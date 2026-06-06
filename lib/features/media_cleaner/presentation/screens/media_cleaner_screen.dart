import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/responsive.dart';
import '../../data/media_scanner.dart';
import '../../data/models/media_models.dart';
import '../providers/media_providers.dart';
import '../widgets/format_bytes.dart';
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
        icon: Icons.no_photography_outlined,
        tone: EmptyStateTone.brand,
        title: 'Medya erisimi yok',
        message: 'Foto ve video erisimi gerekli. Medyani gozden gecirip '
            'temizleyebilmek icin galeri erisimi vermen gerekiyor. Android 13 '
            've sonrasinda sistem foto ve video icin ayri ayri izin ister.',
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
      tone: EmptyStateTone.error,
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
          Text('Medya taraniyor', style: theme.textTheme.titleMedium),
          AppSpacing.gapLg,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
                value: state.total == 0 ? null : state.progress, minHeight: 6),
          ),
          AppSpacing.gapMd,
          Text(
            '${state.processed} / ${state.total}',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: kTabularFigures),
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
      tone: EmptyStateTone.error,
      title: 'Bir sorun olustu',
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
      tone: EmptyStateTone.brand,
      title: 'Tumu incelendi',
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
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: _DeckTypeFilter(),
        ),
        if (stats != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: _FreedSpaceMeter(stats: stats),
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

// Segmented type filter above the deck (Tumu / Fotograflar / Videolar).
class _DeckTypeFilter extends ConsumerWidget {
  const _DeckTypeFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(mediaTypeFilterProvider);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<MediaTypeFilter>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: MediaTypeFilter.all, label: Text('Tumu')),
          ButtonSegment(
              value: MediaTypeFilter.photos, label: Text('Fotograflar')),
          ButtonSegment(
              value: MediaTypeFilter.videos, label: Text('Videolar')),
        ],
        selected: {value},
        onSelectionChanged: (s) =>
            ref.read(mediaTypeFilterProvider.notifier).state = s.first,
      ),
    );
  }
}

// Progress meter: "Ilerleme NNN / NNN" + freed-space estimate + thin bar.
// The estimate sums the byte sizes of assets currently queued for deletion.
class _FreedSpaceMeter extends ConsumerWidget {
  const _FreedSpaceMeter({required this.stats});

  final MediaStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pending = ref.watch(mediaPendingDeletesProvider).valueOrNull;
    final freed = (pending ?? const <MediaAsset>[])
        .fold<int>(0, (sum, a) => sum + a.sizeBytes);
    final figures = theme.textTheme.bodyMedium
        ?.copyWith(fontFeatures: kTabularFigures);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Ilerleme ', style: theme.textTheme.bodyMedium),
            Text('${stats.decided} / ${stats.total}', style: figures),
            const Spacer(),
            Flexible(
              child: Text('Bosaltilacak (tahmini) ',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
            Text('~${formatBytes(freed)}',
                style: figures?.copyWith(
                    color: context.money.income,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        AppSpacing.gapSm,
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: stats.progress,
            minHeight: 5,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
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
              foreground: scheme.onErrorContainer,
              background: scheme.errorContainer,
              onPressed: () => controller.swipe(CardSwiperDirection.left),
            ),
            _ActionButton(
              icon: Icons.schedule,
              label: 'Sonra',
              foreground: scheme.tertiary,
              background: scheme.tertiaryContainer,
              onPressed: () => controller.swipe(CardSwiperDirection.bottom),
            ),
            _ActionButton(
              icon: Icons.star_outline,
              label: 'Favori',
              foreground: scheme.onSecondaryContainer,
              background: scheme.secondaryContainer,
              onPressed: () => controller.swipe(CardSwiperDirection.top),
            ),
            _ActionButton(
              icon: Icons.check,
              label: 'Tut',
              foreground: scheme.onPrimaryContainer,
              background: scheme.primaryContainer,
              onPressed: () => controller.swipe(CardSwiperDirection.right),
            ),
            _ActionButton(
              icon: Icons.undo,
              label: 'Geri al',
              foreground: scheme.onSurfaceVariant,
              background: scheme.surfaceContainerHighest,
              onPressed: controller.undo,
            ),
          ],
        ),
      ),
    );
  }
}

