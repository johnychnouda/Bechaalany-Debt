import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'app_colors.dart';
import 'android_theme.dart';
import 'android_colors.dart';
import '../providers/app_state.dart';

class PlatformTheme {
  // Platform Detection
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  
  // Get platform-specific light theme
  static ThemeData getLightTheme(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.lightTheme;
    } else {
      return AppTheme.lightTheme; // Your existing iOS theme
    }
  }
  
  // Get platform-specific dark theme
  static ThemeData getDarkTheme(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.darkTheme;
    } else {
      return AppTheme.darkTheme; // Your existing iOS theme
    }
  }
  
  // Get current theme based on platform and dark mode preference
  static ThemeData getCurrentTheme(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.isDarkMode ? getDarkTheme(context) : getLightTheme(context);
  }
  
  // Platform-specific typography methods
  static TextStyle getDisplayLarge(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicDisplayLarge(context);
    } else {
      return AppTheme.getDynamicLargeTitle(context);
    }
  }
  
  static TextStyle getDisplayMedium(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicDisplayMedium(context);
    } else {
      return AppTheme.getDynamicTitle1(context);
    }
  }
  
  static TextStyle getDisplaySmall(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicDisplaySmall(context);
    } else {
      return AppTheme.getDynamicTitle2(context);
    }
  }
  
  static TextStyle getHeadlineLarge(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicHeadlineLarge(context);
    } else {
      return AppTheme.getDynamicTitle3(context);
    }
  }
  
  static TextStyle getHeadlineMedium(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicHeadlineMedium(context);
    } else {
      return AppTheme.getDynamicHeadline(context);
    }
  }
  
  static TextStyle getHeadlineSmall(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicHeadlineSmall(context);
    } else {
      return AppTheme.getDynamicHeadline(context);
    }
  }
  
  static TextStyle getTitleLarge(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicTitleLarge(context);
    } else {
      return AppTheme.getDynamicTitle3(context);
    }
  }
  
  static TextStyle getTitleMedium(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicTitleMedium(context);
    } else {
      return AppTheme.getDynamicCallout(context);
    }
  }
  
  static TextStyle getTitleSmall(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicTitleSmall(context);
    } else {
      return AppTheme.getDynamicSubheadline(context);
    }
  }
  
  static TextStyle getBodyLarge(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicBodyLarge(context);
    } else {
      return AppTheme.getDynamicBody(context);
    }
  }
  
  static TextStyle getBodyMedium(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicBodyMedium(context);
    } else {
      return AppTheme.getDynamicCallout(context);
    }
  }
  
  static TextStyle getBodySmall(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicBodySmall(context);
    } else {
      return AppTheme.getDynamicFootnote(context);
    }
  }
  
  static TextStyle getLabelLarge(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicLabelLarge(context);
    } else {
      return AppTheme.getDynamicCaption1(context);
    }
  }
  
  static TextStyle getLabelMedium(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicLabelMedium(context);
    } else {
      return AppTheme.getDynamicCaption1(context);
    }
  }
  
  static TextStyle getLabelSmall(BuildContext context) {
    if (isAndroid) {
      return AndroidTheme.getDynamicLabelSmall(context);
    } else {
      return AppTheme.getDynamicCaption2(context);
    }
  }
  
  // Platform-specific spacing methods
  static double getSpacing4() {
    if (isAndroid) {
      return AndroidTheme.spacing4;
    } else {
      return AppTheme.spacing4;
    }
  }
  
  static double getSpacing8() {
    if (isAndroid) {
      return AndroidTheme.spacing8;
    } else {
      return AppTheme.spacing8;
    }
  }
  
  static double getSpacing12() {
    if (isAndroid) {
      return AndroidTheme.spacing12;
    } else {
      return AppTheme.spacing12;
    }
  }
  
  static double getSpacing16() {
    if (isAndroid) {
      return AndroidTheme.spacing16;
    } else {
      return AppTheme.spacing16;
    }
  }
  
  static double getSpacing20() {
    if (isAndroid) {
      return AndroidTheme.spacing20;
    } else {
      return AppTheme.spacing20;
    }
  }
  
  static double getSpacing24() {
    if (isAndroid) {
      return AndroidTheme.spacing24;
    } else {
      return AppTheme.spacing24;
    }
  }
  
  static double getSpacing32() {
    if (isAndroid) {
      return AndroidTheme.spacing32;
    } else {
      return AppTheme.spacing32;
    }
  }
  
  static double getSpacing40() {
    if (isAndroid) {
      return AndroidTheme.spacing40;
    } else {
      return AppTheme.spacing40;
    }
  }
  
  static double getSpacing48() {
    if (isAndroid) {
      return AndroidTheme.spacing48;
    } else {
      return AppTheme.spacing48;
    }
  }
  
  static double getSpacing56() {
    if (isAndroid) {
      return AndroidTheme.spacing56;
    } else {
      return AppTheme.spacing56;
    }
  }
  
  static double getSpacing64() {
    if (isAndroid) {
      return AndroidTheme.spacing64;
    } else {
      return AppTheme.spacing64;
    }
  }
  
  static double getSpacing80() {
    if (isAndroid) {
      return AndroidTheme.spacing80;
    } else {
      return AppTheme.spacing80;
    }
  }
  
  static double getSpacing96() {
    if (isAndroid) {
      return AndroidTheme.spacing96;
    } else {
      return AppTheme.spacing96;
    }
  }
  
  // Platform-specific radius methods
  static double getRadius4() {
    if (isAndroid) {
      return AndroidTheme.radius4;
    } else {
      return AppTheme.radius4;
    }
  }
  
  static double getRadius8() {
    if (isAndroid) {
      return AndroidTheme.radius8;
    } else {
      return AppTheme.radius8;
    }
  }
  
  static double getRadius12() {
    if (isAndroid) {
      return AndroidTheme.radius12;
    } else {
      return AppTheme.radius12;
    }
  }
  
  static double getRadius16() {
    if (isAndroid) {
      return AndroidTheme.radius16;
    } else {
      return AppTheme.radius16;
    }
  }
  
  static double getRadius20() {
    if (isAndroid) {
      return AndroidTheme.radius20;
    } else {
      return AppTheme.radius20;
    }
  }
  
  static double getRadius24() {
    if (isAndroid) {
      return AndroidTheme.radius24;
    } else {
      return AppTheme.radius24;
    }
  }
  
  static double getRadius32() {
    if (isAndroid) {
      return AndroidTheme.radius32;
    } else {
      return AppTheme.radius32;
    }
  }
  
  // Platform-specific color methods (delegating to appropriate color system)
  static Color getPrimary(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicPrimary(context);
    } else {
      return AppColors.primary;
    }
  }
  
  static Color getOnPrimary(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOnPrimary(context);
    } else {
      return Colors.white;
    }
  }
  
  static Color getPrimaryContainer(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicPrimaryContainer(context);
    } else {
      return AppColors.primaryLight;
    }
  }
  
  static Color getOnPrimaryContainer(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOnPrimaryContainer(context);
    } else {
      return AppColors.primaryDark;
    }
  }
  
  static Color getSecondary(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicSecondary(context);
    } else {
      return AppColors.secondary;
    }
  }
  
  static Color getOnSecondary(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOnSecondary(context);
    } else {
      return Colors.white;
    }
  }
  
  static Color getSurface(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicSurface(context);
    } else {
      return AppColors.dynamicSurface(context);
    }
  }
  
  static Color getOnSurface(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOnSurface(context);
    } else {
      return AppColors.dynamicTextPrimary(context);
    }
  }
  
  static Color getSurfaceVariant(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicSurfaceVariant(context);
    } else {
      return AppColors.backgroundSecondary;
    }
  }
  
  static Color getOnSurfaceVariant(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOnSurfaceVariant(context);
    } else {
      return AppColors.dynamicTextSecondary(context);
    }
  }
  
  static Color getBackground(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicBackground(context);
    } else {
      return AppColors.dynamicBackground(context);
    }
  }
  
  static Color getOnBackground(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOnBackground(context);
    } else {
      return AppColors.dynamicTextPrimary(context);
    }
  }
  
  static Color getError(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicError(context);
    } else {
      return AppColors.error;
    }
  }
  
  static Color getOnError(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOnError(context);
    } else {
      return Colors.white;
    }
  }
  
  static Color getErrorContainer(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicErrorContainer(context);
    } else {
      return AppColors.error;
    }
  }
  
  static Color getOnErrorContainer(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOnErrorContainer(context);
    } else {
      return Colors.white;
    }
  }
  
  static Color getOutline(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOutline(context);
    } else {
      return AppColors.dynamicBorder(context);
    }
  }
  
  static Color getOutlineVariant(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicOutlineVariant(context);
    } else {
      return AppColors.dynamicDivider(context);
    }
  }
  
  static Color getTextPrimary(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicTextPrimary(context);
    } else {
      return AppColors.dynamicTextPrimary(context);
    }
  }
  
  static Color getTextSecondary(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicTextSecondary(context);
    } else {
      return AppColors.dynamicTextSecondary(context);
    }
  }
  
  static Color getTextTertiary(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicTextTertiary(context);
    } else {
      return AppColors.dynamicTextSecondary(context);
    }
  }
  
  static Color getBorder(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicBorder(context);
    } else {
      return AppColors.dynamicBorder(context);
    }
  }
  
  static Color getDivider(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicDivider(context);
    } else {
      return AppColors.dynamicDivider(context);
    }
  }
  
  static Color getSeparator(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.dynamicSeparator(context);
    } else {
      return AppColors.dynamicSeparator(context);
    }
  }
  
  // Platform-specific success colors
  static Color getSuccess(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.success;
    } else {
      return AppColors.success;
    }
  }
  
  static Color getOnSuccess(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.onSuccess;
    } else {
      return Colors.white;
    }
  }
  
  // Platform-specific warning colors
  static Color getWarning(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.warning;
    } else {
      return AppColors.warning;
    }
  }
  
  static Color getOnWarning(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.onWarning;
    } else {
      return Colors.white;
    }
  }
  
  // Platform-specific info colors
  static Color getInfo(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.info;
    } else {
      return AppColors.info;
    }
  }
  
  static Color getOnInfo(BuildContext context) {
    if (isAndroid) {
      return AndroidColors.onInfo;
    } else {
      return Colors.white;
    }
  }
}
