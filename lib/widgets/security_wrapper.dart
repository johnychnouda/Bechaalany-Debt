import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/security_service.dart';
import '../screens/biometric_auth_screen.dart';

class SecurityWrapper extends StatefulWidget {
  final Widget child;
  final bool isInitialLoad;

  const SecurityWrapper({
    Key? key,
    required this.child,
    this.isInitialLoad = false,
  }) : super(key: key);

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper> {
  final SecurityService _securityService = SecurityService();
  bool _isLoading = true;
  bool _needsAuthentication = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
  }

  Future<void> _checkSecurityStatus() async {
    await _securityService.initialize();
    
    final biometricAvailable = await _securityService.isBiometricAvailable();
    final needsAuth = await _securityService.needsAuthentication();
    final needsSetup = await _securityService.needsBiometricSetup();

    setState(() {
      _isLoading = false;
      _needsAuthentication = biometricAvailable && needsAuth;
      _isBiometricAvailable = biometricAvailable;
      _isBiometricEnabled = biometricAvailable;
    });

    // If biometric is not set up, show setup screen
    if (needsSetup) {
      _showBiometricSetupRequired();
    }
  }

  Future<void> _onAuthenticationSuccess() async {
    setState(() {
      _needsAuthentication = false;
    });
  }

  void _onBiometricFallback() {
    // No fallback available - user must use biometric authentication
    _showBiometricSetupRequired();
  }

  void _showBiometricSetupRequired() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Set Up Face ID'),
        content: const Text(
          'To secure your debt data, please set up Face ID or Touch ID in your device settings.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _securityService.openDeviceSettings();
            },
            child: const Text('Open Settings'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _onCancel();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _onCancel() {
    // User cancelled authentication - could exit app or show error
    // For now, we'll just show the app content (not recommended for production)
    setState(() {
      _needsAuthentication = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (!_needsAuthentication) {
      return widget.child;
    }

    // Show biometric authentication screen
    if (_isBiometricAvailable && _isBiometricEnabled) {
      return BiometricAuthScreen(
        onSuccess: _onAuthenticationSuccess,
        onFallback: _onBiometricFallback,
        onCancel: _onCancel,
      );
    } else {
      // No biometric available - show error message
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.lock_shield,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Biometric Authentication Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please set up Face ID or Touch ID in your device settings to use app security.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CupertinoButton(
                  onPressed: _onCancel,
                  child: const Text('Continue Without Security'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
