import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/media_scanner.dart';
import '../../data/models/media_models.dart';
import '../providers/media_providers.dart';
import '../widgets/media_card.dart';
import '../widgets/media_filter_sheet.dart';
import '../widgets/media_stats_panel.dart';

/// Phase 3 Media Cleaner entry point. Web shows a stats-only view; mobile gates
/// on photo/video access, runs the index, then shows the swipe review deck.
class MediaCleanerScreen extends ConsumerWidget {
  const MediaCleanerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(mediaSupportedProvider)) return const _MediaWebView();

    final access = ref.watch(mediaAccessProvider);
    return access.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => _MediaScaffold(child: _MediaError(message: e.toString())),
      data: (value) => value == MediaAccess.denied
          ? const _MediaScaffold(child: _MediaPermissionView())
          : const _MediaDeck(),
    );
  }
}

class _MediaScaffold extends StatelessWidget {
  const _MediaScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medya Temizligi')),
      body: child,
    );
  }
}

// --- Permission gate ------------------------------------------------------

class _MediaPermissionView extends ConsumerWidget {
  const _MediaPermissionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'Foto ve video erisimi gerekli',
        message: 'Medyani gozden gecirip temizleyebilmek icin galeri erisimi '
            'vermen gerekiyor. Android 13 ve sonrasinda sistem foto ve video '
            'icin ayri ayri izin ister.',
        action: FilledButton.icon(
          onPressed: () => ref.invalidate(mediaAccessProvider),
          icon: const Icon(Icons.lock_open),
          label: const Text('Izin ver'),
        ),
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Bir sorun olustu',
      message: message,
    );
  }
}

// --- Deck (index -> progress -> swipe) ------------------------------------

class _MediaDeck extends ConsumerStatefulWidget {
  const _MediaDeck();

  @override
  ConsumerState<_MediaDeck> createState() => _MediaDeckState();
}

class _MediaDeckState extends ConsumerState<_MediaDeck> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startIndexing());
  }

  void _startIndexing() {
    final index = ref.read(mediaIndexControllerProvider);
    if (!index.running && !index.done) {
      ref.read(mediaIndexControllerProvider.notifier).run();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(mediaIndexControllerProvider);
    final deck = ref.watch(mediaDeckProvider).valueOrNull ?? const [];
    final pendingCount =
        ref.watch(mediaPendingDeleteCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medya Temizligi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filtre ve siralama',
            onPressed: () => showMediaFilterSheet(context),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.delete_sweep_outlined),
            ),
            tooltip: 'Silinecekler',
            onPressed: () => context.push('/media/delete'),
          ),
        ],
      ),
      body: _body(index, deck),
    );
  }

  Widget _body(MediaIndexState index, List<MediaAsset> deck) {
    if (index.error != null) return _IndexError(message: index.error!);
    if (index.running && deck.isEmpty) return _IndexProgress(state: index);
    if (deck.isEmpty) return const _DeckEmpty();
    return _DeckContent(controller: _controller, deck: deck);
  }
}

class _IndexProgress extends StatelessWidget {
  const _IndexProgress({required this.state});

  final MediaIndexState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LinearProgressIndicator(value: state.total == 0 ? null : state.progress),
          AppSpacing.gapLg,
          Text(
            'Taraniyor... ${state.processed}/${state.total}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _IndexError extends ConsumerWidget {
  const _IndexError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Tarama basarisiz',
      message: message,
      action: FilledButton.icon(
        onPressed: () => ref.read(mediaIndexControllerProvider.notifier).run(),
        icon: const Icon(Icons.refresh),
        label: const Text('Tekrar dene'),
      ),
    );
  }
}

class _DeckEmpty extends ConsumerWidget {
  const _DeckEmpty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRandom = ref.watch(mediaSortProvider) == MediaSortOrder.random;
    return EmptyState(
      icon: Icons.check_circle_outline,
      title: 'Hepsi incelendi',
      message: 'Bu filtreyle gozden gecirilecek medya kalmadi.',
      action: Wrap(
        spacing: AppSpacing.sm,
        children: [
          FilledButton.icon(
            onPressed: () =>
                ref.read(mediaDeckRefreshProvider.notifier).state++,
            icon: const Icon(Icons.refresh),
            label: const Text('Yeniden tara'),
          ),
          if (isRandom)
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(mediaDeckRefreshProvider.notifier).state++,
              icon: const Icon(Icons.shuffle),
              label: const Text('Karistir'),
            ),
        ],
      ),
    );
  }
}

class _DeckContent extends ConsumerWidget {
  const _DeckContent({required this.controller, required this.deck});

