import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Friendly centered empty state: an 84px circular icon badge + title +
/// optional hint and action. Used wherever a list or section has no data yet.
///
/// Set [tone] to recolor the badge for error/info contexts (per tokens spec:
/// neutral uses `surfaceContainerHigh`, error uses `errorContainer`).
enum EmptyStateTone { neutral, error, brand }

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.tone = EmptyStateTone.neutral,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final EmptyStateTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (Color badge, Color fg) = switch (tone) {
      EmptyStateTone.neutral => (scheme.surfaceContainerHigh, scheme.outline),
      EmptyStateTone.error => (scheme.errorContainer, scheme.onErrorContainer),
      EmptyStateTone.brand => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: badge, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, size: 40, color: fg),
            ),
            AppSpacing.gapXl,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            if (message != null) ...[
              AppSpacing.gapSm,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[
              AppSpacing.gapXl,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
