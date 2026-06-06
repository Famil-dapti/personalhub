import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../providers/dashboard_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/category_visuals.dart';

const List<String> _monthLabels = [
  'Oca', 'Sub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Agu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

class WalletDashboardScreen extends ConsumerWidget {
  const WalletDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final slices = ref.watch(expenseByCategoryProvider);
    final months = ref.watch(monthlyTotalsProvider);
    final hasData = transactions.valueOrNull?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Ozet')),
      body: transactions.when(
        loading: () => const _DashboardLoading(),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Bir sorun olustu',
          message: e.toString(),
        ),
        data: (_) => !hasData
            ? const EmptyState(
                icon: Icons.insights_outlined,
                title: 'Henuz veri yok',
                message: 'Islem ekledikce burada gider ve gelir grafiklerini gorursun.',
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _SectionTitle('Bu Ay Gider Dagilimi'),
                  _ExpensePie(slices: slices),
                  AppSpacing.gapXxl,
                  _SectionTitle('Son 6 Ay'),
                  const _TrendLegend(),
                  AppSpacing.gapMd,
                  _MonthlyTrend(months: months),
                ],
              ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SkeletonBox(width: 180, height: 16),
          AppSpacing.gapLg,
          Center(child: SkeletonBox(width: 200, height: 200, radius: 100)),
          AppSpacing.gapXxl,
          SkeletonBox(width: 120, height: 16),
          AppSpacing.gapLg,
          SkeletonBox(height: 200),
        ],
      ),
    );
  }
}

/// Color key for the income vs expense bars in the 6-month trend chart.
class _TrendLegend extends StatelessWidget {
  const _TrendLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _LegendDot(color: Colors.green.shade500, label: 'Gelir'),
        const SizedBox(width: AppSpacing.lg),
        _LegendDot(color: scheme.error, label: 'Gider'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: theme.textTheme.titleMedium),
    );
  }
}

class _ExpensePie extends StatelessWidget {
  const _ExpensePie({required this.slices});

  final List<CategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (slices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Bu ay gider yok')),
      );
    }
    final total = slices.fold<double>(0, (sum, s) => sum + s.total);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: slices.map((s) {
                final color = categoryColor(s.category, theme.colorScheme.primary);
                final pct = total == 0 ? 0 : (s.total / total * 100);
                return PieChartSectionData(
                  value: s.total,
                  color: color,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...slices.map((s) => _LegendRow(slice: s)),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice});

  final CategorySlice slice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = categoryColor(slice.category, theme.colorScheme.primary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 12),
          Expanded(child: Text(slice.category?.name ?? 'Kategorisiz')),
          Text(formatMoney(slice.total),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MonthlyTrend extends StatelessWidget {
  const _MonthlyTrend({required this.months});

  final List<MonthTotals> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = _maxValue(months);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_monthLabels[months[i].month - 1],
                        style: theme.textTheme.bodySmall),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < months.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: months[i].income,
                    color: Colors.green.shade500,
                    width: 7,
                  ),
                  BarChartRodData(
                    toY: months[i].expense,
                    color: theme.colorScheme.error,
                    width: 7,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  double _maxValue(List<MonthTotals> months) {
    var max = 0.0;
    for (final m in months) {
      if (m.income > max) max = m.income;
      if (m.expense > max) max = m.expense;
    }
    return max == 0 ? 100 : max * 1.2;
  }
}
