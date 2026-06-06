import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/database_provider.dart';
import '../../../../core/db/mappers.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../notifications/presentation/providers/capture_providers.dart'
    show deviceIdentityProvider;
import '../../data/media_scanner.dart';
import '../../data/models/media_models.dart';
import '../../domain/media_filter.dart';

// --- Platform gateway -----------------------------------------------------

final mediaScannerProvider =
    Provider<MediaScanner>((ref) => createMediaScanner());

// True on Android/iOS, false on web (no device file access).
final mediaSupportedProvider =
    Provider<bool>((ref) => ref.watch(mediaScannerProvider).supported);

// Asks the OS for photo/video access. Invalidate to re-check after the user
// returns from system settings.
final mediaAccessProvider = FutureProvider<MediaAccess>((ref) {
  final scanner = ref.watch(mediaScannerProvider);
  if (!scanner.supported) return Future.value(MediaAccess.denied);
  return scanner.requestAccess();
});

// --- Filter / sort UI state -----------------------------------------------

final mediaTypeFilterProvider =
    StateProvider<MediaTypeFilter>((ref) => MediaTypeFilter.all);
final mediaSortProvider =
    StateProvider<MediaSortOrder>((ref) => MediaSortOrder.newest);
final mediaAlbumFilterProvider = StateProvider<String?>((ref) => null);
final mediaScreenshotsOnlyProvider = StateProvider<bool>((ref) => false);

// Bump to rebuild the deck from scratch (after indexing, batch delete, or a
// random reshuffle). Doubles as the deterministic shuffle seed.
final mediaDeckRefreshProvider = StateProvider<int>((ref) => 0);

// --- Reads ----------------------------------------------------------------

final mediaAlbumsProvider = FutureProvider<List<String>>((ref) async {
  if (!ref.watch(mediaSupportedProvider)) return const [];
  ref.watch(mediaDeckRefreshProvider);
  final device = await ref.watch(deviceIdentityProvider.future);
  return ref.watch(appDatabaseProvider).distinctAlbumNames(device.id);
});

/// The ordered review deck. Recomputed only when filters/sort/refresh change —
/// NOT on each swipe, so the card stack stays stable while the user reviews.
final mediaDeckProvider = FutureProvider<List<MediaAsset>>((ref) async {
  if (!ref.watch(mediaSupportedProvider)) return const [];
  final device = await ref.watch(deviceIdentityProvider.future);
  final db = ref.watch(appDatabaseProvider);
  final seed = ref.watch(mediaDeckRefreshProvider);
  final rows = await db.reviewQueue(device.id);
  final assets = rows.map(mediaAssetToDomain).toList();
  return applyMediaFilterSort(
    assets,
    type: ref.watch(mediaTypeFilterProvider),
    album: ref.watch(mediaAlbumFilterProvider),
    screenshotsOnly: ref.watch(mediaScreenshotsOnlyProvider),
    sort: ref.watch(mediaSortProvider),
    seed: seed,
  );
});

/// Per-device cleanup stats (phone + web), straight from Drift.
final mediaStatsProvider = StreamProvider<List<MediaStats>>((ref) {
  return ref.watch(appDatabaseProvider).watchMediaStats().map(
        (rows) => rows.map(mediaStatsToDomain).toList(),
      );
});

/// Live count of assets queued for deletion (batch-delete badge).
final mediaPendingDeleteCountProvider = StreamProvider<int>((ref) {
  if (!ref.watch(mediaSupportedProvider)) return Stream.value(0);
  final db = ref.watch(appDatabaseProvider);
  return ref.watch(deviceIdentityProvider.future).asStream().asyncExpand(
        (device) => db.watchPendingDeleteCount(device.id),
      );
});

/// The assets queued for deletion, with sizes — for the batch-confirm screen.
final mediaPendingDeletesProvider = FutureProvider<List<MediaAsset>>((ref) async {
  if (!ref.watch(mediaSupportedProvider)) return const [];
  ref.watch(mediaDeckRefreshProvider);
  ref.watch(mediaPendingDeleteCountProvider); // refresh as the queue changes
  final device = await ref.watch(deviceIdentityProvider.future);
  final rows = await ref.watch(appDatabaseProvider).pendingDeletes(device.id);
  return rows.map(mediaAssetToDomain).toList();
});

// --- Indexing controller (progress) ---------------------------------------

/// Progress of the library scan. `total == 0` before the count is known.
class MediaIndexState {
  const MediaIndexState({
    this.running = false,
    this.done = false,
    this.processed = 0,
    this.total = 0,
    this.error,
  });

  final bool running;
  final bool done;
  final int processed;
  final int total;
  final String? error;

  double get progress => total == 0 ? 0 : (processed / total).clamp(0, 1);
}

final mediaIndexControllerProvider =
    StateNotifierProvider<MediaIndexController, MediaIndexState>(
        (ref) => MediaIndexController(ref));

/// Runs the full/delta library scan and refreshes the deck + stats afterwards.
class MediaIndexController extends StateNotifier<MediaIndexState> {
  MediaIndexController(this._ref) : super(const MediaIndexState());

