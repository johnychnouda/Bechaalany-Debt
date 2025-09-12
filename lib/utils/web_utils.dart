import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebUtils {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;
  
  /// Check if running on mobile platform
  static bool get isMobile => !kIsWeb;
  
  /// Get responsive layout for web vs mobile
  static Widget buildResponsiveLayout({
    required Widget mobile,
    required Widget web,
    Widget? tablet,
  }) {
    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Use tablet layout for larger screens on web
          if (constraints.maxWidth > 768 && tablet != null) {
            return tablet;
          }
          return web;
        },
      );
    }
    return mobile;
  }
  
  /// Get responsive padding for web vs mobile
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (kIsWeb) {
      final width = MediaQuery.of(context).size.width;
      if (width > 1200) {
        return const EdgeInsets.symmetric(horizontal: 200, vertical: 24);
      } else if (width > 768) {
        return const EdgeInsets.symmetric(horizontal: 100, vertical: 24);
      } else {
        return const EdgeInsets.all(24);
      }
    }
    return const EdgeInsets.all(16);
  }
  
  /// Get responsive container width for web
  static double getResponsiveContainerWidth(BuildContext context) {
    if (kIsWeb) {
      final width = MediaQuery.of(context).size.width;
      if (width > 1200) {
        return 800; // Max width for large screens
      } else if (width > 768) {
        return width * 0.8; // 80% of screen width
      }
    }
    return double.infinity; // Full width on mobile
  }
  
  /// Get responsive font size for web
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (kIsWeb) {
      final width = MediaQuery.of(context).size.width;
      if (width > 1200) {
        return baseSize * 1.1; // Slightly larger on large screens
      }
    }
    return baseSize;
  }
  
  /// Check if should show mobile-style navigation on web
  static bool shouldShowMobileNavigation(BuildContext context) {
    if (kIsWeb) {
      final width = MediaQuery.of(context).size.width;
      return width < 768; // Show mobile nav on smaller web screens
    }
    return true; // Always show mobile nav on actual mobile
  }
  
  /// Get web-optimized scroll physics
  static ScrollPhysics getWebScrollPhysics() {
    if (kIsWeb) {
      return const BouncingScrollPhysics(); // iOS-style scrolling on web
    }
    return const BouncingScrollPhysics();
  }
  
  /// Get responsive card elevation for web
  static List<BoxShadow> getResponsiveCardShadow(BuildContext context) {
    if (kIsWeb) {
      final width = MediaQuery.of(context).size.width;
      if (width > 768) {
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
      }
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
