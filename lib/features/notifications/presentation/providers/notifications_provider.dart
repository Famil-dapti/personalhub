import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/database_provider.dart';
import '../../../../core/db/mappers.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../wallet/data/models/transaction_model.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/models/notification_model.dart';
import '../../domain/notification_parser.dart';
import '../../domain/package_templates.dart';

// Special filter sentinels; any other value is a literal app name.
const String kFilterAll = 'all';
const String kFilterTransactions = 'transactions';

// Reactive notification archive straight from the local Drift store.
final notificationsProvider = StreamProvider<List<NotificationItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchNotifications().map(
        (rows) => rows.map(notificationToDomain).toList(),
      );
});

// Distinct source-app names present in the archive, for the filter chip row.
final notificationAppsProvider = Provider<List<String>>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  final names = <String>{
    for (final n in items)
      if (n.appName != null && n.appName!.isNotEmpty) n.appName!,
  };
  final sorted = names.toList()..sort();
  return sorted;
});

// Distinct capturing-device names present in the archive, for the device filter.
final notificationDevicesProvider = Provider<List<String>>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  final names = <String>{
    for (final n in items)
      if (n.deviceName != null && n.deviceName!.isNotEmpty) n.deviceName!,
  };
  final sorted = names.toList()..sort();
  return sorted;
});

final notificationSearchProvider = StateProvider<String>((ref) => '');
final notificationFilterProvider = StateProvider<String>((ref) => kFilterAll);

// Device-name filter; null = all devices (independent of the app/transaction filter).
final notificationDeviceFilterProvider =
    StateProvider<String?>((ref) => null);

// Currently selected row (desktop master-detail; null = none selected).
final selectedNotificationIdProvider = StateProvider<String?>((ref) => null);

// Search + filter applied over the reactive list.
final filteredNotificationsProvider =
    Provider<List<NotificationItem>>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  final query = ref.watch(notificationSearchProvider).trim().toLowerCase();
  final filter = ref.watch(notificationFilterProvider);
  final deviceFilter = ref.watch(notificationDeviceFilterProvider);

  return items.where((n) {
    if (deviceFilter != null && n.deviceName != deviceFilter) return false;
    if (filter == kFilterTransactions && !n.isTransaction) return false;
    if (filter != kFilterAll &&
        filter != kFilterTransactions &&
        n.appName != filter) {
      return false;
    }
    if (query.isEmpty) return true;
    return [n.title, n.body, n.appName]
        .any((f) => (f ?? '').toLowerCase().contains(query));
  }).toList();
});

final selectedNotificationProvider = Provider<NotificationItem?>((ref) {
  final id = ref.watch(selectedNotificationIdProvider);
  if (id == null) return null;
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  for (final n in items) {
    if (n.id == id) return n;
  }
  return null;
});

final notificationsControllerProvider =
    Provider<NotificationsController>((ref) {
  return NotificationsController(ref);
});

/// Write path for captured notifications. Lands the row in Drift + the sync
/// outbox first (instant, offline-capable), then kicks a background sync.
/// Called by the Android capture channel in Phase 2B.
class NotificationsController {
  NotificationsController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  Future<String?> ingest(NotificationItem n) async {
    try {
      final userId = _ref.read(supabaseClientProvider).auth.currentUser!.id;
      final db = _ref.read(appDatabaseProvider);

      // Drop duplicates Android re-delivers (e.g. heads-up then collapse-to-bar)
      // that slip past the native dedup; identity = posted time + source + text.
      final duplicate = await db.notificationExistsLike(
        deviceId: n.deviceId,
        postedAt: n.postedAt,
        appPackage: n.appPackage,
        title: n.title,
        body: n.body,
      );
      if (duplicate) return null;

      final id = n.id.isEmpty ? _uuid.v4() : n.id;
      final row = LocalNotificationsCompanion.insert(
        id: id,
        userId: userId,
        createdAt: n.createdAt,
        appPackage: Value(n.appPackage),
        appName: Value(n.appName),
        title: Value(n.title),
        body: Value(n.body),
        postedAt: Value(n.postedAt),
        isTransaction: Value(n.isTransaction),
        rawJson: Value(n.rawJson),
        deviceId: Value(n.deviceId),
        deviceName: Value(n.deviceName),
      );
      final payload = NotificationItem(
        id: id,
        userId: userId,
        createdAt: n.createdAt,
        appPackage: n.appPackage,
        appName: n.appName,
        title: n.title,
        body: n.body,
        postedAt: n.postedAt,
        isTransaction: n.isTransaction,
        rawJson: n.rawJson,
        deviceId: n.deviceId,
        deviceName: n.deviceName,
      ).toInsert(userId);
      await db.enqueueUpsertNotification(row, payload);
      // Native capture path only (ingest never runs for pulled rows), so a draft
      // is derived exactly once, on the phone that captured the SMS.
      await _maybeAutoRouteSms(id, n, db);
      _ref.read(syncServiceProvider).syncAll();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  // SMS rule (Phase 4): an SMS-app notification whose body carries an "NN.NN"
  // amount becomes a cancelable pending draft in the wallet. Mis-routes are
  // trivially cancelable, so the gate is intentionally permissive.
  Future<void> _maybeAutoRouteSms(
      String notificationId, NotificationItem n, AppDatabase db) async {
    if (!kSmsPackages.contains(n.appPackage)) return;
    final body = n.body ?? '';
    if (body.isEmpty) return;
    // Strip date/time noise first so "06.06.2026" / "14:32" never satisfy the
    // NN.NN gate, then require an amount with exactly two decimals.
    final gate = body
        .replaceAll(RegExp(r'\d{1,4}[./-]\d{1,2}[./-]\d{1,4}'), ' ')
        .replaceAll(RegExp(r'\d{1,2}:\d{2}(?::\d{2})?'), ' ');
    if (!RegExp(r'\d+\.\d{2}').hasMatch(gate)) return;
    if (await db.transactionExistsForNotification(notificationId)) return;

    final parsed = parseAmountLenient(n.title, body);
    if (parsed == null) return;
    final draft = Transaction(
      id: '',
      userId: '',
      amount: parsed.signedAmount,
      createdAt: n.postedAt ?? n.createdAt,
      description: (n.title?.isNotEmpty ?? false) ? n.title : body,
      source: 'notification',
      notificationId: notificationId,
      pending: true,
    );
    await _ref.read(transactionsControllerProvider).add(draft);
  }

  /// Deletes every archived notification — remotely (frees Supabase space) then
  /// locally. Remote-first so a failure (offline) leaves both stores intact and
  /// the action can be retried. Returns null on success, else an error message.
  Future<String?> clearAll() async {
    try {
      await _ref.read(syncServiceProvider).purgeNotifications();
      await _ref.read(appDatabaseProvider).clearAllNotificationsLocal();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }
}
