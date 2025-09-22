import 'package:flutter/material.dart';

class AppColors {
  // iOS-style Primary Colors
  static const Color primary = Color(0xFF007AFF);
  static const Color primaryDark = Color(0xFF0056CC);
  static const Color primaryLight = Color(0xFF4DA3FF);
  
  // iOS-style Secondary Colors
  static const Color secondary = Color(0xFF34C759);
  static const Color secondaryDark = Color(0xFF28A745);
  static const Color secondaryLight = Color(0xFF5CDB95);
  
  // iOS-style Accent Colors
  static const Color accent = Color(0xFFFF9500);
  static const Color accentDark = Color(0xFFE6850E);
  static const Color accentLight = Color(0xFFFFB340);
  
  // iOS-style Background Colors
  static const Color background = Color(0xFFF2F2F7);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // iOS-style Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);
  static const Color textQuaternary = Color(0xFFF2F2F7);
  static const Color textLight = Color(0xFF94A3B8);
  
  // iOS-style Status Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);
  
  // iOS-style Debt Status Colors
  static const Color debtPaid = Color(0xFF34C759);
  static const Color debtPending = Color(0xFFFF9500);
  
  // iOS-style Border and Divider Colors
  static const Color border = Color(0xFFC6C6C8);
  static const Color divider = Color(0xFFF2F2F7);
  static const Color separator = Color(0xFFC6C6C8);
  
  // iOS-style System Colors
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemPink = Color(0xFFFF2D92);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemYellow = Color(0xFFFFCC02);
  
  // iOS-style Gray Colors
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);
  
  // iOS-style Dynamic Colors (for dark mode support)
  static Color dynamicPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF0A84FF) 
        : primary;
  }
  
  static Color dynamicBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF000000) 
        : background;
  }
  
  static Color dynamicSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF1C1C1E) 
        : surface;
  }
  
  static Color dynamicTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFFFFFFFF) 
        : textPrimary;
  }
  
  static Color dynamicTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF8E8E93) 
        : textSecondary;
  }
  
  static Color dynamicBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF38383A) 
        : border;
  }
  
  static Color dynamicWarning(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFFFF9500) 
        : warning;
  }
  
  static Color dynamicSuccess(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF34C759) 
        : success;
  }
  
  static Color dynamicError(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFFFF453A) 
        : error;
  }
  
  static Color dynamicDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF38383A) 
        : divider;
  }
  
  static Color dynamicSeparator(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF38383A) 
        : separator;
  }
  
  // iOS-style Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF0056CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF28A745)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFE6850E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF2F2F7), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // iOS-style Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> floatingShadow = [
    BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];
} 