import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_spacing.dart';
import '../providers/notifications_provider.dart';

/// Horizontal scrolling filter chips: Tumu / Islemler / one per source app.
/// Selection is held in [notificationFilterProvider].
class NotificationFilterChipRow extends ConsumerWidget {
  const NotificationFilterChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(notificationFilterProvider);
    final apps = ref.watch(notificationAppsProvider);

    final chips = <_ChipSpec>[
      const _ChipSpec(kFilterAll, 'Tumu'),
      const _ChipSpec(kFilterTransactions, 'Islemler'),
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
          return Center(
            child: ChoiceChip(
              label: Text(chip.label),
              selected: selected == chip.value,
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
  const _ChipSpec(this.value, this.label);
  final String value;
  final String label;
}
