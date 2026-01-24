import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'app_theme.dart';
import 'app_colors.dart';
import '../providers/app_state.dart';

class PlatformTheme {
  // Cross-platform detection
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  
  // Get iOS light theme
  static ThemeData getLightTheme(BuildContext context) {
    return AppTheme.lightTheme;
  }
  
  // Get iOS dark theme
  static ThemeData getDarkTheme(BuildContext context) {
    return AppTheme.darkTheme;
  }
  
  // Get current theme based on platform and dark mode preference
  static ThemeData getCurrentTheme(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.isDarkMode ? getDarkTheme(context) : getLightTheme(context);
  }
  
  // iOS typography methods
  static TextStyle getDisplayLarge(BuildContext context) {
    return AppTheme.getDynamicLargeTitle(context);
  }
  
  static TextStyle getDisplayMedium(BuildContext context) {
    return AppTheme.getDynamicTitle1(context);
  }
  
  static TextStyle getDisplaySmall(BuildContext context) {
    return AppTheme.getDynamicTitle2(context);
  }
  
  static TextStyle getHeadlineLarge(BuildContext context) {
    return AppTheme.getDynamicTitle3(context);
  }
  
  static TextStyle getHeadlineMedium(BuildContext context) {
    return AppTheme.getDynamicHeadline(context);
  }
  
  static TextStyle getHeadlineSmall(BuildContext context) {
    return AppTheme.getDynamicHeadline(context);
  }
  
  static TextStyle getTitleLarge(BuildContext context) {
    return AppTheme.getDynamicTitle3(context);
  }
  
  static TextStyle getTitleMedium(BuildContext context) {
    return AppTheme.getDynamicCallout(context);
  }
  
  static TextStyle getTitleSmall(BuildContext context) {
    return AppTheme.getDynamicSubheadline(context);
  }
  
  static TextStyle getBodyLarge(BuildContext context) {
    return AppTheme.getDynamicBody(context);
  }
  
  static TextStyle getBodyMedium(BuildContext context) {
    return AppTheme.getDynamicCallout(context);
  }
  
  static TextStyle getBodySmall(BuildContext context) {
    return AppTheme.getDynamicFootnote(context);
  }
  
  static TextStyle getLabelLarge(BuildContext context) {
    return AppTheme.getDynamicCaption1(context);
  }
  
  static TextStyle getLabelMedium(BuildContext context) {
    return AppTheme.getDynamicCaption1(context);
  }
  
  static TextStyle getLabelSmall(BuildContext context) {
    return AppTheme.getDynamicCaption2(context);
  }
  
  // iOS spacing methods
  static double getSpacing4() {
    return AppTheme.spacing4;
  }
  
  static double getSpacing8() {
    return AppTheme.spacing8;
  }
  
  static double getSpacing12() {
    return AppTheme.spacing12;
  }
  
  static double getSpacing16() {
    return AppTheme.spacing16;
  }
  
  static double getSpacing20() {
    return AppTheme.spacing20;
  }
  
  static double getSpacing24() {
    return AppTheme.spacing24;
  }
  
  static double getSpacing32() {
    return AppTheme.spacing32;
  }
  
  static double getSpacing40() {
    return AppTheme.spacing40;
  }
  
  static double getSpacing48() {
    return AppTheme.spacing48;
  }
  
  static double getSpacing56() {
    return AppTheme.spacing56;
  }
  
  static double getSpacing64() {
    return AppTheme.spacing64;
  }
  
  static double getSpacing80() {
    return AppTheme.spacing80;
  }
  
  static double getSpacing96() {
    return AppTheme.spacing96;
  }
  
  // iOS radius methods
  static double getRadius4() {
    return AppTheme.radius4;
  }
  
  static double getRadius8() {
    return AppTheme.radius8;
  }
  
  static double getRadius12() {
    return AppTheme.radius12;
  }
  
  static double getRadius16() {
    return AppTheme.radius16;
  }
  
  static double getRadius20() {
    return AppTheme.radius20;
  }
  
  static double getRadius24() {
    return AppTheme.radius24;
  }
  
  static double getRadius32() {
    return AppTheme.radius32;
  }
  
  // iOS color methods
  static Color getPrimary(BuildContext context) {
    return AppColors.primary;
  }
  
  static Color getOnPrimary(BuildContext context) {
    return Colors.white;
  }
  
  static Color getPrimaryContainer(BuildContext context) {
    return AppColors.primaryLight;
  }
  
  static Color getOnPrimaryContainer(BuildContext context) {
    return AppColors.primaryDark;
  }
  
  static Color getSecondary(BuildContext context) {
    return AppColors.secondary;
  }
  
  static Color getOnSecondary(BuildContext context) {
    return Colors.white;
  }
  
  static Color getSurface(BuildContext context) {
    return AppColors.dynamicSurface(context);
  }
  
  static Color getOnSurface(BuildContext context) {
    return AppColors.dynamicTextPrimary(context);
  }
  
  static Color getSurfaceVariant(BuildContext context) {
    return AppColors.backgroundSecondary;
  }
  
  static Color getOnSurfaceVariant(BuildContext context) {
    return AppColors.dynamicTextSecondary(context);
  }
  
  static Color getBackground(BuildContext context) {
    return AppColors.dynamicBackground(context);
  }
  
  static Color getOnBackground(BuildContext context) {
    return AppColors.dynamicTextPrimary(context);
  }
  
  static Color getError(BuildContext context) {
    return AppColors.error;
  }
  
  static Color getOnError(BuildContext context) {
    return Colors.white;
  }
  
  static Color getErrorContainer(BuildContext context) {
    return AppColors.error;
  }
  
  static Color getOnErrorContainer(BuildContext context) {
    return Colors.white;
  }
  
  static Color getOutline(BuildContext context) {
    return AppColors.dynamicBorder(context);
  }
  
  static Color getOutlineVariant(BuildContext context) {
    return AppColors.dynamicDivider(context);
  }
  
  static Color getTextPrimary(BuildContext context) {
    return AppColors.dynamicTextPrimary(context);
  }
  
  static Color getTextSecondary(BuildContext context) {
    return AppColors.dynamicTextSecondary(context);
  }
  
  static Color getTextTertiary(BuildContext context) {
    return AppColors.dynamicTextSecondary(context);
  }
  
  static Color getBorder(BuildContext context) {
    return AppColors.dynamicBorder(context);
  }
  
  static Color getDivider(BuildContext context) {
    return AppColors.dynamicDivider(context);
  }
  
  static Color getSeparator(BuildContext context) {
    return AppColors.dynamicSeparator(context);
  }
  
  // iOS success colors
  static Color getSuccess(BuildContext context) {
    return AppColors.success;
  }
  
  static Color getOnSuccess(BuildContext context) {
    return Colors.white;
  }
  
  // iOS warning colors
  static Color getWarning(BuildContext context) {
    return AppColors.warning;
  }
  
  static Color getOnWarning(BuildContext context) {
    return Colors.white;
  }
  
  // iOS info colors
  static Color getInfo(BuildContext context) {
    return AppColors.info;
  }
  
  static Color getOnInfo(BuildContext context) {
    return Colors.white;
  }
}
