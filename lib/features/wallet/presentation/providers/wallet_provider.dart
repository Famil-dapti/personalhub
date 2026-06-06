import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/database_provider.dart';
import '../../../../core/db/mappers.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../data/models/transaction_model.dart';

// Reactive transaction list straight from the local Drift store (offline-first).
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTransactions().map(
        (rows) => rows.map(transactionToDomain).toList(),
      );
});

final transactionsControllerProvider = Provider<TransactionsController>((ref) {
  return TransactionsController(ref);
});

/// Writes land in Drift + the sync outbox first (instant, offline-capable),
/// then opportunistically kick a sync. Returns an error string on failure.
class TransactionsController {
  TransactionsController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  Future<String?> add(Transaction t) async {
    return _write(t, id: _uuid.v4());
  }

  /// Upserts an existing transaction by its id. Used to commit an SMS draft
  /// (pending -> false) after the user edits and saves it.
  Future<String?> update(Transaction t) async {
    return _write(t, id: t.id);
  }

  Future<String?> _write(Transaction t, {required String id}) async {
    try {
      final userId = _ref.read(supabaseClientProvider).auth.currentUser!.id;
      final row = LocalTransactionsCompanion.insert(
        id: id,
        userId: userId,
        amount: t.amount,
        createdAt: t.createdAt,
        updatedAt: DateTime.now(),
        currency: Value(t.currency),
        categoryId: Value(t.categoryId),
        description: Value(t.description),
        source: Value(t.source),
        notificationId: Value(t.notificationId),
        pending: Value(t.pending),
      );
      final payload = {
        'id': id,
        'user_id': userId,
        'amount': t.amount,
        'currency': t.currency,
        'category_id': t.categoryId,
        'description': t.description,
        'source': t.source,
        'notification_id': t.notificationId,
        'pending': t.pending,
        'created_at': t.createdAt.toIso8601String(),
      };
      await _ref
          .read(appDatabaseProvider)
          .enqueueUpsertTransaction(row, payload);
      _ref.read(syncServiceProvider).syncAll();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  Future<String?> remove(String id) async {
    try {
      await _ref.read(appDatabaseProvider).enqueueDeleteTransaction(id);
      _ref.read(syncServiceProvider).syncAll();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }
}

class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
  });

  final double balance;
  final double monthIncome; // current calendar month
  final double monthExpense; // current calendar month (positive magnitude)
}

// Derived totals for the balance card. Single currency (AZN) in Phase 1.1.
final walletSummaryProvider = Provider<WalletSummary>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final now = DateTime.now();

  var balance = 0.0;
  var monthIncome = 0.0;
  var monthExpense = 0.0;

  for (final t in transactions) {
    if (t.pending) continue; // drafts do not affect the balance until committed
    balance += t.amount;
    final inMonth =
        t.createdAt.year == now.year && t.createdAt.month == now.month;
    if (!inMonth) continue;
    if (t.isIncome) {
      monthIncome += t.amount;
    } else {
      monthExpense += -t.amount;
    }
  }

  return WalletSummary(
    balance: balance,
    monthIncome: monthIncome,
    monthExpense: monthExpense,
  );
});
