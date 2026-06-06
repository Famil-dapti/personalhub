import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_spacing.dart';
import '../../../wallet/data/models/category_model.dart';
import '../../../wallet/presentation/models/transaction_prefill.dart';
import '../../data/models/notification_model.dart';
import '../../domain/parsed_transaction.dart';
import '../providers/extractor_provider.dart';
import '../providers/notifications_provider.dart';
import 'notifications_screen.dart';

/// Pushed detail view for a single notification on phone. Reads the selected
/// item from [selectedNotificationProvider] so it survives list rebuilds.
class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(selectedNotificationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim')),
      body: item == null
          ? const Center(child: Text('Bildirim bulunamadi'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: NotificationDetailBody(
                item: item,
                onCreateTransaction: () => _createTransaction(context, ref, item),
              ),
            ),
    );
  }
}

/// Runs the hybrid extractor (regex, then Groq if a key is set) and opens the
/// pre-filled, editable add-transaction form. A short modal spinner covers the
/// AI round-trip; regex hits are instant.
Future<void> _createTransaction(
  BuildContext context,
  WidgetRef ref,
  NotificationItem item,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  final parsed = await ref.read(transactionExtractorProvider).extract(item);
  if (context.mounted) Navigator.of(context).pop(); // close spinner
  if (!context.mounted) return;

  context.push(
    '/wallet/add',
    extra: TransactionPrefill(
      amountMagnitude: parsed?.amountMagnitude,
      kind: parsed == null
          ? null
          : (parsed.direction == TxnDirection.income
              ? CategoryKind.income
              : CategoryKind.expense),
      description: (item.title?.isNotEmpty ?? false) ? item.title : item.body,
      notificationId: item.id,
    ),
  );
}
