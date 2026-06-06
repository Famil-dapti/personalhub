import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/wallet_provider.dart';

/// Hero balance card: a deep-teal gradient panel surfacing the running balance
/// plus this month's income/expense tiles. Reads from [walletSummaryProvider].
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(walletSummaryProvider);
    final isDark = theme.brightness == Brightness.dark;
    final onColor = isDark
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onPrimary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.balanceR,
        gradient: _gradient(theme, isDark),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bakiye',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: onColor.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(summary.balance),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onColor,
              fontFeatures: kTabularFigures,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Bu ay gelir',
                  amount: summary.monthIncome,
                  icon: Icons.south_west,
                  onColor: onColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'Bu ay gider',
                  amount: summary.monthExpense,
                  icon: Icons.north_east,
                  onColor: onColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 150deg gradient: primary -> darker mix (light), container -> darker (dark).
  LinearGradient _gradient(ThemeData theme, bool isDark) {
    final scheme = theme.colorScheme;
    final start = isDark ? scheme.primaryContainer : scheme.primary;
    final end = isDark
        ? Color.lerp(scheme.primaryContainer, Colors.black, 0.30)!
        : Color.lerp(scheme.primary, const Color(0xFF063B2A), 0.30)!;
    return LinearGradient(
      colors: [start, end],
      transform: const GradientRotation(150 * 3.1415926535 / 180),
    );
  }
}

/// One translucent income/expense tile inside the balance card.
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.onColor,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadii.fieldR,
      ),
      child: Row(
        children: [
          Icon(icon, color: onColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: onColor.withValues(alpha: 0.85)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatMoney(amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: onColor,
                    fontFeatures: kTabularFigures,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
