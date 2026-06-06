import 'package:flutter/material.dart';

import '../../../../core/widgets/app_spacing.dart';
import '../../data/models/media_models.dart';

/// Compact progress card for one device's cleanup stats. Reused as the deck
/// header (this device) and stacked per-device in the web view.
class MediaStatsPanel extends StatelessWidget {
  const MediaStatsPanel({super.key, required this.stats, this.dense = false});

  final MediaStats stats;

  // The deck header is tighter than the standalone web cards.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = (stats.deviceName?.isNotEmpty ?? false)
        ? stats.deviceName!
        : 'Bu cihaz';
    return Card(
      color: scheme.surfaceContainerHigh,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(dense ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smartphone, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall),
                ),
                Text('${stats.decided}/${stats.total} karar verildi',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            AppSpacing.gapSm,
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: LinearProgressIndicator(
                value: stats.progress,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _StatChip(
                    label: 'Tutulan',
                    value: stats.kept,
                    color: scheme.primary),
                _StatChip(
                    label: 'Silinen',
                    value: stats.deleted,
                    color: scheme.error),
                _StatChip(
                    label: 'Kalan',
                    value: stats.remaining,
                    color: scheme.tertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text('$label $value',
          style: theme.textTheme.labelMedium?.copyWith(color: color)),
    );
  }
}
