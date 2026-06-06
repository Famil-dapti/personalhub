import 'package:flutter/material.dart';

import '../../../../core/widgets/app_spacing.dart';

/// First-run / access-not-granted screen for the Android notification listener.
/// Deep-links the user to the system "Notification access" settings.
class PermissionScreen extends StatelessWidget {
  const PermissionScreen({
    super.key,
    required this.onOpenSettings,
    required this.onLater,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.notifications_active,
                  size: 48, color: scheme.onPrimaryContainer),
            ),
            AppSpacing.gapXl,
            Text(
              'Bildirim erisimi gerekli',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            AppSpacing.gapMd,
            Text(
              'Bildirimleri arsivlemek icin PersonalHub\'a bildirim erisimi '
              'vermen gerekiyor. Ayarlar acilacak; listeden PersonalHub\'i '
              'bulup izni etkinlestir.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            AppSpacing.gapLg,
            Card(
              color: scheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: scheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Bildirimler yalnizca senin hesabina kaydedilir. '
                        'Veriler cihazinda ve kendi Supabase hesabinda tutulur.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapXl,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Ayarlari ac'),
              ),
            ),
            AppSpacing.gapSm,
            TextButton(
              onPressed: onLater,
              child: const Text('Daha sonra'),
            ),
          ],
        ),
      ),
    );
  }
}
