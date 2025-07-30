import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoUtils {
  /// Returns the appropriate logo asset path based on the current theme
  static String getLogoAsset(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode 
        ? 'assets/images/Logodarkmode.svg' 
        : 'assets/images/Logolightmode.svg';
  }

  /// Creates a themed logo widget with consistent styling
  static Widget buildLogo({
    required BuildContext context,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
  }) {
    return SvgPicture.asset(
      getLogoAsset(context),
      width: width,
      height: height,
      fit: fit,
      placeholderBuilder: placeholder != null 
          ? (context) => placeholder 
          : null,
    );
  }

  /// Creates a logo widget with a container background
  static Widget buildLogoWithBackground({
    required BuildContext context,
    double? width,
    double? height,
    Color? backgroundColor,
    double borderRadius = 12,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: buildLogo(
        context: context,
        width: width,
        height: height,
      ),
    );
  }
} 