import 'package:flutter/material.dart';

/// Centralized snackbar feedback so success/error toasts look the same
/// everywhere. Each call clears any queued snackbar first to avoid stacking.
abstract final class AppFeedback {
  static void success(BuildContext context, String message) {
    _show(context, message, icon: Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    _show(
      context,
      message,
      icon: Icons.error_outline,
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    Color? background,
    Color? foreground,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
        backgroundColor: background,
      ),
    );
  }
}
