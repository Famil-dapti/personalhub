import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../data/models/media_models.dart';
import '../providers/media_providers.dart';

/// Bottom sheet that drives the deck's filter/sort StateProviders. Writing them
/// already rebuilds [mediaDeckProvider]; no extra refresh needed.
Future<void> showMediaFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _MediaFilterSheet(),
  );
}

class _MediaFilterSheet extends ConsumerWidget {
  const _MediaFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtre ve siralama', style: theme.textTheme.titleMedium),
            AppSpacing.gapLg,
            _SectionLabel('Tur'),
            AppSpacing.gapSm,
            const _TypeSelector(),
            AppSpacing.gapLg,
            _SectionLabel('Siralama'),
            AppSpacing.gapSm,
            const _SortSelector(),
            AppSpacing.gapLg,
            _SectionLabel('Album'),
            AppSpacing.gapSm,
            const _AlbumDropdown(),
            AppSpacing.gapMd,
            const _ScreenshotsSwitch(),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }
}

class _TypeSelector extends ConsumerWidget {
  const _TypeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(mediaTypeFilterProvider);
    return SegmentedButton<MediaTypeFilter>(
      segments: const [
        ButtonSegment(value: MediaTypeFilter.all, label: Text('Tumu')),
        ButtonSegment(value: MediaTypeFilter.photos, label: Text('Foto')),
        ButtonSegment(value: MediaTypeFilter.videos, label: Text('Video')),
      ],
      selected: {value},
      onSelectionChanged: (s) =>
          ref.read(mediaTypeFilterProvider.notifier).state = s.first,
    );
  }
}

class _SortSelector extends ConsumerWidget {
  const _SortSelector();

  static const _labels = {
    MediaSortOrder.newest: 'En yeni',
    MediaSortOrder.oldest: 'En eski',
    MediaSortOrder.largest: 'En buyuk',
    MediaSortOrder.random: 'Rastgele',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(mediaSortProvider);
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final entry in _labels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: value == entry.key,
            onSelected: (_) =>
                ref.read(mediaSortProvider.notifier).state = entry.key,
          ),
      ],
    );
  }
}

class _AlbumDropdown extends ConsumerWidget {
  const _AlbumDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(mediaAlbumsProvider).valueOrNull ?? const [];
    final selected = ref.watch(mediaAlbumFilterProvider);
    return DropdownButtonFormField<String?>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(borderRadius: AppRadii.fieldR),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Tum albumler')),
        for (final a in albums)
          DropdownMenuItem<String?>(value: a, child: Text(a)),
      ],
      onChanged: (v) => ref.read(mediaAlbumFilterProvider.notifier).state = v,
    );
  }
}

class _ScreenshotsSwitch extends ConsumerWidget {
  const _ScreenshotsSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(mediaScreenshotsOnlyProvider);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Sadece ekran goruntuleri'),
      value: value,
      onChanged: (v) =>
          ref.read(mediaScreenshotsOnlyProvider.notifier).state = v,
    );
  }
}
