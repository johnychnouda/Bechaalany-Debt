import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'android_colors.dart';
import '../providers/app_state.dart';
import '../services/theme_service.dart';

class AndroidTheme {
  // Android 16 Material You Typography (Roboto font family)
  
  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
    fontFamily: 'Roboto',
  );
  
  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
    fontFamily: 'Roboto',
  );
  
  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.27,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    fontFamily: 'Roboto',
  );
  
  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    fontFamily: 'Roboto',
  );
  
  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    fontFamily: 'Roboto',
  );

  // Dynamic Typography Methods (for accessibility)
  static TextStyle getDynamicDisplayLarge(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 25,
      fontWeight: FontWeight.w400,
    ).copyWith(
      letterSpacing: -0.25,
      height: 1.12,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicDisplayMedium(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 20,
      fontWeight: FontWeight.w400,
    ).copyWith(
      letterSpacing: 0,
      height: 1.16,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicDisplaySmall(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 15,
      fontWeight: FontWeight.w400,
    ).copyWith(
      letterSpacing: 0,
      height: 1.22,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicHeadlineLarge(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 12,
      fontWeight: FontWeight.w400,
    ).copyWith(
      letterSpacing: 0,
      height: 1.25,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicHeadlineMedium(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 10,
      fontWeight: FontWeight.w400,
    ).copyWith(
      letterSpacing: 0,
      height: 1.29,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicHeadlineSmall(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 8,
      fontWeight: FontWeight.w400,
    ).copyWith(
      letterSpacing: 0,
      height: 1.33,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicTitleLarge(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 6,
      fontWeight: FontWeight.w400,
    ).copyWith(
      letterSpacing: 0,
      height: 1.27,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicTitleMedium(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 2,
      fontWeight: FontWeight.w500,
    ).copyWith(
      letterSpacing: 0.15,
      height: 1.50,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicTitleSmall(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize),
      fontWeight: FontWeight.w500,
    ).copyWith(
      letterSpacing: 0.1,
      height: 1.43,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicBodyLarge(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 2,
    ).copyWith(
      letterSpacing: 0.5,
      height: 1.50,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicBodyMedium(BuildContext context) {
    return ThemeService.getTextStyle(context).copyWith(
      letterSpacing: 0.25,
      height: 1.43,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicBodySmall(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) - 2,
    ).copyWith(
      letterSpacing: 0.4,
      height: 1.33,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicLabelLarge(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize),
      fontWeight: FontWeight.w500,
    ).copyWith(
      letterSpacing: 0.1,
      height: 1.43,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicLabelMedium(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) - 2,
      fontWeight: FontWeight.w500,
    ).copyWith(
      letterSpacing: 0.5,
      height: 1.33,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle getDynamicLabelSmall(BuildContext context) {
    return ThemeService.getTextStyle(
      context,
      fontSize: ThemeService.getTextSize(Provider.of<AppState>(context, listen: false).textSize) - 3,
      fontWeight: FontWeight.w500,
    ).copyWith(
      letterSpacing: 0.5,
      height: 1.45,
      fontFamily: 'Roboto',
    );
  }
  
  // Android 16 Material You Spacing (8dp grid system)
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
  static const double spacing96 = 96.0;
  
  // Android 16 Material You Border Radius (4dp grid system)
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  static const double radius32 = 32.0;
  
  // Android 16 Material You Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AndroidColors.primary,
      onPrimary: AndroidColors.onPrimary,
      primaryContainer: AndroidColors.primaryContainer,
      onPrimaryContainer: AndroidColors.onPrimaryContainer,
      secondary: AndroidColors.secondary,
      onSecondary: AndroidColors.onSecondary,
      secondaryContainer: AndroidColors.secondaryContainer,
      onSecondaryContainer: AndroidColors.onSecondaryContainer,
      tertiary: AndroidColors.tertiary,
      onTertiary: AndroidColors.onTertiary,
      tertiaryContainer: AndroidColors.tertiaryContainer,
      onTertiaryContainer: AndroidColors.onTertiaryContainer,
      surface: AndroidColors.surface,
      onSurface: AndroidColors.onSurface,
      surfaceVariant: AndroidColors.surfaceVariant,
      onSurfaceVariant: AndroidColors.onSurfaceVariant,
      surfaceContainerHighest: AndroidColors.surfaceContainerHighest,
      surfaceContainerHigh: AndroidColors.surfaceContainerHigh,
      surfaceContainer: AndroidColors.surfaceContainer,
      surfaceContainerLow: AndroidColors.surfaceContainerLow,
      surfaceContainerLowest: AndroidColors.surfaceContainerLowest,
      background: AndroidColors.background,
      onBackground: AndroidColors.onBackground,
      error: AndroidColors.error,
      onError: AndroidColors.onError,
      errorContainer: AndroidColors.errorContainer,
      onErrorContainer: AndroidColors.onErrorContainer,
      outline: AndroidColors.outline,
      outlineVariant: AndroidColors.outlineVariant,
      scrim: AndroidColors.scrim,
      inverseSurface: AndroidColors.inverseSurface,
      onInverseSurface: AndroidColors.onInverseSurface,
      inversePrimary: AndroidColors.inversePrimary,
      shadow: AndroidColors.shadow,
      surfaceTint: AndroidColors.surfaceTint,
    ),
    
    // Android 16 AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AndroidColors.surface,
      foregroundColor: AndroidColors.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: AndroidColors.onSurface,
        letterSpacing: 0,
        height: 1.27,
        fontFamily: 'Roboto',
      ),
      iconTheme: IconThemeData(
        color: AndroidColors.primary,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: AndroidColors.primary,
        size: 24,
      ),
    ),
    
    // Android 16 Card Theme
    cardTheme: CardThemeData(
      color: AndroidColors.surface,
      elevation: 1,
      shadowColor: AndroidColors.shadow.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing8),
    ),
    
    // Android 16 Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AndroidColors.primary,
        foregroundColor: AndroidColors.onPrimary,
        elevation: 1,
        shadowColor: AndroidColors.primary.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        textStyle: labelLarge,
        minimumSize: const Size(64, 40),
      ),
    ),
    
    // Android 16 Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AndroidColors.primary,
        side: const BorderSide(color: AndroidColors.outline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        textStyle: labelLarge,
        minimumSize: const Size(64, 40),
      ),
    ),
    
    // Android 16 Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AndroidColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
        textStyle: labelLarge,
        minimumSize: const Size(64, 40),
      ),
    ),
    
    // Android 16 Filled Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AndroidColors.primary,
        foregroundColor: AndroidColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        textStyle: labelLarge,
        minimumSize: const Size(64, 40),
      ),
    ),
    
    // Android 16 Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AndroidColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: AndroidColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: AndroidColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: AndroidColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: AndroidColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: AndroidColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
      hintStyle: bodyLarge.copyWith(color: AndroidColors.onSurfaceVariant),
      labelStyle: bodyLarge.copyWith(color: AndroidColors.onSurfaceVariant),
      helperStyle: bodySmall.copyWith(color: AndroidColors.onSurfaceVariant),
      errorStyle: bodySmall.copyWith(color: AndroidColors.error),
    ),
    
    // Android 16 Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AndroidColors.primary,
      foregroundColor: AndroidColors.onPrimary,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      highlightElevation: 12,
      shape: CircleBorder(),
    ),
    
    // Android 16 Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AndroidColors.surface,
      selectedItemColor: AndroidColors.primary,
      unselectedItemColor: AndroidColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 3,
    ),
    
    // Android 16 Divider Theme
    dividerTheme: const DividerThemeData(
      color: AndroidColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    
    // Android 16 Typography
    textTheme: const TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),
  );
  
  // Android 16 Material You Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD0BCFF),
      onPrimary: Color(0xFF381E72),
      primaryContainer: Color(0xFF4F378B),
      onPrimaryContainer: Color(0xFFEADDFF),
      secondary: Color(0xFFCCC2DC),
      onSecondary: Color(0xFF332D41),
      secondaryContainer: Color(0xFF4A4458),
      onSecondaryContainer: Color(0xFFE8DEF8),
      tertiary: Color(0xFFEFB8C8),
      onTertiary: Color(0xFF492532),
      tertiaryContainer: Color(0xFF633B48),
      onTertiaryContainer: Color(0xFFFFD8E4),
      surface: Color(0xFF141218),
      onSurface: Color(0xFFE6E0E9),
      surfaceVariant: Color(0xFF49454F),
      onSurfaceVariant: Color(0xFFCAC4D0),
      surfaceContainerHighest: Color(0xFF2B2930),
      surfaceContainerHigh: Color(0xFF211F26),
      surfaceContainer: Color(0xFF1D1B20),
      surfaceContainerLow: Color(0xFF191C1B),
      surfaceContainerLowest: Color(0xFF0F0D13),
      background: Color(0xFF141218),
      onBackground: Color(0xFFE6E0E9),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFF9DEDC),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE6E0E9),
      onInverseSurface: Color(0xFF313033),
      inversePrimary: Color(0xFF6750A4),
      shadow: Color(0xFF000000),
      surfaceTint: Color(0xFFD0BCFF),
    ),
    
    // Android 16 Dark AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF141218),
      foregroundColor: Color(0xFFE6E0E9),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: Color(0xFFE6E0E9),
        letterSpacing: 0,
        height: 1.27,
        fontFamily: 'Roboto',
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFD0BCFF),
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: Color(0xFFD0BCFF),
        size: 24,
      ),
    ),
    
    // Android 16 Dark Card Theme
    cardTheme: CardThemeData(
      color: const Color(0xFF1D1B20),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing8),
    ),
    
    // Android 16 Dark Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD0BCFF),
        foregroundColor: const Color(0xFF381E72),
        elevation: 1,
        shadowColor: const Color(0xFFD0BCFF).withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        textStyle: labelLarge,
        minimumSize: const Size(64, 40),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD0BCFF),
        side: const BorderSide(color: Color(0xFF938F99), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        textStyle: labelLarge,
        minimumSize: const Size(64, 40),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFD0BCFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
        textStyle: labelLarge,
        minimumSize: const Size(64, 40),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFD0BCFF),
        foregroundColor: const Color(0xFF381E72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        textStyle: labelLarge,
        minimumSize: const Size(64, 40),
      ),
    ),
    
    // Note: TonalButton not available in current Flutter version
    // Using FilledButton with secondary colors instead
    
    // Android 16 Dark Input Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1D1B20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: Color(0xFF938F99)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: Color(0xFF938F99)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: Color(0xFFD0BCFF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: Color(0xFFF2B8B5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius4),
        borderSide: const BorderSide(color: Color(0xFFF2B8B5), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
      hintStyle: bodyLarge.copyWith(color: const Color(0xFFCAC4D0)),
      labelStyle: bodyLarge.copyWith(color: const Color(0xFFCAC4D0)),
      helperStyle: bodySmall.copyWith(color: const Color(0xFFCAC4D0)),
      errorStyle: bodySmall.copyWith(color: const Color(0xFFF2B8B5)),
    ),
    
    // Android 16 Dark Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFD0BCFF),
      foregroundColor: Color(0xFF381E72),
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      highlightElevation: 12,
      shape: CircleBorder(),
    ),
    
    // Android 16 Dark Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF141218),
      selectedItemColor: Color(0xFFD0BCFF),
      unselectedItemColor: Color(0xFFCAC4D0),
      type: BottomNavigationBarType.fixed,
      elevation: 3,
    ),
    
    // Android 16 Dark Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFF49454F),
      thickness: 1,
      space: 1,
    ),
    
    // Android 16 Dark Typography
    textTheme: const TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),
  );
}
