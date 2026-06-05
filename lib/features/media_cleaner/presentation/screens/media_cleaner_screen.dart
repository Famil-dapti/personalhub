import 'package:flutter/material.dart';

class MediaCleanerScreen extends StatelessWidget {
  const MediaCleanerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Media Cleaner')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Media Cleaner', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Coming in Phase 3', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
