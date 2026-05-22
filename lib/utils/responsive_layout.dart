import 'package:flutter/material.dart';

import 'platform_utils.dart';

/// Breakpoints and helpers for browser (web) layouts. Native iOS/Android are unchanged.
class ResponsiveLayout {
  ResponsiveLayout._();

  static const double desktopBreakpoint = 840;
  static const double maxContentWidth = 1280;
  static const double sidebarWidth = 260;

  /// True when running in a browser (Flutter web).
  static bool get isWeb => PlatformUtils.isBrowserContext;

  /// Sidebar + desktop chrome on wide browser viewports.
  static bool isDesktopWeb(BuildContext context) {
    if (!isWeb) return false;
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  /// Centered content with max width on any browser width.
  static bool useWebContentConstraints(BuildContext context) => isWeb;
}
