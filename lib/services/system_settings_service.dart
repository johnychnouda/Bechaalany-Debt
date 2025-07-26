import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class SystemSettingsService {
  static final SystemSettingsService _instance = SystemSettingsService._internal();
  factory SystemSettingsService() => _instance;
  SystemSettingsService._internal();

  // Privacy & Security Settings
  Future<void> openPrivacySettings() async {
    try {
      const url = 'App-Prefs:Privacy';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening privacy settings: $e');
    }
  }

  Future<void> openFaceIDSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=Face%20ID';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening Face ID settings: $e');
    }
  }

  Future<void> openLocationSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=LOCATION';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening location settings: $e');
    }
  }

  Future<void> openCameraSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=CAMERA';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening camera settings: $e');
    }
  }

  Future<void> openPhotoLibrarySettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=PHOTO_LIBRARY';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening photo library settings: $e');
    }
  }

  Future<void> openMicrophoneSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=MICROPHONE';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening microphone settings: $e');
    }
  }

  Future<void> openContactsSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=CONTACTS';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening contacts settings: $e');
    }
  }

  Future<void> openCalendarSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=CALENDAR';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening calendar settings: $e');
    }
  }

  Future<void> openHealthSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=HEALTH';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening health settings: $e');
    }
  }

  Future<void> openMotionSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=MOTION';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening motion settings: $e');
    }
  }

  Future<void> openBluetoothSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=BLUETOOTH';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening bluetooth settings: $e');
    }
  }

  Future<void> openLocalNetworkSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=LOCAL_NETWORK';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening local network settings: $e');
    }
  }

  Future<void> openNearbyInteractionSettings() async {
    try {
      const url = 'App-Prefs:Privacy&path=NEARBY_INTERACTION';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openPrivacySettings();
      }
    } catch (e) {
      print('Error opening nearby interaction settings: $e');
    }
  }

  // Notifications Settings
  Future<void> openNotificationSettings() async {
    try {
      const url = 'App-Prefs:NOTIFICATION';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening notification settings: $e');
    }
  }

  // Accessibility Settings
  Future<void> openAccessibilitySettings() async {
    try {
      const url = 'App-Prefs:ACCESSIBILITY';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening accessibility settings: $e');
    }
  }

  Future<void> openVoiceOverSettings() async {
    try {
      const url = 'App-Prefs:ACCESSIBILITY&path=VOICEOVER';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openAccessibilitySettings();
      }
    } catch (e) {
      print('Error opening VoiceOver settings: $e');
    }
  }

  Future<void> openReduceMotionSettings() async {
    try {
      const url = 'App-Prefs:ACCESSIBILITY&path=REDUCE_MOTION';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openAccessibilitySettings();
      }
    } catch (e) {
      print('Error opening reduce motion settings: $e');
    }
  }

  Future<void> openBoldTextSettings() async {
    try {
      const url = 'App-Prefs:ACCESSIBILITY&path=BOLD_TEXT';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openAccessibilitySettings();
      }
    } catch (e) {
      print('Error opening bold text settings: $e');
    }
  }

  // Storage & iCloud Settings
  Future<void> openStorageSettings() async {
    try {
      const url = 'App-Prefs:General&path=STORAGE_ICLOUD_USAGE';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening storage settings: $e');
    }
  }

  Future<void> openICloudSettings() async {
    try {
      const url = 'App-Prefs:ICLOUD';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening iCloud settings: $e');
    }
  }

  Future<void> openKeychainSettings() async {
    try {
      const url = 'App-Prefs:General&path=KEYCHAIN';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening keychain settings: $e');
    }
  }

  // Search & Siri Settings
  Future<void> openSiriSettings() async {
    try {
      const url = 'App-Prefs:SIRI';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening Siri settings: $e');
    }
  }

  Future<void> openSpotlightSettings() async {
    try {
      const url = 'App-Prefs:General&path=SPOTLIGHT';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening spotlight settings: $e');
    }
  }

  // App-Specific Settings
  Future<void> openBackgroundAppRefreshSettings() async {
    try {
      const url = 'App-Prefs:General&path=BACKGROUND_APP_REFRESH';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening background app refresh settings: $e');
    }
  }

  Future<void> openCellularDataSettings() async {
    try {
      const url = 'App-Prefs:General&path=CELLULAR_DATA';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening cellular data settings: $e');
    }
  }

  Future<void> openVPNSettings() async {
    try {
      const url = 'App-Prefs:General&path=VPN';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening VPN settings: $e');
    }
  }

  Future<void> openScreenTimeSettings() async {
    try {
      const url = 'App-Prefs:SCREEN_TIME';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening screen time settings: $e');
    }
  }

  Future<void> openFocusSettings() async {
    try {
      const url = 'App-Prefs:FOCUS';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening focus settings: $e');
    }
  }

  // Display & Brightness Settings
  Future<void> openDisplaySettings() async {
    try {
      const url = 'App-Prefs:DISPLAY';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening display settings: $e');
    }
  }

  Future<void> openDarkModeSettings() async {
    try {
      const url = 'App-Prefs:DISPLAY&path=APPEARANCE';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openDisplaySettings();
      }
    } catch (e) {
      print('Error opening dark mode settings: $e');
    }
  }

  Future<void> openAutoLockSettings() async {
    try {
      const url = 'App-Prefs:DISPLAY&path=AUTO_LOCK';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openDisplaySettings();
      }
    } catch (e) {
      print('Error opening auto lock settings: $e');
    }
  }

  // Sound & Haptics Settings
  Future<void> openSoundSettings() async {
    try {
      const url = 'App-Prefs:SOUNDS';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openGeneralSettings();
      }
    } catch (e) {
      print('Error opening sound settings: $e');
    }
  }

  Future<void> openHapticSettings() async {
    try {
      const url = 'App-Prefs:SOUNDS&path=HAPTIC_FEEDBACK';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openSoundSettings();
      }
    } catch (e) {
      print('Error opening haptic settings: $e');
    }
  }

  // General Settings
  Future<void> openGeneralSettings() async {
    try {
      const url = 'App-Prefs:General';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await openMainSettings();
      }
    } catch (e) {
      print('Error opening general settings: $e');
    }
  }

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

  // Permission Check Methods
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

  Future<bool> checkLocationPermissions() async {
    try {
      const platform = MethodChannel('location');
      final bool isGranted = await platform.invokeMethod('checkPermission');
      return isGranted;
    } catch (e) {
      print('Error checking location permissions: $e');
      return false;
    }
  }

  Future<bool> checkCameraPermissions() async {
    try {
      const platform = MethodChannel('camera');
      final bool isGranted = await platform.invokeMethod('checkPermission');
      return isGranted;
    } catch (e) {
      print('Error checking camera permissions: $e');
      return false;
    }
  }

  Future<bool> checkMicrophonePermissions() async {
    try {
      const platform = MethodChannel('microphone');
      final bool isGranted = await platform.invokeMethod('checkPermission');
      return isGranted;
    } catch (e) {
      print('Error checking microphone permissions: $e');
      return false;
    }
  }

  Future<bool> checkContactsPermissions() async {
    try {
      const platform = MethodChannel('contacts');
      final bool isGranted = await platform.invokeMethod('checkPermission');
      return isGranted;
    } catch (e) {
      print('Error checking contacts permissions: $e');
      return false;
    }
  }

  Future<bool> checkCalendarPermissions() async {
    try {
      const platform = MethodChannel('calendar');
      final bool isGranted = await platform.invokeMethod('checkPermission');
      return isGranted;
    } catch (e) {
      print('Error checking calendar permissions: $e');
      return false;
    }
  }
} 