import 'package:flutter/widgets.dart';

/// Design spacing tokens. Replaces ad-hoc magic numbers across the UI so
/// padding and gaps stay consistent (4 / 8 / 12 / 16 / 20 / 24 / 32 scale).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Reusable vertical gaps.
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);

  // Clears the floating action button so the last list item stays tappable.
  static const SizedBox fabClearance = SizedBox(height: 88);
}
