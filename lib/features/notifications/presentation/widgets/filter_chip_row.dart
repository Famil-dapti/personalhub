import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../providers/notifications_provider.dart';

/// Horizontal scrolling filter chips: Tumu / Islemler / one per source app.
/// Selection is held in [notificationFilterProvider].
class NotificationFilterChipRow extends ConsumerWidget {
  const NotificationFilterChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(notificationFilterProvider);
    final apps = ref.watch(notificationAppsProvider);

    final chips = <_ChipSpec>[
      const _ChipSpec(kFilterAll, 'Tumu'),
      const _ChipSpec(kFilterTransactions, 'Islemler',
          icon: Icons.payments_outlined),
      for (final app in apps) _ChipSpec(app, app),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final isSelected = selected == chip.value;
          return Center(
            child: ChoiceChip(
              label: Text(chip.label),
              avatar: chip.icon == null
                  ? null
                  : Icon(
                      chip.icon,
                      size: 18,
                      color: isSelected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: scheme.primaryContainer,
              labelStyle: isSelected
                  ? TextStyle(color: scheme.onPrimaryContainer)
                  : null,
              shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.chipR),
              onSelected: (_) => ref
                  .read(notificationFilterProvider.notifier)
                  .state = chip.value,
            ),
          );
        },
      ),
    );
  }
}

class _ChipSpec {
  const _ChipSpec(this.value, this.label, {this.icon});
  final String value;
  final String label;
  final IconData? icon;
}
