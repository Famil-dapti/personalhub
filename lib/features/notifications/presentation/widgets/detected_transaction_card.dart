import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../domain/parsed_transaction.dart';

/// Highlighted card on a notification flagged as a payment. Shows the amount
/// and direction read by the device-side parser (if any) and the action to
/// create an editable wallet transaction. When the parser found nothing the
/// user can still add it manually (the form opens empty).
class DetectedTransactionCard extends StatelessWidget {
  const DetectedTransactionCard({
    super.key,
    this.readOnly = false,
    this.onCreate,
    this.parsed,
  });

  final bool readOnly;
  final VoidCallback? onCreate;
  final ParsedTransaction? parsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = parsed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadii.cardR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: scheme.onPrimaryContainer),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Islem olarak algilandi',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ],
          ),
          AppSpacing.gapSm,
          if (p != null)
            Text(
              '${p.direction == TxnDirection.income ? 'Gelir' : 'Gider'}: '
              '${p.amountMagnitude.toStringAsFixed(2)} ${p.currency}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontFeatures: kTabularFigures,
              ),
            )
          else
            Text(
              'Tutar otomatik okunamadi; cuzdana eklerken elle girebilirsiniz.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          if (!readOnly) ...[
            AppSpacing.gapMd,
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Cuzdana ekle'),
            ),
          ],
        ],
      ),
    );
  }
}
