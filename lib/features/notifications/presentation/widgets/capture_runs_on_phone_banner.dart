import 'package:flutter/material.dart';

import '../../../../core/widgets/app_spacing.dart';

/// Persistent banner on the desktop/web archive making the capture model clear:
/// notifications are intercepted on the Android phone; this view is read-only.
class CaptureRunsOnPhoneBanner extends StatelessWidget {
  const CaptureRunsOnPhoneBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.smartphone, size: 20, color: scheme.onTertiaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Yakalama Android telefonunuzda calisir. Bu gorunum salt-okunurdur.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
