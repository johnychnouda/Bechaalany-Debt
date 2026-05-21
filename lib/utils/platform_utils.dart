import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';

/// Cross-platform helpers (mobile + web). Avoids `dart:io` [Platform].
class PlatformUtils {
  PlatformUtils._();

  static bool get isWeb => kIsWeb;

  /// Running in a browser (Flutter web, or http(s) host if [kIsWeb] is false in release).
  static bool get isBrowserContext {
    if (kIsWeb) return true;
    final scheme = Uri.base.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  static bool get isIOS =>
      !isBrowserContext && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      !isBrowserContext && defaultTargetPlatform == TargetPlatform.android;

  /// True when the page is served from localhost (Flutter web dev server).
  static bool get isLocalhostWeb {
    if (!isBrowserContext) return false;
    final host = Uri.base.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1';
  }

  /// Apple web Sign-In only works on HTTPS domains registered in Apple Developer
  /// (e.g. firebaseapp.com / web.app), not on localhost.
  static bool get isAppleWebSignInAvailable =>
      isBrowserContext && !isLocalhostWeb;

  /// Apple Sign-In on iOS (native) and web when the host supports it.
  static bool get showAppleSignIn => isIOS || isAppleWebSignInAvailable;

  /// Subtitle on sign-in when Apple + Google are both offered.
  static bool get signInSubtitleMentionsApple => showAppleSignIn;

  static String get systemLocaleCode {
    try {
      final code = PlatformDispatcher.instance.locale.languageCode.trim();
      return code.isEmpty ? 'en' : code;
    } catch (_) {
      return 'en';
    }
  }
}
