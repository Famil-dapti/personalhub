import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../providers/category_provider.dart';
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
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
          ref.invalidate(categoriesProvider);
          await ref.read(transactionsProvider.future);
        },
        child: transactions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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

class _WalletBody extends StatelessWidget {
  const _WalletBody({required this.items, required this.ref});

  final List items;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const BalanceCard(),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: Text('Henuz islem yok')),
          )
        else
          ...items.map(
            (t) => TransactionTile(
              transaction: t,
              onDelete: () => _confirmDelete(context, ref, t.id),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _confirmDelete(
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
    if (confirmed != true) return;
    await ref.read(transactionsProvider.notifier).removeTransaction(id);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Center(child: Text('Hata: $message')),
      ],
    );
  }
}
