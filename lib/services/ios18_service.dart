import 'package:flutter/services.dart';

class IOS18Service {
  static const MethodChannel _channel = MethodChannel('ios18_service');

  /// Initialize iOS 18.6+ services
  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
    } catch (e) {
      // Handle error silently - iOS 18.6+ features are optional
    }
  }

  /// Check if device supports iOS 18.6+ features
  static Future<bool> isIOS186Supported() async {
    try {
      final result = await _channel.invokeMethod('isIOS186Supported');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get device capabilities for iOS 18.6+ features
  static Future<Map<String, bool>> getDeviceCapabilities() async {
    try {
      final result = await _channel.invokeMethod('getDeviceCapabilities');
      if (result is Map) {
        return Map<String, bool>.from(result);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Enable Focus Mode integration
  static Future<void> enableFocusModeIntegration() async {
    try {
      await _channel.invokeMethod('enableFocusModeIntegration');
    } catch (e) {
      // Handle error silently
    }
  }

  /// Enable Dynamic Island integration
  static Future<void> enableDynamicIslandIntegration() async {
    try {
      await _channel.invokeMethod('enableDynamicIslandIntegration');
    } catch (e) {
      // Handle error silently
    }
  }

  /// Enable Live Activities
  static Future<void> enableLiveActivities() async {
    try {
      await _channel.invokeMethod('enableLiveActivities');
    } catch (e) {
      // Handle error silently
    }
  }

  /// Enable Smart Stack features
  static Future<void> enableSmartStack() async {
    try {
      await _channel.invokeMethod('enableSmartStack');
    } catch (e) {
      // Handle error silently
    }
  }

  /// Enable AI features
  static Future<void> enableAIFeatures() async {
    try {
      await _channel.invokeMethod('enableAIFeatures');
    } catch (e) {
      // Handle error silently
    }
  }

  /// Request notification permissions for iOS 18.6+
  static Future<bool> requestNotificationPermissions() async {
    try {
      final result = await _channel.invokeMethod('requestNotificationPermissions');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Configure notification interruption level
  static Future<void> configureInterruptionLevel(String level) async {
    try {
      await _channel.invokeMethod('configureInterruptionLevel', {'level': level});
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get current notification settings
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final result = await _channel.invokeMethod('getNotificationSettings');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {};
    } catch (e) {
      return {};
    }
  }
} 