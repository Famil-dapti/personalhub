import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category_model.dart';
import 'category_provider.dart';
import 'wallet_provider.dart';

class CategorySlice {
  const CategorySlice({required this.category, required this.total});

  final Category? category;
  final double total; // positive magnitude
}

class MonthTotals {
  const MonthTotals({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  final int year;
  final int month;
  final double income;
  final double expense; // positive magnitude
}

// Current-month expense totals grouped by category, descending.
final expenseByCategoryProvider = Provider<List<CategorySlice>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final categories = ref.watch(categoryMapProvider);
  final now = DateTime.now();

  final totals = <String?, double>{};
  for (final t in transactions) {
    if (!t.isExpense) continue;
    if (t.createdAt.year != now.year || t.createdAt.month != now.month) continue;
    totals.update(t.categoryId, (v) => v + -t.amount, ifAbsent: () => -t.amount);
  }

  final slices = totals.entries
      .map((e) => CategorySlice(category: categories[e.key], total: e.value))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));
  return slices;
});

// Income vs expense totals for the last 6 calendar months (oldest first).
final monthlyTotalsProvider = Provider<List<MonthTotals>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final now = DateTime.now();

  final buckets = <String, MonthTotals>{};
  final order = <String>[];
  for (var i = 5; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i);
    final key = '${d.year}-${d.month}';
    order.add(key);
    buckets[key] =
        MonthTotals(year: d.year, month: d.month, income: 0, expense: 0);
  }

  for (final t in transactions) {
    final key = '${t.createdAt.year}-${t.createdAt.month}';
    final current = buckets[key];
    if (current == null) continue;
    buckets[key] = MonthTotals(
      year: current.year,
      month: current.month,
      income: current.income + (t.isIncome ? t.amount : 0),
      expense: current.expense + (t.isExpense ? -t.amount : 0),
    );
  }

  return order.map((k) => buckets[k]!).toList();
});
