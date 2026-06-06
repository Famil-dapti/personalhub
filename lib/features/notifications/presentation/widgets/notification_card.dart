import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../data/models/notification_model.dart';
import 'notification_visuals.dart';

/// Archive list row: brand avatar, "app · relative time" header, bold title,
/// 2-line body, and a transaction badge when the item looks like a payment.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.item,
    this.selected = false,
    this.onTap,
    this.showDevice = false,
  });

  final NotificationItem item;
  final bool selected;
  final VoidCallback? onTap;
  // Whether to surface the capturing-device name (only useful with 2+ phones).
  final bool showDevice;

  String? get _deviceLabel =>
      (showDevice && (item.deviceName ?? '').isNotEmpty)
          ? item.deviceName
          : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      color: selected ? scheme.secondaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBrandAvatar(source: item.sourceLabel),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.sourceLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          formatRelativeTime(item.displayTime),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    if ((item.title ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.title!,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if ((item.body ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.body!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.isTransaction || _deviceLabel != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          if (item.isTransaction) const TransactionBadge(),
                          if (item.isTransaction)
                            const SizedBox(width: AppSpacing.xs),
                          if (item.isTransaction)
                            TextButton(
                              onPressed: onTap,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm),
                                minimumSize: const Size(0, 32),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Islem olustur'),
                            ),
                          if ((item.isTransaction) && _deviceLabel != null)
                            const SizedBox(width: AppSpacing.sm),
                          if (_deviceLabel != null)
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.smartphone,
                                      size: 12, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _deviceLabel!,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                          color: scheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill marking a notification the heuristic flagged as a payment.
class TransactionBadge extends StatelessWidget {
  const TransactionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadii.chipR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined,
              size: 14, color: scheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            'Islem',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
