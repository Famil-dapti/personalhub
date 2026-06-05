import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Notification Archiver', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Coming in Phase 2', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
