import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/category_model.dart';
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
        transaction.isIncome ? context.money.income : theme.colorScheme.error;

    return ListTile(
      leading: _CategoryAvatar(category: category, color: color),
      title: Row(
        children: [
          Flexible(
            child: Text(
              category?.name ?? 'Kategorisiz',
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (transaction.pending) ...[
            const SizedBox(width: 8),
            _DraftBadge(scheme: theme.colorScheme),
          ],
        ],
      ),
      subtitle: Text(
        _subtitle(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Text(
        formatSignedMoney(transaction.amount),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w600,
          fontFeatures: kTabularFigures,
        ),
      ),
      onTap: onTap,
      onLongPress: onDelete,
    );
  }

  String _subtitle() {
    return [
      if (transaction.description?.isNotEmpty ?? false)
        transaction.description!,
      formatDate(transaction.createdAt),
    ].join(' · ');
  }
}

/// 44px tinted circle holding the category glyph at its own color.
class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({required this.category, required this.color});

  final Category? category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Icon(categoryIcon(category), color: color, size: 22),
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
