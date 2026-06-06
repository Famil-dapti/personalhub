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

const _uuid = Uuid();

/// Offline-first local store. Holds mirrors of the synced Supabase tables plus
/// the sync outbox and watermarks. All UI reads come from here; writes land
/// here first (optimistic) and an outbox row is queued for the sync engine.
@DriftDatabase(
  tables: [
    LocalTransactions,
    LocalCategories,
    LocalNotifications,
    SyncOutbox,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 2;

  // v2 adds the LocalNotifications mirror (Phase 2). Existing installs only
  // need the new table created; all other tables are unchanged.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(localNotifications);
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
