import 'package:flutter/material.dart';

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
  });

  final NotificationItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                    if (item.isTransaction) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const TransactionBadge(),
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
        borderRadius: BorderRadius.circular(AppSpacing.sm),
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
