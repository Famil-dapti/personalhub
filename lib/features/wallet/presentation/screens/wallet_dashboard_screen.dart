import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/responsive.dart';
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
          tone: EmptyStateTone.error,
        ),
        data: (_) => !hasData
            ? const EmptyState(
                icon: Icons.insights_outlined,
                title: 'Henuz veri yok',
                message:
                    'Islem ekledikce burada gider ve gelir grafiklerini gorursun.',
              )
            : _DashboardBody(slices: slices, months: months),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.slices, required this.months});

  final List<CategorySlice> slices;
  final List<MonthTotals> months;

  @override
  Widget build(BuildContext context) {
    final donut = _ChartCard(
      title: 'Bu Ay Gider Dagilimi',
      child: _ExpensePie(slices: slices),
    );
    final bars = _ChartCard(
      title: 'Son 6 Ay',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrendLegend(),
          AppSpacing.gapMd,
          _MonthlyTrend(months: months),
        ],
      ),
    );

    if (context.isWide) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: donut),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(child: bars),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [donut, AppSpacing.gapLg, bars],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            AppSpacing.gapLg,
            child,
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
        _LegendDot(color: context.money.income, label: 'Gelir'),
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

class _ExpensePie extends StatelessWidget {
  const _ExpensePie({required this.slices});

  final List<CategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (slices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: Text('Bu ay gider yok')),
      );
    }
    final total = slices.fold<double>(0, (sum, s) => sum + s.total);
    final canvas = context.isWide ? 220.0 : 200.0;

    return Column(
      children: [
        SizedBox(
          height: canvas,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: canvas * 0.30,
                  sections: _sections(theme, total),
                ),
              ),
              _CenterTotal(total: total),
            ],
          ),
        ),
        AppSpacing.gapLg,
        ...slices.map((s) => _LegendRow(slice: s)),
      ],
    );
  }

  List<PieChartSectionData> _sections(ThemeData theme, double total) {
    return slices.map((s) {
      final color = categoryColor(s.category, theme.colorScheme.primary);
      final pct = total == 0 ? 0 : (s.total / total * 100);
      return PieChartSectionData(
        value: s.total,
        color: color,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 54,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }
}

class _CenterTotal extends StatelessWidget {
  const _CenterTotal({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Toplam',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          formatMoney(total),
          style: theme.textTheme.titleSmall
              ?.copyWith(fontFeatures: kTabularFigures),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              slice.category?.name ?? 'Kategorisiz',
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatMoney(slice.total),
            style: theme.textTheme.titleSmall
                ?.copyWith(fontFeatures: kTabularFigures),
          ),
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
    final height = context.isWide ? 300.0 : 220.0;

    return SizedBox(
      height: height,
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
                    child: Text(
                      _monthLabels[months[i].month - 1],
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: _barGroups(context),
        ),
      ),
    );
  }

  List<BarChartGroupData> _barGroups(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final income = context.money.income;
    return [
      for (var i = 0; i < months.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: months[i].income, color: income, width: 8),
            BarChartRodData(
                toY: months[i].expense, color: scheme.error, width: 8),
          ],
        ),
    ];
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
