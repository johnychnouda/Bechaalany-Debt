import 'package:flutter/material.dart';

/// Overrides [MaterialApp]'s root "error" [DefaultTextStyle] (yellow underline on
/// unstyled text). Use via [MaterialApp.builder] and [CupertinoMaterialPageScaffold].
class AppDefaultTextStyle {
  AppDefaultTextStyle._();

  static TextStyle resolve(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
      color: theme.colorScheme.onSurface,
    );
  }

  static Widget wrap(BuildContext context, Widget child) {
    return DefaultTextStyle(
      style: resolve(context),
      child: child,
    );
  }
}
