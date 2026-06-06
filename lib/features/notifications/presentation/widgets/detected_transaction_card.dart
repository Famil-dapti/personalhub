import 'package:flutter/material.dart';

import '../../../../core/widgets/app_spacing.dart';

/// Highlighted card shown on a notification flagged as a payment. Amount and
/// category parsing + the actual "add to wallet" link are Phase 4 work, so the
/// action is present on phone but explains that integration is pending.
class DetectedTransactionCard extends StatelessWidget {
  const DetectedTransactionCard({
    super.key,
    this.readOnly = false,
    this.onCreate,
  });

  final bool readOnly;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.md),
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
          Text(
            'Tutar ve kategori cikarimi ile cuzdana ekleme entegrasyonu '
            'sonraki asamada gelecek.',
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
