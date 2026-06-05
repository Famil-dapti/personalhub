import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider));
});

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
  TransactionsNotifier.new,
);

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    return ref.read(transactionRepositoryProvider).fetchAll();
  }

  Future<String?> addTransaction(Transaction transaction) async {
    try {
      await ref.read(transactionRepositoryProvider).create(transaction);
      ref.invalidateSelf();
      await future;
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  Future<String?> removeTransaction(String id) async {
    try {
      await ref.read(transactionRepositoryProvider).delete(id);
      ref.invalidateSelf();
      await future;
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
    balance += t.amount;
    final inMonth = t.createdAt.year == now.year && t.createdAt.month == now.month;
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