// Circular tonal action button with a label below. 56px target (>=48 min).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Material(
            color: background,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Icon(icon, color: foreground),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// --- Web / desktop companion dashboard ------------------------------------

// Read-only companion: a browser cannot read device media, so this is a brand
// dashboard (hero + aggregate stats + per-device history), not the swipe tool.
class _MediaWebView extends ConsumerWidget {
  const _MediaWebView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(mediaStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Medya Temizligi')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _MediaError(message: e.toString()),
        data: (list) => list.isEmpty ? const _WebEmpty() : _WebDashboard(list),
      ),
    );
  }
}

class _WebDashboard extends StatelessWidget {
  const _WebDashboard(this.list);

  final List<MediaStats> list;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agg = _WebAggregate.of(list);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_done_outlined, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text('Senklendi',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            AppSpacing.gapMd,
            const _CompanionHero(),
            AppSpacing.gapXl,
            _WebStatRow(agg: agg),
            AppSpacing.gapXl,
            Text('Son oturumlar', style: theme.textTheme.titleMedium),
            AppSpacing.gapMd,
            for (final s in list) ...[
              MediaStatsPanel(stats: s),
              AppSpacing.gapMd,
            ],
          ],
        ),
      ),
    );
  }
}

// Sums per-device counters into a single set of dashboard figures. There is no
// freed-bytes field on MediaStats, so only counts are aggregated here.
class _WebAggregate {
  const _WebAggregate(
      {required this.reviewed, required this.kept, required this.deleted});

  final int reviewed;
  final int kept;
  final int deleted;

  static _WebAggregate of(List<MediaStats> list) {
    var reviewed = 0, kept = 0, deleted = 0;
    for (final s in list) {
      reviewed += s.decided;
      kept += s.kept;
      deleted += s.deleted;
    }
    return _WebAggregate(reviewed: reviewed, kept: kept, deleted: deleted);
  }
}

class _CompanionHero extends StatelessWidget {
  const _CompanionHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sheet),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: context.isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(child: _HeroText()),
                SizedBox(width: AppSpacing.xxl),
                _QrPlaceholder(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _HeroText(),
                SizedBox(height: AppSpacing.xl),
                _QrPlaceholder(),
              ],
            ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onHero = theme.colorScheme.onPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('COMPANION',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: onHero, letterSpacing: 2)),
        AppSpacing.gapSm,
        Text('Medya temizligi telefonda calisir',
            style: theme.textTheme.headlineMedium?.copyWith(color: onHero)),
        AppSpacing.gapMd,
        Text(
          'Tarayicilar cihaz medyasina erisemez. Telefonunda temizligi yap; '
          'ilerleme ve istatistikler burada gorunur.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: onHero.withValues(alpha: 0.9)),
        ),
        AppSpacing.gapLg,
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
          ),
          onPressed: () => AppFeedback.success(
              context, 'Telefonunda PersonalHub uygulamasini ac'),
          icon: const Icon(Icons.phone_iphone),
          label: const Text('Telefonda ac'),
        ),
      ],
    );
  }
}

// Visual-only QR stand-in (no QR dependency added).
class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.qr_code_2, size: 88, color: scheme.onSurfaceVariant),
    );
  }
}

class _WebStatRow extends StatelessWidget {
  const _WebStatRow({required this.agg});

  final _WebAggregate agg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // No freed-bytes field on MediaStats -> the "Bosaltilan alan" card is
    // omitted and only real counts are shown.
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: [
        _WebStatCard(
            label: 'Incelenen dosya',
            value: agg.reviewed,
            color: scheme.onSurface),
        _WebStatCard(
            label: 'Saklanan',
            value: agg.kept,
            color: context.money.income),
        _WebStatCard(label: 'Silinen', value: agg.deleted, color: scheme.error),
      ],
    );
  }
}

class _WebStatCard extends StatelessWidget {
  const _WebStatCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          AppSpacing.gapSm,
          Text('$value',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: color, fontFeatures: kTabularFigures)),
        ],
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
          icon: Icons.cloud_sync_outlined,
          tone: EmptyStateTone.brand,
          title: 'Henuz istatistik yok',
          message: 'Medya temizligi telefonda calisir. Telefonda ilk '
              'temizligi yaptiginizda ilerleme burada gorunur.',
        ),
      ],
    );
  }
}
