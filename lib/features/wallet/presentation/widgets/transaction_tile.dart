import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../providers/category_provider.dart';
import 'category_visuals.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onTap,
  });

  final Transaction transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoryMapProvider)[transaction.categoryId];
    final color = categoryColor(category, theme.colorScheme.primary);
    final amountColor =
        transaction.isIncome ? Colors.green.shade600 : theme.colorScheme.error;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(categoryIcon(category), color: color),
      ),
      title: Row(
        children: [
          Flexible(child: Text(category?.name ?? 'Kategorisiz')),
          if (transaction.pending) ...[
            const SizedBox(width: 8),
            _DraftBadge(scheme: theme.colorScheme),
          ],
        ],
      ),
      subtitle: Text(
        [
          if (transaction.description?.isNotEmpty ?? false)
            transaction.description!,
          formatDate(transaction.createdAt),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        formatSignedMoney(transaction.amount),
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: amountColor, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
      onLongPress: onDelete,
    );
  }
}

/// "Taslak" chip on an unconfirmed SMS-derived transaction (Phase 4).
class _DraftBadge extends StatelessWidget {
  const _DraftBadge({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Taslak',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}
