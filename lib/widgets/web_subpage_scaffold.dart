import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_layout.dart';
import '../utils/settings_navigation.dart';
import 'desktop_content.dart';

/// Content-area layout for sub-pages on desktop web (sidebar stays visible).
class WebSubpageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? trailing;
  final bool showBackButton;

  const WebSubpageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
    this.showBackButton = true,
  });

  static bool useWebPanel(BuildContext context) =>
      ResponsiveLayout.isDesktopWeb(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      body: DesktopContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Row(
                children: [
                  if (showBackButton)
                    SettingsNavigation.materialBackButton(context)
                  else
                    const SizedBox(width: 44),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.getDynamicTitle3(context).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
