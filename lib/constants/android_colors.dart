import 'package:flutter/material.dart';

class AndroidColors {
  // Android 16 Material You Primary Colors (Dynamic Color System)
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);
  
  // Android 16 Material You Secondary Colors
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);
  
  // Android 16 Material You Tertiary Colors
  static const Color tertiary = Color(0xFF7D5260);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  static const Color onTertiaryContainer = Color(0xFF31111D);
  
  // Android 16 Material You Surface Colors
  static const Color surface = Color(0xFFFEF7FF);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  static const Color surfaceContainerHighest = Color(0xFFF3EDF7);
  static const Color surfaceContainerHigh = Color(0xFFF7F2FA);
  static const Color surfaceContainer = Color(0xFFFBF8FD);
  static const Color surfaceContainerLow = Color(0xFFFEF7FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  
  // Android 16 Material You Background Colors
  static const Color background = Color(0xFFFEF7FF);
  static const Color onBackground = Color(0xFF1C1B1F);
  
  // Android 16 Material You Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
  
  // Android 16 Material You Outline Colors
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
  
  // Android 16 Material You State Colors
  static const Color scrim = Color(0xFF000000);
  static const Color inverseSurface = Color(0xFF313033);
  static const Color onInverseSurface = Color(0xFFF4EFF4);
  static const Color inversePrimary = Color(0xFFD0BCFF);
  
  // Android 16 Material You Shadow Colors
  static const Color shadow = Color(0xFF000000);
  static const Color surfaceTint = Color(0xFF6750A4);
  
  // Android 16 Material You Success Colors (Custom for debt app)
  static const Color success = Color(0xFF4CAF50);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color onSuccessContainer = Color(0xFF1B5E20);
  
  // Android 16 Material You Warning Colors (Custom for debt app)
  static const Color warning = Color(0xFFFF9800);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color onWarningContainer = Color(0xFFE65100);
  
  // Android 16 Material You Info Colors (Custom for debt app)
  static const Color info = Color(0xFF2196F3);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFBBDEFB);
  static const Color onInfoContainer = Color(0xFF0D47A1);
  
  // Android 16 Material You Debt Status Colors (Custom for debt app)
  static const Color debtPaid = Color(0xFF4CAF50);
  static const Color debtPending = Color(0xFFFF9800);
  static const Color debtOverdue = Color(0xFFF44336);
  
  // Android 16 Material You Text Colors
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textTertiary = Color(0xFF79747E);
  static const Color textDisabled = Color(0xFFCAC4D0);
  
  // Android 16 Material You Border Colors
  static const Color border = Color(0xFF79747E);
  static const Color divider = Color(0xFFE7E0EC);
  static const Color separator = Color(0xFFCAC4D0);
  
  // Android 16 Material You System Colors (Dynamic Color System)
  static const Color systemBlue = Color(0xFF2196F3);
  static const Color systemGreen = Color(0xFF4CAF50);
  static const Color systemOrange = Color(0xFFFF9800);
  static const Color systemRed = Color(0xFFF44336);
  static const Color systemPurple = Color(0xFF9C27B0);
  static const Color systemTeal = Color(0xFF009688);
  static const Color systemIndigo = Color(0xFF3F51B5);
  static const Color systemPink = Color(0xFFE91E63);
  static const Color systemLime = Color(0xFFCDDC39);
  static const Color systemAmber = Color(0xFFFFC107);
  static const Color systemCyan = Color(0xFF00BCD4);
  static const Color systemDeepOrange = Color(0xFFFF5722);
  static const Color systemLightGreen = Color(0xFF8BC34A);
  static const Color systemDeepPurple = Color(0xFF673AB7);
  static const Color systemBrown = Color(0xFF795548);
  static const Color systemGrey = Color(0xFF9E9E9E);
  static const Color systemBlueGrey = Color(0xFF607D8B);
  
  // Android 16 Material You Dynamic Color Methods
  static Color dynamicPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }
  
  static Color dynamicOnPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }
  
  static Color dynamicPrimaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.primaryContainer;
  }
  
  static Color dynamicOnPrimaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimaryContainer;
  }
  
  static Color dynamicSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }
  
  static Color dynamicOnSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondary;
  }
  
  static Color dynamicSecondaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.secondaryContainer;
  }
  
  static Color dynamicOnSecondaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondaryContainer;
  }
  
  static Color dynamicSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }
  
  static Color dynamicOnSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }
  
  static Color dynamicSurfaceVariant(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceVariant;
  }
  
  static Color dynamicOnSurfaceVariant(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
  
  static Color dynamicBackground(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }
  
  static Color dynamicOnBackground(BuildContext context) {
    return Theme.of(context).colorScheme.onBackground;
  }
  
  static Color dynamicError(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
  
  static Color dynamicOnError(BuildContext context) {
    return Theme.of(context).colorScheme.onError;
  }
  
  static Color dynamicErrorContainer(BuildContext context) {
    return Theme.of(context).colorScheme.errorContainer;
  }
  
  static Color dynamicOnErrorContainer(BuildContext context) {
    return Theme.of(context).colorScheme.onErrorContainer;
  }
  
  static Color dynamicOutline(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }
  
  static Color dynamicOutlineVariant(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }
  
  static Color dynamicTextPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }
  
  static Color dynamicTextSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
  
  static Color dynamicTextTertiary(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }
  
  static Color dynamicBorder(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }
  
  static Color dynamicDivider(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }
  
  static Color dynamicSeparator(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }
}
