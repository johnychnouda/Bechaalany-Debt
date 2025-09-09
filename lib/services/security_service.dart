import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  // Security settings keys
  static const String _securityEnabledKey = 'security_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastUnlockKey = 'last_unlock_time';
  static const String _autoLockMinutesKey = 'auto_lock_minutes';

  // Auto-lock timeout (default 5 minutes)
  int _autoLockMinutes = 5;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  /// Initialize security service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if biometric authentication is available
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (isAvailable && isDeviceSupported) {
        // Get available biometric types
        final biometrics = await _localAuth.getAvailableBiometrics();
        print('Available biometrics: $biometrics');
      }

      // Load security settings
      await _loadSecuritySettings();
      
      _isInitialized = true;
    } catch (e) {
      print('Security service initialization error: $e');
    }
  }

  /// Load security settings from SharedPreferences
  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoLockMinutes = prefs.getInt(_autoLockMinutesKey) ?? 5;
  }

  /// Check if security is enabled
  Future<bool> isSecurityEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_securityEnabledKey) ?? false;
  }

  /// Enable/disable security
  Future<void> setSecurityEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_securityEnabledKey, enabled);
    
    if (!enabled) {
      // Clear biometric settings when disabling security
      await prefs.setBool(_biometricEnabledKey, false);
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }


  /// Set auto-lock timeout
  Future<void> setAutoLockMinutes(int minutes) async {
    _autoLockMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoLockMinutesKey, minutes);
  }

  /// Get auto-lock timeout
  int get autoLockMinutes => _autoLockMinutes;

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!await isBiometricAvailable()) {
        return false;
      }

      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return false;
      }

      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Bechaalany Connect',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (result) {
        _isAuthenticated = true;
        await _updateLastUnlockTime();
      }

      return result;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }


  /// Check if app should be locked (auto-lock)
  Future<bool> shouldLockApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUnlock = prefs.getInt(_lastUnlockKey);
      
      if (lastUnlock == null) {
        return true; // Never unlocked, should lock
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceUnlock = now - lastUnlock;
      final lockTimeoutMs = _autoLockMinutes * 60 * 1000;

      return timeSinceUnlock > lockTimeoutMs;
    } catch (e) {
      return true; // Error, should lock for security
    }
  }

  /// Update last unlock time
  Future<void> _updateLastUnlockTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUnlockKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Lock the app
  void lockApp() {
    _isAuthenticated = false;
  }

  /// Check if user needs to authenticate
  Future<bool> needsAuthentication() async {
    if (!_isAuthenticated) {
      return true;
    }

    return await shouldLockApp();
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Get biometric type display name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Touch ID';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.weak:
        return 'Weak Biometric';
      case BiometricType.strong:
        return 'Strong Biometric';
    }
  }

  /// Get platform-specific biometric name
  String getPlatformBiometricName() {
    if (Platform.isIOS) {
      return 'Face ID / Touch ID';
    } else if (Platform.isAndroid) {
      return 'Fingerprint / Face';
    }
    return 'Biometric';
  }
}
