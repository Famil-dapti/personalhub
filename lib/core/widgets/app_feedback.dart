import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Centralized snackbar feedback so success/error toasts look the same
/// everywhere. Floating, rounded, and theme-driven (success = inverse-surface
/// with a brand check icon; error = errorContainer). Each call clears any
/// queued snackbar first to avoid stacking.
abstract final class AppFeedback {
  static void success(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    _show(
      context,
      message,
      icon: Icons.check_circle_rounded,
      foreground: scheme.onInverseSurface,
      iconColor: scheme.inversePrimary,
    );
  }

  static void error(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    _show(
      context,
      message,
      icon: Icons.error_rounded,
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      iconColor: scheme.onErrorContainer,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    Color? background,
    Color? foreground,
    Color? iconColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        content: Row(
          children: [
            Icon(icon, color: iconColor ?? foreground, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
