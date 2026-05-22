import 'package:flutter/material.dart';

import '../utils/responsive_layout.dart';

/// Centers page content and caps width on web so lists do not stretch edge-to-edge.
class DesktopContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const DesktopContent({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.useWebContentConstraints(context)) {
      return child;
    }

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ResponsiveLayout.maxContentWidth),
        child: content,
      ),
    );
  }
}
