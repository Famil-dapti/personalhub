import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../providers/category_provider.dart';
import 'category_visuals.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({super.key, required this.transaction, this.onDelete});

  final Transaction transaction;
  final VoidCallback? onDelete;

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
      title: Text(category?.name ?? 'Kategorisiz'),
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
      onLongPress: onDelete,
    );
  }
}
