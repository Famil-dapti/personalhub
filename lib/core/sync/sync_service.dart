import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../db/mappers.dart';

/// Push/pull reconciliation between the local Drift store and Supabase.
///
/// Push: drains the outbox oldest-first as idempotent upserts (and soft-delete
/// updates). Pull: per table, fetches rows with `updated_at` greater than the
/// stored watermark and upserts them locally. Last-write-wins is anchored to
/// the server clock (Postgres trigger sets `updated_at`). Echo loops are
/// avoided by writing the server-returned row (and its `updated_at`) back
/// locally after each push, so the next pull's watermark filter excludes it.
class SyncService {
  SyncService(this._db, this._client);

  final AppDatabase _db;
  final SupabaseClient _client;

  bool _running = false;

  Future<void> syncAll() async {
    if (_running) return; // serialize: app-start / reconnect / post-write
    if (_client.auth.currentUser == null) return;
    _running = true;
    try {
      await _pushOutbox();
      await _pullTable(kTransactionsTable);
      await _pullTable(kCategoriesTable);
    } finally {
      _running = false;
    }
  }

  // --- Push ----------------------------------------------------------------

  Future<void> _pushOutbox() async {
    final pending = await _db.pendingOutbox();
    for (final item in pending) {
      try {
        final Map<String, dynamic> serverRow;
        if (item.op == 'delete') {
          final row = await _client
              .from(item.entityTable)
              .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
              .eq('id', item.entityId)
              .select()
              .maybeSingle();
          if (row == null) {
            await _db.clearOutbox(item.id); // already gone server-side
            continue;
          }
          serverRow = row;
        } else {
          final payload = jsonDecode(item.payload!) as Map<String, dynamic>;
          serverRow = await _client
              .from(item.entityTable)
              .upsert(payload)
              .select()
              .single();
        }
        await _applyRemoteRow(item.entityTable, serverRow);
        await _db.clearOutbox(item.id);
      } on Exception {
        // Likely offline or transient. Stop to preserve order; retry next sync.
        break;
      }
    }
  }

  // --- Pull ----------------------------------------------------------------

  Future<void> _pullTable(String table) async {
    final since = await _db.watermark(table);
    final filter = _client.from(table).select();
    final rows = since == null
        ? await filter.order('updated_at', ascending: true)
        : await filter
            .gt('updated_at', since.toUtc().toIso8601String())
            .order('updated_at', ascending: true);
    if (rows.isEmpty) return;

    final list = rows.cast<Map<String, dynamic>>();
    if (table == kTransactionsTable) {
      await _db.upsertTransactions(
          list.map(transactionCompanionFromRemote).toList());
    } else {
      await _db.upsertCategories(
          list.map(categoryCompanionFromRemote).toList());
    }

    var maxTs = since ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    for (final row in list) {
      final ts = DateTime.parse(row['updated_at'] as String);
      if (ts.isAfter(maxTs)) maxTs = ts;
    }
    await _db.setWatermark(table, maxTs);
  }

  Future<void> _applyRemoteRow(String table, Map<String, dynamic> row) {
    if (table == kTransactionsTable) {
      return _db.upsertTransactions([transactionCompanionFromRemote(row)]);
    }
    return _db.upsertCategories([categoryCompanionFromRemote(row)]);
  }
}
