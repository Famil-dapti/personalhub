import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../models/transaction_prefill.dart';
import '../providers/wallet_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuzdan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Ozet',
            onPressed: () => context.push('/wallet/dashboard'),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Kategoriler',
            onPressed: () => context.push('/wallet/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cikis',
            onPressed: () => ref.read(supabaseClientProvider).auth.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncServiceProvider).syncAll(),
        child: transactions.when(
          loading: () => const _WalletLoading(),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (items) => _WalletBody(items: items, ref: ref),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/wallet/add'),
        icon: const Icon(Icons.add),
        label: const Text('Islem Ekle'),
      ),
    );
  }
}

class _WalletLoading extends StatelessWidget {
  const _WalletLoading();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          Card(
            margin: EdgeInsets.all(AppSpacing.lg),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 80, height: 12),
                  AppSpacing.gapMd,
                  SkeletonBox(width: 180, height: 28),
                  AppSpacing.gapXl,
                  SkeletonBox(height: 14),
                ],
              ),
            ),
          ),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
        ],
      ),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({required this.items, required this.ref});

  final List<Transaction> items;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: [
          const BalanceCard(),
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Henuz islem yok',
            message: 'Ilk gelir veya giderini eklemek icin asagidaki butona dokun.',
          ),
        ],
      );
    }

    return ListView(
      children: [
        const BalanceCard(),
        ..._buildGroupedRows(context),
        AppSpacing.fabClearance,
      ],
    );
  }

  // Groups transactions into day sections, preserving the repository's
  // newest-first order. Each section gets a header followed by its tiles.
  List<Widget> _buildGroupedRows(BuildContext context) {
    final rows = <Widget>[];
    DateTime? currentDay;
    for (final t in items) {
      final day = dayKey(t.createdAt);
      if (currentDay == null || day != currentDay) {
        currentDay = day;
        rows.add(_DayHeader(label: formatDayHeader(t.createdAt)));
      }
      rows.add(
        Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          confirmDismiss: (_) => _confirmDelete(context, t.id),
          child: TransactionTile(
            transaction: t,
            onDelete: () => _confirmDelete(context, t.id),
            // Tapping a draft opens the pre-filled form; saving commits it.
            onTap: t.pending ? () => _editDraft(context, t) : null,
          ),
        ),
      );
    }
    return rows;
  }

  void _editDraft(BuildContext context, Transaction t) {
    context.push(
      '/wallet/add',
      extra: TransactionPrefill(
        existingTransactionId: t.id,
        amountMagnitude: t.amount.abs(),
        kind: t.isIncome ? CategoryKind.income : CategoryKind.expense,
        description: t.description,
        notificationId: t.notificationId,
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Islemi sil'),
        content: const Text('Bu islem silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _delete(context, id);
      return true;
    }
    return false;
  }

  Future<void> _delete(BuildContext context, String id) async {
    final error =
        await ref.read(transactionsControllerProvider).remove(id);
    if (!context.mounted) return;
    if (error == null) {
      AppFeedback.success(context, 'Islem silindi');
    } else {
      AppFeedback.error(context, 'Silinemedi: $error');
    }
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

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
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