  final Ref _ref;

  Future<void> run() async {
    if (state.running) return;
    final scanner = _ref.read(mediaScannerProvider);
    if (!scanner.supported) {
      state = const MediaIndexState(done: true);
      return;
    }
    state = const MediaIndexState(running: true);
    try {
      final device = await _ref.read(deviceIdentityProvider.future);
      await scanner.indexDevice(
        deviceId: device.id,
        db: _ref.read(appDatabaseProvider),
        onProgress: (done, total) {
          state = MediaIndexState(running: true, processed: done, total: total);
        },
      );
      state = MediaIndexState(
          done: true, processed: state.processed, total: state.total);
      _ref.read(mediaDeckRefreshProvider.notifier).state++;
      _ref.invalidate(mediaAlbumsProvider);
      await _ref.read(mediaCleanerControllerProvider).syncStats();
    } on Exception catch (e) {
      state = MediaIndexState(error: e.toString());
    }
  }
}

// --- Action controller (decide / undo / delete / stats) -------------------

/// Result of a batch delete; `error` non-null means the operation failed.
class MediaDeleteResult {
  const MediaDeleteResult({
    this.deletedCount = 0,
    this.freedBytes = 0,
    this.error,
  });
  final int deletedCount;
  final int freedBytes;
  final String? error;
}

final mediaCleanerControllerProvider = Provider<MediaCleanerController>(
    (ref) => MediaCleanerController(ref));

/// Write path for the Media Cleaner: records decisions locally, executes
/// batch deletes through the OS, and keeps the synced per-device stats current.
class MediaCleanerController {
  MediaCleanerController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();
  static const _kStatsIdKey = 'media_stats_id';

  /// Records a keep/delete/favorite/later verdict for one asset.
  Future<String?> decide(MediaAsset asset, MediaDecisionKind kind) async {
    try {
      await _ref.read(appDatabaseProvider).upsertMediaDecision(
            LocalMediaDecisionsCompanion.insert(
              assetId: asset.assetId,
              deviceId: asset.deviceId,
              decision: kind.wire,
              decidedAt: DateTime.now(),
              pendingDelete: Value(kind == MediaDecisionKind.delete),
            ),
          );
      await syncStats();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  /// Reverts the last verdict for an asset (undo) — it re-enters the queue.
  Future<String?> undo(MediaAsset asset) async {
    try {
      await _ref.read(appDatabaseProvider).deleteMediaDecision(asset.assetId);
      await syncStats();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  /// Executes every pending delete via the OS trash dialog, then drops the
  /// removed assets from the index. Returns the freed space + count.
  Future<MediaDeleteResult> executeDeletes() async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final device = await _ref.read(deviceIdentityProvider.future);
      final pending = await db.pendingDeletes(device.id);
      if (pending.isEmpty) return const MediaDeleteResult();

      final ids = pending.map((a) => a.assetId).toList();
      final deletedIds = await _ref.read(mediaScannerProvider).deleteAssets(ids);
      final freed = pending
          .where((a) => deletedIds.contains(a.assetId))
          .fold<int>(0, (sum, a) => sum + a.sizeBytes);

      await db.markDeletesExecuted(deletedIds);
      await syncStats();
      _ref.read(mediaDeckRefreshProvider.notifier).state++;
      return MediaDeleteResult(deletedCount: deletedIds.length, freedBytes: freed);
    } on Exception catch (e) {
      return MediaDeleteResult(error: e.toString());
    }
  }

  /// Recomputes this device's aggregate counters and queues the (aggregate-only)
  /// push to Supabase so other devices and the web app can show its progress.
  Future<void> syncStats() async {
    final client = _ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final db = _ref.read(appDatabaseProvider);
    final device = await _ref.read(deviceIdentityProvider.future);
    final counts = await db.computeMediaCounts(device.id);

    final prefs = await SharedPreferences.getInstance();
    var statsId = prefs.getString(_kStatsIdKey);
    if (statsId == null) {
      statsId = _uuid.v4();
      await prefs.setString(_kStatsIdKey, statsId);
    }

    final row = LocalMediaStatsCompanion.insert(
      id: statsId,
      userId: userId,
      deviceId: device.id,
      deviceName: Value(device.name),
      total: Value(counts.total),
      decided: Value(counts.decided),
      kept: Value(counts.kept),
      deleted: Value(counts.deleted),
      updatedAt: DateTime.now(),
    );
    // updated_at is omitted: the Supabase trigger stamps server time, which the
    // pull watermark relies on (the push echo writes the server value back).
    final payload = <String, dynamic>{
      'id': statsId,
      'user_id': userId,
      'device_id': device.id,
      'device_name': device.name,
      'total': counts.total,
      'decided': counts.decided,
      'kept': counts.kept,
      'deleted': counts.deleted,
    };
    await db.enqueueUpsertMediaStats(row, payload);
    _ref.read(syncServiceProvider).syncAll();
  }
}