  final CardSwiperController controller;
  final List<MediaAsset> deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild the swiper from scratch whenever the deck composition changes.
    final swiperKey = ValueKey(
      '${ref.watch(mediaTypeFilterProvider)}_${ref.watch(mediaSortProvider)}'
      '_${ref.watch(mediaAlbumFilterProvider)}'
      '_${ref.watch(mediaScreenshotsOnlyProvider)}'
      '_${ref.watch(mediaDeckRefreshProvider)}_${deck.length}',
    );
    final stats = _thisDeviceStats(ref);

    return Column(
      children: [
        if (stats != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: MediaStatsPanel(stats: stats, dense: true),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CardSwiper(
              key: swiperKey,
              controller: controller,
              cardsCount: deck.length,
              numberOfCardsDisplayed: math.min(3, deck.length),
              isLoop: false,
              allowedSwipeDirection: const AllowedSwipeDirection.all(),
              onSwipe: (prev, current, direction) =>
                  _onSwipe(ref, context, prev, direction),
              onUndo: (prev, current, direction) => _onUndo(ref, current),
              cardBuilder: (context, index, _, _) =>
                  MediaCard(asset: deck[index]),
            ),
          ),
        ),
        _ActionBar(controller: controller),
      ],
    );
  }

  MediaStats? _thisDeviceStats(WidgetRef ref) {
    final all = ref.watch(mediaStatsProvider).valueOrNull;
    if (all == null || all.isEmpty) return null;
    if (deck.isEmpty) return all.first;
    final deviceId = deck.first.deviceId;
    for (final s in all) {
      if (s.deviceId == deviceId) return s;
    }
    return null;
  }

  Future<bool> _onSwipe(WidgetRef ref, BuildContext context, int prev,
      CardSwiperDirection direction) async {
    if (prev < 0 || prev >= deck.length) return true;
    final kind = _kindFor(direction);
    if (kind == null) return true;
    final error =
        await ref.read(mediaCleanerControllerProvider).decide(deck[prev], kind);
    if (error != null && context.mounted) {
      AppFeedback.error(context, 'Kaydedilemedi. Tekrar deneyin.');
    }
    return true;
  }

  // onUndo must return bool synchronously; the revert runs in the background.
  bool _onUndo(WidgetRef ref, int current) {
    if (current < 0 || current >= deck.length) return true;
    ref.read(mediaCleanerControllerProvider).undo(deck[current]);
    return true;
  }

  // CardSwiperDirection is a class of static const values, not an enum.
  MediaDecisionKind? _kindFor(CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.left) return MediaDecisionKind.delete;
    if (direction == CardSwiperDirection.right) return MediaDecisionKind.keep;
    if (direction == CardSwiperDirection.top) return MediaDecisionKind.favorite;
    if (direction == CardSwiperDirection.bottom) return MediaDecisionKind.later;
    return null;
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller});

  final CardSwiperController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.delete_outline,
              label: 'Sil',
              color: scheme.error,
              onPressed: () => controller.swipe(CardSwiperDirection.left),
            ),
            _ActionButton(
              icon: Icons.schedule,
              label: 'Sonra',
              color: scheme.tertiary,
              onPressed: () => controller.swipe(CardSwiperDirection.bottom),
            ),
            _ActionButton(
              icon: Icons.star_outline,
              label: 'Favori',
              color: scheme.secondary,
              onPressed: () => controller.swipe(CardSwiperDirection.top),
            ),
            _ActionButton(
              icon: Icons.check,
              label: 'Tut',
              color: scheme.primary,
              onPressed: () => controller.swipe(CardSwiperDirection.right),
            ),
            _ActionButton(
              icon: Icons.undo,
              label: 'Geri al',
              color: scheme.onSurfaceVariant,
              onPressed: controller.undo,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// --- Web stats-only view --------------------------------------------------

class _MediaWebView extends ConsumerWidget {
  const _MediaWebView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(mediaStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Medya')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _MediaError(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const _WebEmpty();
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Bu cihazda medya temizligi yok; istatistikler asagida. '
                'Yakalama ve temizlik telefonda calisir.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              AppSpacing.gapLg,
              for (final s in list) ...[
                MediaStatsPanel(stats: s),
                AppSpacing.gapMd,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WebEmpty extends StatelessWidget {
  const _WebEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        EmptyState(
          icon: Icons.insights_outlined,
          title: 'Henuz istatistik yok',
          message: 'Medya temizligi telefonda calisir. Ilerleme burada gorunur.',
        ),
      ],
    );
  }
}
