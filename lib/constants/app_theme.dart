import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import '../providers/app_state.dart';
import '../services/theme_service.dart';

class AppTheme {
  // iOS-style Typography
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.37,
    height: 1.12,
  );
  
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.36,
    height: 1.21,
  );
  
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.35,
    height: 1.27,
  );
  
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    height: 1.25,
  );
  
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    height: 1.29,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.41,
    height: 1.29,
  );
  
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.32,
    height: 1.25,
  );
  
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.24,
    height: 1.33,
  );
  
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.08,
    height: 1.38,
  );
  
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.0,
    height: 1.33,
  );
  
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.07,
    height: 1.45,
  );

  // Dynamic theme methods that use ThemeService
  static TextStyle getDynamicLargeTitle(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 20,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getDynamicTitle1(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 14,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getDynamicTitle2(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 8,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getDynamicTitle3(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 6,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getDynamicHeadline(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 3,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getDynamicBody(BuildContext context) {
    return ThemeService.getTextStyle(context);
  }

  static TextStyle getDynamicCallout(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) - 1,
    );
  }

  static TextStyle getDynamicSubheadline(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) - 2,
    );
  }

  static TextStyle getDynamicFootnote(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) - 4,
    );
  }

  static TextStyle getDynamicCaption1(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) - 5,
    );
  }

  static TextStyle getDynamicCaption2(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) - 6,
    );
  }
  
  // iOS-style Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  static const double spacing80 = 80.0;
  
  // iOS-style Border Radius
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;
  
  // iOS-style Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.41,
      ),
      iconTheme: IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius16),
      ),
      shadowColor: Colors.black.withOpacity(0.08),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing24,
          vertical: spacing16,
        ),
        textStyle: headline.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing24,
          vertical: spacing16,
        ),
        textStyle: headline.copyWith(color: AppColors.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
        textStyle: body.copyWith(color: AppColors.primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
      hintStyle: body.copyWith(color: AppColors.textSecondary),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: CircleBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.separator,
      thickness: 0.5,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: largeTitle,
      displayMedium: title1,
      displaySmall: title2,
      headlineMedium: title3,
      headlineSmall: headline,
      titleMedium: callout,
      titleSmall: subheadline,
      bodyLarge: body,
      bodyMedium: callout,
      bodySmall: footnote,
      labelLarge: caption1,
      labelSmall: caption2,
    ),
  );
  
  // iOS-style Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0A84FF),
      secondary: Color(0xFF30D158),
      surface: Color(0xFF1C1C1E),
      background: Color(0xFF000000),
      error: Color(0xFFFF453A),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.41,
      ),
      iconTheme: IconThemeData(
        color: Color(0xFF0A84FF),
        size: 24,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius16),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing24,
          vertical: spacing16,
        ),
        textStyle: headline.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0A84FF),
        side: const BorderSide(color: Color(0xFF0A84FF), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing24,
          vertical: spacing16,
        ),
        textStyle: headline.copyWith(color: const Color(0xFF0A84FF)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF0A84FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
        textStyle: body.copyWith(color: const Color(0xFF0A84FF)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius12),
        borderSide: const BorderSide(color: Color(0xFF38383A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius12),
        borderSide: const BorderSide(color: Color(0xFF38383A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius12),
        borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius12),
        borderSide: const BorderSide(color: Color(0xFFFF453A)),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
      hintStyle: body.copyWith(color: const Color(0xFF8E8E93)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF0A84FF),
      foregroundColor: Colors.white,
      elevation: 8,
      shape: CircleBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF38383A),
      thickness: 0.5,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: largeTitle,
      displayMedium: title1,
      displaySmall: title2,
      headlineMedium: title3,
      headlineSmall: headline,
      titleMedium: callout,
      titleSmall: subheadline,
      bodyLarge: body,
      bodyMedium: callout,
      bodySmall: footnote,
      labelLarge: caption1,
      labelSmall: caption2,
    ),
  );
} 