import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Navigation helpers for pages opened from [SettingsScreen] (and related flows).
///
/// Uses the nearest [Navigator] (shell or settings inner stack on web) so the
/// sidebar stays visible on desktop web.
class SettingsNavigation {
  SettingsNavigation._();

  static NavigatorState _nearestNavigator(BuildContext context) {
    return Navigator.of(context, rootNavigator: false);
  }

  static NavigatorState _rootNavigator(BuildContext context) {
    return Navigator.of(context, rootNavigator: true);
  }

  /// Pushes a sub-page on the nearest navigator (keeps web sidebar visible).
  static Future<T?> pushSubpage<T>(BuildContext context, Widget page) {
    return _nearestNavigator(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Pops one level (back to Settings list, Products, etc.).
  static void popSubpage(BuildContext context) {
    final navigator = _nearestNavigator(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Cupertino nav bar back control for mobile layouts.
  static Widget cupertinoBackButton(BuildContext context) {
    return CupertinoNavigationBarBackButton(
      onPressed: () => popSubpage(context),
    );
  }

  /// Material-style back icon for web panel headers.
  static Widget materialBackButton(BuildContext context) {
    return IconButton(
      onPressed: () => popSubpage(context),
      icon: Icon(
        Icons.arrow_back_ios_rounded,
        color: AppColors.dynamicTextPrimary(context),
        size: 24,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }

  /// Clears the entire app stack and shows [page] (sign-out, delete account).
  static void pushAndClearToRoot(BuildContext context, Widget page) {
    _rootNavigator(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => page),
      (route) => false,
    );
  }
}
