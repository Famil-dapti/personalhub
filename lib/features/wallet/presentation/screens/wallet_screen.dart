import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../models/transaction_prefill.dart';
import '../providers/category_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/category_visuals.dart';
import '../widgets/transaction_tile.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  // Desktop-only client-side filter over the already-loaded list.
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final isWide = context.isWide;

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
          loading: () => _WalletLoading(isWide: isWide),
          error: (e, _) => _ErrorView(message: e.toString(), ref: ref),
          data: (items) => isWide
              ? _WideBody(
                  items: items,
                  ref: ref,
                  query: _query,
                  onQuery: (q) => setState(() => _query = q),
                )
              : _PhoneBody(items: items, ref: ref),
        ),
      ),
      // Quick-add lives inline on desktop; phone keeps the pushed screen.
      floatingActionButton: isWide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/wallet/add'),
              icon: const Icon(Icons.add),
              label: const Text('Islem Ekle'),
            ),
    );
  }
}

// --- Day grouping (shared by phone + desktop) ---------------------------------

List<Widget> buildGroupedRows(
  BuildContext context,
  WidgetRef ref,
  List<Transaction> items,
) {
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
        confirmDismiss: (_) => _confirmDelete(context, ref, t.id),
        child: TransactionTile(
          transaction: t,
          onDelete: () => _confirmDelete(context, ref, t.id),
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

Future<bool> _confirmDelete(
    BuildContext context, WidgetRef ref, String id) async {
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
    final error = await ref.read(transactionsControllerProvider).remove(id);
    if (!context.mounted) return true;
    if (error == null) {
      AppFeedback.success(context, 'Islem silindi');
    } else {
      AppFeedback.error(context, 'Silinemedi: $error');
    }
    return true;
  }
  return false;
}

// --- Phone layout -------------------------------------------------------------

class _PhoneBody extends StatelessWidget {
  const _PhoneBody({required this.items, required this.ref});

  final List<Transaction> items;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: BalanceCard(),
          ),
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Henuz islem yok',
            message:
                'Ilk gelir veya giderini eklemek icin asagidaki butona dokun.',
            action: FilledButton.tonalIcon(
              onPressed: () => context.push('/wallet/add'),
              icon: const Icon(Icons.add),
              label: const Text('Islem Ekle'),
            ),
          ),
        ],
      );
    }

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: BalanceCard(),
        ),
        ...buildGroupedRows(context, ref, items),
        AppSpacing.fabClearance,
      ],
    );
  }
}

// --- Desktop layout -----------------------------------------------------------

class _WideBody extends StatelessWidget {
  const _WideBody({
    required this.items,
    required this.ref,
    required this.query,
    required this.onQuery,
  });

  final List<Transaction> items;
  final WidgetRef ref;
  final String query;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final filtered = _filter(items, query, ref);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 380,
                child: ListView(
                  children: const [
                    BalanceCard(),
                    SizedBox(height: AppSpacing.xxl),
                    _QuickAddCard(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: _RightColumn(
                  items: filtered,
                  ref: ref,
                  query: query,
                  onQuery: onQuery,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Transaction> _filter(
      List<Transaction> items, String query, WidgetRef ref) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    final categories = ref.read(categoryMapProvider);
    return items.where((t) {
      final desc = t.description?.toLowerCase() ?? '';
      final cat = categories[t.categoryId]?.name.toLowerCase() ?? '';
      return desc.contains(q) || cat.contains(q);
    }).toList();
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({
    required this.items,
    required this.ref,
    required this.query,
    required this.onQuery,
  });

  final List<Transaction> items;
  final WidgetRef ref;
  final String query;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Islemler', style: theme.textTheme.titleMedium),
            const Spacer(),
            SizedBox(
              width: 240,
              child: TextField(
                onChanged: onQuery,
                decoration: const InputDecoration(
                  hintText: 'Islem ara',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _wideList(context)),
      ],
    );
  }

  Widget _wideList(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: query.trim().isEmpty
            ? Icons.receipt_long_outlined
            : Icons.search_off,
        title: 'Henuz islem yok',
        message: query.trim().isEmpty
            ? 'Ilk gelir veya giderini soldaki formdan ekle.'
            : 'Aramana uyan islem bulunamadi.',
      );
    }
    return ListView(children: buildGroupedRows(context, ref, items));
  }
}

/// Inline quick-add card (desktop). Commits via the SAME controller used by
/// the add-transaction screen so behavior stays identical.
class _QuickAddCard extends ConsumerStatefulWidget {
  const _QuickAddCard();

  @override
  ConsumerState<_QuickAddCard> createState() => _QuickAddCardState();
}

class _QuickAddCardState extends ConsumerState<_QuickAddCard> {
  final _amountController = TextEditingController();
  CategoryKind _kind = CategoryKind.expense;
  String? _categoryId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final options = categories.where((c) => c.kind == _kind).take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hizli Ekle', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<CategoryKind>(
              segments: const [
                ButtonSegment(
                  value: CategoryKind.expense,
                  label: Text('Gider'),
                  icon: Icon(Icons.north_east),
                ),
                ButtonSegment(
                  value: CategoryKind.income,
                  label: Text('Gelir'),
                  icon: Icon(Icons.south_west),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tutar',
                suffixText: 'AZN',
              ),
              style: TextStyle(fontFeatures: kTabularFigures),
            ),
            const SizedBox(height: AppSpacing.md),
            _QuickChips(
              options: options,
              selectedId: _categoryId,
              onSelected: (id) => setState(() => _categoryId = id),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final magnitude =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (magnitude == null || magnitude <= 0) {
      setState(() => _error = 'Gecerli bir tutar girin');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Bir kategori secin');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final signed = _kind == CategoryKind.expense ? -magnitude : magnitude;
    final transaction = Transaction(
      id: '',
      userId: '',
      amount: signed,
      createdAt: DateTime.now(),
      categoryId: _categoryId,
    );

    final error = await ref.read(transactionsControllerProvider).add(transaction);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    _amountController.clear();
    setState(() {
      _saving = false;
      _categoryId = null;
    });
    AppFeedback.success(context, 'Islem eklendi');
  }
}

class _QuickChips extends StatelessWidget {
  const _QuickChips({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (options.isEmpty) {
      return Text(
        'Bu tur icin kategori yok',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((c) {
        final color = categoryColor(c, theme.colorScheme.primary);
        return ChoiceChip(
          selected: c.id == selectedId,
          avatar: Icon(categoryIcon(c), size: 18, color: color),
          label: Text(c.name),
          onSelected: (_) => onSelected(c.id),
        );
      }).toList(),
    );
  }
}

// --- Shared pieces ------------------------------------------------------------

class _WalletLoading extends StatelessWidget {
  const _WalletLoading({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final rows = isWide ? 6 : 4;
    return Skeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SkeletonBox(height: 150, radius: AppRadii.balance),
          AppSpacing.gapLg,
          for (var i = 0; i < rows; i++) const SkeletonListTile(),
        ],
      ),
    );
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
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadii.cardR,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: scheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Sil',
            style: TextStyle(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.ref});

  final String message;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Bir sorun olustu',
          message: message,
          tone: EmptyStateTone.error,
          action: FilledButton.tonalIcon(
            onPressed: () => ref.read(syncServiceProvider).syncAll(),
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar dene'),
          ),
        ),
      ],
    );
  }
}
