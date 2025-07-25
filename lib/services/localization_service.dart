import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _localeKey = 'selected_locale';
  
  Locale _currentLocale = const Locale('en', 'US');
  bool _isRTL = false;
  
  Locale get currentLocale => _currentLocale;
  bool get isRTL => _isRTL;
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ar', 'SA'),
  ];
  
  // Language names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'العربية',
  };
  
  // Initialize the service
  Future<void> initialize() async {
    await _loadSavedLanguage();
  }
  
  // Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? 'en';
      await setLanguage(savedLanguage);
    } catch (e) {
      print('Error loading saved language: $e');
      // Default to English
      await setLanguage('en');
    }
  }
  
  // Set language and update app
  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      // Update locale
      _currentLocale = Locale(languageCode);
      
      // Update RTL setting
      _isRTL = languageCode == 'ar';
      
      // Set system UI overlay style for RTL
      if (_isRTL) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        );
      } else {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        );
      }
      
      notifyListeners();
    } catch (e) {
      print('Error setting language: $e');
    }
  }
  
  // Get current language code
  String get currentLanguageCode => _currentLocale.languageCode;
  
  // Get current language name
  String get currentLanguageName => languageNames[_currentLocale.languageCode] ?? 'English';
  
  // Check if current language is RTL
  bool get isCurrentLanguageRTL => _isRTL;
  
  // Get text direction
  TextDirection get textDirection => _isRTL ? TextDirection.rtl : TextDirection.ltr;
  
  // Get alignment for RTL support
  Alignment get alignment => _isRTL ? Alignment.centerRight : Alignment.centerLeft;
  
  // Get cross alignment for RTL support
  CrossAxisAlignment get crossAxisAlignment => _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  
  // Get main alignment for RTL support
  MainAxisAlignment get mainAxisAlignment => _isRTL ? MainAxisAlignment.end : MainAxisAlignment.start;
  
  // Get edge insets for RTL support
  EdgeInsets get edgeInsets => _isRTL 
    ? const EdgeInsets.only(right: 16, left: 0)
    : const EdgeInsets.only(left: 16, right: 0);
  
  // Get symmetric edge insets for RTL support
  EdgeInsets get symmetricEdgeInsets => const EdgeInsets.symmetric(horizontal: 16);
  
  // Get padding for RTL support
  EdgeInsets get padding => _isRTL 
    ? const EdgeInsets.only(right: 8, left: 0)
    : const EdgeInsets.only(left: 8, right: 0);
  
  // Get margin for RTL support
  EdgeInsets get margin => _isRTL 
    ? const EdgeInsets.only(right: 4, left: 0)
    : const EdgeInsets.only(left: 4, right: 0);
} 