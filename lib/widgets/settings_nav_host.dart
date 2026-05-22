import 'package:flutter/material.dart';

/// Marks [SettingsScreen]'s inner web navigator so sub-pages push inside the
/// content pane while the sidebar stays visible.
class SettingsNavHost extends InheritedWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const SettingsNavHost({
    super.key,
    required this.navigatorKey,
    required super.child,
  });

  static SettingsNavHost? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SettingsNavHost>();
  }

  @override
  bool updateShouldNotify(SettingsNavHost oldWidget) =>
      navigatorKey != oldWidget.navigatorKey;
}
