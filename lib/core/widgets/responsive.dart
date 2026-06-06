import 'package:flutter/widgets.dart';

/// Shared responsive breakpoint. At or above this width we switch from the
/// phone layout (bottom nav, pushed sub-screens) to the desktop layout
/// (left nav rail, two-pane / master-detail).
const double kWideBreakpoint = 840;

/// Max content width for centered desktop layouts (forms, single columns).
const double kContentMaxWidth = 1120;

extension Responsive on BuildContext {
  /// True when the current layout width warrants the desktop chrome.
  bool get isWide => MediaQuery.sizeOf(this).width >= kWideBreakpoint;
}
