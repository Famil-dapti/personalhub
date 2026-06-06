import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Supabase table names, reused as outbox `entityTable` values.
const String kTransactionsTable = 'transactions';
const String kCategoriesTable = 'categories';
const String kNotificationsTable = 'notifications';
const String kMediaStatsTable = 'media_stats';

// Media decision kinds (Phase 3). 'later' is a defer, not a final decision.
const String kDecisionKeep = 'keep';
const String kDecisionDelete = 'delete';
const String kDecisionFavorite = 'favorite';
const String kDecisionLater = 'later';

const _uuid = Uuid();

/// Offline-first local store. Holds mirrors of the synced Supabase tables plus
/// the sync outbox and watermarks. All UI reads come from here; writes land
/// here first (optimistic) and an outbox row is queued for the sync engine.
@DriftDatabase(
  tables: [
    LocalTransactions,
    LocalCategories,
    LocalNotifications,
    LocalMediaAssets,
    LocalMediaDecisions,
    LocalMediaStats,
    SyncOutbox,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 4;

  // v2 adds the LocalNotifications mirror (Phase 2). v3 adds per-device capture
  // attribution columns. v4 adds the Phase 3 media tables. Existing installs
  // only get the missing pieces.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v1 installs get the table fresh (already includes the v3 columns);
          // only an existing v2 table needs the columns added.
          if (from < 2) await m.createTable(localNotifications);
          if (from == 2) {
            await m.addColumn(localNotifications, localNotifications.deviceId);
            await m.addColumn(localNotifications, localNotifications.deviceName);
          }
          if (from < 4) {
            await m.createTable(localMediaAssets);
            await m.createTable(localMediaDecisions);
            await m.createTable(localMediaStats);
          }
        },
      );

  // --- Reactive reads (UI) --------------------------------------------------

  Stream<List<LocalTransaction>> watchTransactions() {
    return (select(localTransactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<LocalCategory>> watchCategories() {
    return (select(localCategories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  Stream<List<LocalNotification>> watchNotifications() {
    return (select(localNotifications)
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }

  // --- Local writes + outbox (atomic) --------------------------------------

  Future<void> enqueueUpsertTransaction(
    LocalTransactionsCompanion row,
    Map<String, dynamic> payload,
  ) {
    return transaction(() async {
      await into(localTransactions).insertOnConflictUpdate(row);
      await _enqueue(kTransactionsTable, row.id.value, 'upsert', payload);
    });
  }

  Future<void> enqueueDeleteTransaction(String id) {
    return transaction(() async {
      await (update(localTransactions)..where((t) => t.id.equals(id)))
          .write(LocalTransactionsCompanion(deletedAt: Value(DateTime.now())));
      await _enqueue(kTransactionsTable, id, 'delete', null);
    });
  }

  Future<void> enqueueUpsertCategory(
    LocalCategoriesCompanion row,
    Map<String, dynamic> payload,
  ) {
    return transaction(() async {
      await into(localCategories).insertOnConflictUpdate(row);
      await _enqueue(kCategoriesTable, row.id.value, 'upsert', payload);
    });
  }

  Future<void> enqueueDeleteCategory(String id) {
    return transaction(() async {
      await (update(localCategories)..where((c) => c.id.equals(id)))
          .write(LocalCategoriesCompanion(deletedAt: Value(DateTime.now())));
      await _enqueue(kCategoriesTable, id, 'delete', null);
    });
  }

  // Captured notifications are immutable: write the row locally and queue an
  // upsert push. No delete/update path (notifications are never edited).
  Future<void> enqueueUpsertNotification(
    LocalNotificationsCompanion row,
    Map<String, dynamic> payload,
  ) {
    return transaction(() async {
      await into(localNotifications).insertOnConflictUpdate(row);
      await _enqueue(kNotificationsTable, row.id.value, 'upsert', payload);
    });
  }

  // Dedup guard for capture: true if the SAME device already stored an
  // identical notification (same posted time + source + content) — i.e. a
  // re-delivery (heads-up then collapse-to-bar), not a distinct event. Scoped
  // to deviceId so a copy synced from the other phone is never mistaken for a
  // duplicate of this phone's own capture.
  Future<bool> notificationExistsLike({
    required String? deviceId,
    required DateTime? postedAt,
    required String? appPackage,
    required String? title,
    required String? body,
  }) async {
    final query = select(localNotifications)
      ..where((n) =>
          n.deviceId.equalsNullable(deviceId) &
          n.postedAt.equalsNullable(postedAt) &
          n.appPackage.equalsNullable(appPackage) &
          n.title.equalsNullable(title) &
          n.body.equalsNullable(body))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row != null;
  }

  // Local side of "clear all notifications": wipe the mirror and drop any
  // not-yet-pushed notification upserts so they cannot recreate deleted rows.
  Future<void> clearAllNotificationsLocal() {
    return transaction(() async {
      await delete(localNotifications).go();
      await (delete(syncOutbox)
            ..where((o) => o.entityTable.equals(kNotificationsTable)))
          .go();
    });
  }

  Future<void> _enqueue(
    String table,
    String entityId,
    String op,
    Map<String, dynamic>? payload,
  ) {
    return into(syncOutbox).insert(
      SyncOutboxCompanion.insert(
        id: _uuid.v4(),
        entityTable: table,
        entityId: entityId,
        op: op,
        payload: Value(payload == null ? null : jsonEncode(payload)),
        createdAt: DateTime.now(),
      ),
    );
  }

  // --- Sync engine support --------------------------------------------------

  Future<List<SyncOutboxData>> pendingOutbox() {
    return (select(syncOutbox)
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
        .get();
  }

  Future<void> clearOutbox(String id) {
    return (delete(syncOutbox)..where((o) => o.id.equals(id))).go();
  }

  Future<DateTime?> watermark(String table) async {
    final row = await (select(syncState)
          ..where((s) => s.entity.equals(table)))
        .getSingleOrNull();
    return row?.lastPulledAt;
  }

  Future<void> setWatermark(String table, DateTime ts) {
    return into(syncState).insertOnConflictUpdate(
      SyncStateCompanion(entity: Value(table), lastPulledAt: Value(ts)),
    );
  }

  Future<void> upsertTransactions(List<LocalTransactionsCompanion> rows) {
    return batch((b) => b.insertAllOnConflictUpdate(localTransactions, rows));
  }

  Future<void> upsertCategories(List<LocalCategoriesCompanion> rows) {
    return batch((b) => b.insertAllOnConflictUpdate(localCategories, rows));
  }

  Future<void> upsertNotifications(List<LocalNotificationsCompanion> rows) {
    return batch((b) => b.insertAllOnConflictUpdate(localNotifications, rows));
  }

  // --- Media index (Phase 3, local-only) -----------------------------------

  /// All asset ids currently indexed for a device — the delta-scan baseline.
  Future<Set<String>> indexedAssetIds(String deviceId) async {
    final q = selectOnly(localMediaAssets)
      ..addColumns([localMediaAssets.assetId])
      ..where(localMediaAssets.deviceId.equals(deviceId));
    final rows = await q.get();
    return rows.map((r) => r.read(localMediaAssets.assetId)!).toSet();
  }

  Future<void> upsertMediaAssets(List<LocalMediaAssetsCompanion> rows) {
    return batch((b) => b.insertAllOnConflictUpdate(localMediaAssets, rows));
  }

  /// Distinct, sorted folder/album names in the index — for the filter menu.
  Future<List<String>> distinctAlbumNames(String deviceId) async {
    final q = selectOnly(localMediaAssets, distinct: true)
      ..addColumns([localMediaAssets.albumName])
      ..where(localMediaAssets.deviceId.equals(deviceId) &
          localMediaAssets.albumName.isNotNull());
    final rows = await q.get();
    final names = rows
        .map((r) => r.read(localMediaAssets.albumName))
        .whereType<String>()
        .toList()
      ..sort();
    return names;
  }

  /// Drops index rows for assets no longer present on the device (delta scan).
  Future<void> removeMediaAssets(List<String> assetIds) {
    if (assetIds.isEmpty) return Future.value();
    return (delete(localMediaAssets)..where((a) => a.assetId.isIn(assetIds)))
        .go();
  }

  /// The review working set: indexed assets that have no FINAL decision yet
  /// (keep/delete/favorite). Undecided come first; deferred ('later') last.
  /// Filtering/sorting beyond this baseline is applied in Dart by the engine.
  Future<List<LocalMediaAsset>> reviewQueue(String deviceId) async {
    final finalized = selectOnly(localMediaDecisions)
      ..addColumns([localMediaDecisions.assetId])
      ..where(localMediaDecisions.decision.isIn(
          const [kDecisionKeep, kDecisionDelete, kDecisionFavorite]));
    final finalizedIds = (await finalized.get())
        .map((r) => r.read(localMediaDecisions.assetId)!)
        .toSet();

    final rows = await (select(localMediaAssets)
          ..where((a) => a.deviceId.equals(deviceId)))
        .get();
    return rows.where((a) => !finalizedIds.contains(a.assetId)).toList();
  }

  // --- Media decisions (Phase 3, local-only) -------------------------------

  Future<void> upsertMediaDecision(LocalMediaDecisionsCompanion row) {
    return into(localMediaDecisions).insertOnConflictUpdate(row);
  }

  /// Reverts a decision (undo): the asset returns to the review queue.
  Future<void> deleteMediaDecision(String assetId) {
    return (delete(localMediaDecisions)..where((d) => d.assetId.equals(assetId)))
        .go();
  }

  /// Assets marked delete but not yet executed against device storage, with the
  /// size needed for the freed-space estimate on the batch-confirm screen.
  Future<List<LocalMediaAsset>> pendingDeletes(String deviceId) {
    final pending = selectOnly(localMediaDecisions)
      ..addColumns([localMediaDecisions.assetId])
      ..where(localMediaDecisions.deviceId.equals(deviceId) &
          localMediaDecisions.pendingDelete.equals(true));
    return pending.get().then((rows) async {
      final ids = rows.map((r) => r.read(localMediaDecisions.assetId)!).toList();
      if (ids.isEmpty) return <LocalMediaAsset>[];
      return (select(localMediaAssets)..where((a) => a.assetId.isIn(ids))).get();
    });
  }

  /// Live count of assets queued for deletion (drives the batch-delete badge).
  Stream<int> watchPendingDeleteCount(String deviceId) {
    return (select(localMediaDecisions)
          ..where((d) =>
              d.deviceId.equals(deviceId) & d.pendingDelete.equals(true)))
        .watch()
        .map((rows) => rows.length);
  }

  /// After device storage deletion succeeds: clear the pending flag and drop
  /// the assets from the index. The decision rows persist (cumulative stats).
  Future<void> markDeletesExecuted(List<String> assetIds) {
    if (assetIds.isEmpty) return Future.value();
    return transaction(() async {
      await (update(localMediaDecisions)
            ..where((d) => d.assetId.isIn(assetIds)))
          .write(const LocalMediaDecisionsCompanion(
              pendingDelete: Value(false)));
      await (delete(localMediaAssets)..where((a) => a.assetId.isIn(assetIds)))
          .go();
    });
  }

  // --- Media stats (Phase 3, synced aggregates) ----------------------------

  /// Recomputes this device's aggregate counters from the local index +
  /// decisions. `total` = items still needing review + items already decided.
  Future<MediaCounts> computeMediaCounts(String deviceId) async {
    Future<int> count<T extends HasResultSet, R>(SimpleSelectStatement<T, R> q) =>
        q.get().then((r) => r.length);

    final decided = await count(select(localMediaDecisions)
      ..where((d) =>
          d.deviceId.equals(deviceId) &
          d.decision.isIn(
              const [kDecisionKeep, kDecisionDelete, kDecisionFavorite])));
    final kept = await count(select(localMediaDecisions)
      ..where((d) =>
          d.deviceId.equals(deviceId) &
          d.decision.isIn(const [kDecisionKeep, kDecisionFavorite])));
    final deleted = await count(select(localMediaDecisions)
      ..where((d) =>
          d.deviceId.equals(deviceId) & d.decision.equals(kDecisionDelete)));
    // Undecided = indexed assets without a final decision.
    final pendingReview = (await reviewQueue(deviceId)).length;
    return MediaCounts(
      total: decided + pendingReview,
      decided: decided,
      kept: kept,
      deleted: deleted,
    );
  }

  Stream<List<LocalMediaStat>> watchMediaStats() {
    return (select(localMediaStats)
          ..orderBy([(s) => OrderingTerm.asc(s.deviceName)]))
        .watch();
  }

  /// Writes this device's stats row locally and queues the aggregate push.
  Future<void> enqueueUpsertMediaStats(
    LocalMediaStatsCompanion row,
    Map<String, dynamic> payload,
  ) {
    return transaction(() async {
      await into(localMediaStats).insertOnConflictUpdate(row);
      await _enqueue(kMediaStatsTable, row.id.value, 'upsert', payload);
    });
  }

  Future<void> upsertMediaStats(List<LocalMediaStatsCompanion> rows) {
    return batch((b) => b.insertAllOnConflictUpdate(localMediaStats, rows));
  }
}

/// Aggregate media-cleanup counters for one device.
class MediaCounts {
  const MediaCounts({
    required this.total,
    required this.decided,
    required this.kept,
    required this.deleted,
  });
  final int total;
  final int decided;
  final int kept;
  final int deleted;
}

QueryExecutor _open() {
  // Relative web URIs resolve against <base href> so they work under the
  // GitHub Pages subpath (/personalhub/). Native uses path_provider via
  // drift_flutter automatically.
  return driftDatabase(
    name: 'personalhub',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
