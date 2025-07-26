import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class SystemSettingsService {
  static final SystemSettingsService _instance = SystemSettingsService._internal();
  factory SystemSettingsService() => _instance;
  SystemSettingsService._internal();

  /// Open iOS Privacy & Security Settings
  Future<void> openPrivacySettings() async {
    try {
      const url = 'App-Prefs:Privacy';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // Fallback to general settings
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening privacy settings: $e');
    }
  }

  /// Open iOS Notifications Settings
  Future<void> openNotificationSettings() async {
    try {
      const url = 'App-Prefs:NOTIFICATION';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // Fallback to general settings
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening notification settings: $e');
    }
  }

  /// Open iOS Accessibility Settings
  Future<void> openAccessibilitySettings() async {
    try {
      const url = 'App-Prefs:ACCESSIBILITY';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // Fallback to general settings
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening accessibility settings: $e');
    }
  }

  /// Open iOS Storage Settings
  Future<void> openStorageSettings() async {
    try {
      const url = 'App-Prefs:General&path=STORAGE_ICLOUD_USAGE';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // Fallback to general settings
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening storage settings: $e');
    }
  }

  /// Open iOS General Settings
  Future<void> openGeneralSettings() async {
    try {
      const url = 'App-Prefs:General';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // Final fallback to main settings
        await openMainSettings();
      }
    } catch (e) {
      print('Error opening general settings: $e');
    }
  }

  /// Open iOS Main Settings
  Future<void> openMainSettings() async {
    try {
      const url = 'App-Prefs:';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw Exception('Cannot open iOS Settings');
      }
    } catch (e) {
      print('Error opening main settings: $e');
    }
  }

  /// Check if Face ID/Touch ID is available
  Future<bool> isBiometricAvailable() async {
    try {
      const platform = MethodChannel('local_auth');
      final bool isAvailable = await platform.invokeMethod('isDeviceSupported');
      return isAvailable;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Check notification permissions
  Future<bool> checkNotificationPermissions() async {
    try {
      const platform = MethodChannel('flutter_local_notifications');
      final bool isGranted = await platform.invokeMethod('requestPermissions');
      return isGranted;
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }
} 