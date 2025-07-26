import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ThemeService {
  static double getTextSize(String textSize) {
    switch (textSize) {
      case 'Small':
        return 12.0;
      case 'Medium':
        return 14.0;
      case 'Large':
        return 16.0;
      case 'Extra Large':
        return 18.0;
      default:
        return 14.0;
    }
  }
  
  static TextStyle getTextStyle(BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    final baseSize = fontSize ?? getTextSize(appState.textSize);
    final isBold = appState.boldTextEnabled;
    
    return TextStyle(
      fontSize: baseSize,
      fontWeight: fontWeight ?? (isBold ? FontWeight.w600 : FontWeight.normal),
      color: color,
    );
  }
  
  static TextStyle getTitleStyle(BuildContext context) {
    return getTextStyle(
      context,
      fontSize: getTextSize(Provider.of<AppState>(context, listen: false).textSize) + 2,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle getBodyStyle(BuildContext context) {
    return getTextStyle(context);
  }
  
  static TextStyle getCaptionStyle(BuildContext context) {
    return getTextStyle(
      context,
      fontSize: getTextSize(Provider.of<AppState>(context, listen: false).textSize) - 2,
    );
  }
} 