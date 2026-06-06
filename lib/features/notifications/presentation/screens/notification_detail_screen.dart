import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
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
                onCreateTransaction: () => AppFeedback.success(
                  context,
                  'Cuzdan entegrasyonu sonraki asamada gelecek',
                ),
              ),
            ),
    );
  }
}
