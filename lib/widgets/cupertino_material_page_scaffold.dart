import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_default_text_style.dart';

/// Drop-in replacement for [CupertinoPageScaffold] that wraps [child] with
/// [Material] + [DefaultTextStyle] so text never inherits MaterialApp's error
/// style (yellow underline) in release builds.
///
/// Prefer this over raw [CupertinoPageScaffold] for all new Cupertino screens.
class CupertinoMaterialPageScaffold extends StatelessWidget {
  final ObstructingPreferredSizeWidget? navigationBar;
  final Color? backgroundColor;
  final Widget child;

  const CupertinoMaterialPageScaffold({
    super.key,
    this.navigationBar,
    this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: navigationBar,
      backgroundColor: backgroundColor,
      child: Material(
        type: MaterialType.transparency,
        child: AppDefaultTextStyle.wrap(context, child),
      ),
    );
  }
}
