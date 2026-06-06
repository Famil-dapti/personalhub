import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../widgets/capture_runs_on_phone_banner.dart';
import '../widgets/detected_transaction_card.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_visuals.dart';
import '../widgets/raw_payload_block.dart';
import '../widgets/search_field.dart';

// Above this width the archive switches to a master-detail layout.
const double _wideBreakpoint = 840;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Yenile',
            onPressed: () => ref.read(syncServiceProvider).syncAll(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth >= _wideBreakpoint
              ? const _DesktopArchive()
              : const _PhoneArchive();
        },
      ),
    );
  }
}

// --- Phone: list, tap pushes a detail route ------------------------------

class _PhoneArchive extends ConsumerWidget {
  const _PhoneArchive();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
          child: NotificationSearchField(),
        ),
        NotificationFilterChipRow(),
        AppSpacing.gapSm,
        Expanded(child: _ArchiveList(selectable: false)),
      ],
    );
  }
}

// --- Desktop/Web: master-detail, read-only -------------------------------

class _DesktopArchive extends ConsumerWidget {
  const _DesktopArchive();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SizedBox(
          width: 420,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md,
                    AppSpacing.lg, AppSpacing.sm),
                child: NotificationSearchField(),
              ),
              NotificationFilterChipRow(),
              AppSpacing.gapSm,
              Expanded(child: _ArchiveList(selectable: true)),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(child: _DesktopDetailPane()),
      ],
    );
  }
}

// --- Shared list (grouped by day) ----------------------------------------

class _ArchiveList extends ConsumerWidget {
  const _ArchiveList({required this.selectable});

  // When true (desktop) tapping selects in place; otherwise it pushes a route.
  final bool selectable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return async.when(
      loading: () => const _ListLoading(),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (all) {
        if (all.isEmpty) return const _EmptyArchive();
        final items = ref.watch(filteredNotificationsProvider);
        if (items.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Text('Sonuc yok'),
          ));
        }
        final selectedId = ref.watch(selectedNotificationIdProvider);
        return RefreshIndicator(
          onRefresh: () => ref.read(syncServiceProvider).syncAll(),
          child: ListView(
            children: [
              ..._buildGroupedRows(context, ref, items, selectedId),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedRows(
    BuildContext context,
    WidgetRef ref,
    List<NotificationItem> items,
    String? selectedId,
  ) {
    final rows = <Widget>[];
    DateTime? currentDay;
    for (final n in items) {
      final day = dayKey(n.displayTime);
      if (currentDay == null || day != currentDay) {
        currentDay = day;
        rows.add(_DayHeader(label: formatDayHeader(n.displayTime)));
      }
      rows.add(
        NotificationCard(
          item: n,
          selected: selectable && n.id == selectedId,
          onTap: () {
            ref.read(selectedNotificationIdProvider.notifier).state = n.id;
            if (!selectable) context.push('/notifications/detail');
          },
        ),
      );
    }
    return rows;
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        label,
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}

// --- Desktop detail pane --------------------------------------------------

class _DesktopDetailPane extends ConsumerWidget {
  const _DesktopDetailPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(selectedNotificationProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CaptureRunsOnPhoneBanner(),
          AppSpacing.gapLg,
          Expanded(
            child: item == null
                ? const Center(child: Text('Bir bildirim secin'))
                : SingleChildScrollView(
                    child: NotificationDetailBody(item: item, readOnly: true),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Shared detail body (phone screen + desktop pane) --------------------

class NotificationDetailBody extends StatelessWidget {
  const NotificationDetailBody({
    super.key,
    required this.item,
    this.readOnly = false,
    this.onCreateTransaction,
  });

  final NotificationItem item;
  final bool readOnly;
  final VoidCallback? onCreateTransaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppBrandAvatar(source: item.sourceLabel, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.sourceLabel, style: theme.textTheme.titleMedium),
                  Text(
                    '${formatDate(item.displayTime)} · ${formatTime(item.displayTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.gapLg,
        if ((item.title ?? '').isNotEmpty) ...[
          Text(item.title!, style: theme.textTheme.headlineSmall),
          AppSpacing.gapSm,
        ],
        if ((item.body ?? '').isNotEmpty) ...[
          Text(item.body!, style: theme.textTheme.bodyLarge),
          AppSpacing.gapLg,
        ],
        if (item.isTransaction) ...[
          DetectedTransactionCard(
            readOnly: readOnly,
            onCreate: onCreateTransaction,
          ),
          AppSpacing.gapLg,
        ],
        RawPayloadBlock(item: item),
      ],
    );
  }
}

// --- States ---------------------------------------------------------------

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
        ],
      ),
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        EmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'Henuz bildirim yok',
          message: 'Yakalama Android telefonunuzda calisir. '
              'Bildirimler geldikce burada gorunur.',
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Bir sorun olustu',
          message: message,
        ),
      ],
    );
  }
}
