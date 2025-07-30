import 'package:flutter/services.dart';

class SystemSettingsService {
  static const MethodChannel _channel = MethodChannel('system_settings');

  /// Open iOS Settings app to the app's settings page
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException catch (_) {
      // Handle error silently
    }
  }

  /// Check if notifications are enabled at system level
  static Future<bool> areNotificationsEnabled() async {
    try {
      final bool enabled = await _channel.invokeMethod('areNotificationsEnabled');
      return enabled;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool available = await _channel.invokeMethod('isBiometricAvailable');
      return available;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }

  /// Get system text size setting
  static Future<String> getSystemTextSize() async {
    try {
      final String textSize = await _channel.invokeMethod('getSystemTextSize');
      return textSize;
    } on PlatformException catch (_) {
      // Handle error silently
      return 'medium';
    }
  }

  /// Check if system bold text is enabled
  static Future<bool> isSystemBoldTextEnabled() async {
    try {
      final bool enabled = await _channel.invokeMethod('isSystemBoldTextEnabled');
      return enabled;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }

  /// Check if system reduce motion is enabled
  static Future<bool> isSystemReduceMotionEnabled() async {
    try {
      final bool enabled = await _channel.invokeMethod('isSystemReduceMotionEnabled');
      return enabled;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }

  /// Get app storage usage
  static Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      final Map<String, dynamic> usage = await _channel.invokeMethod('getStorageUsage');
      return usage;
    } on PlatformException catch (_) {
      // Handle error silently
      return {'size': 0, 'items': 0};
    }
  }

  /// Clear app cache
  static Future<void> clearCache() async {
    try {
      await _channel.invokeMethod('clearCache');
    } on PlatformException catch (_) {
      // Handle error silently
    }
  }

  /// Check camera permission status
  static Future<bool> hasCameraPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('hasCameraPermission');
      return hasPermission;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }

  /// Check photo library permission status
  static Future<bool> hasPhotoLibraryPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('hasPhotoLibraryPermission');
      return hasPermission;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }

  /// Check location permission status
  static Future<bool> hasLocationPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('hasLocationPermission');
      return hasPermission;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestCameraPermission');
      return granted;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }

  /// Request photo library permission
  static Future<bool> requestPhotoLibraryPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestPhotoLibraryPermission');
      return granted;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestLocationPermission');
      return granted;
    } on PlatformException catch (_) {
      // Handle error silently
      return false;
    }
  }
} 