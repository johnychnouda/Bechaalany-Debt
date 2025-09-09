import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/security_service.dart';

class BiometricAuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onFallback;
  final VoidCallback? onCancel;

  const BiometricAuthScreen({
    Key? key,
    this.onSuccess,
    this.onFallback,
    this.onCancel,
  }) : super(key: key);

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final SecurityService _securityService = SecurityService();
  bool _isLoading = false;
  String _errorMessage = '';
  String _biometricType = '';

  @override
  void initState() {
    super.initState();
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    await _securityService.initialize();
    final biometrics = await _securityService.getAvailableBiometrics();
    
    if (biometrics.isNotEmpty) {
      setState(() {
        _biometricType = _securityService.getBiometricTypeName(biometrics.first);
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final success = await _securityService.authenticateWithBiometrics();
      
      if (success) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      } else {
        setState(() {
          _errorMessage = 'Authentication failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Native iOS 18+ style biometric icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _biometricType.contains('Face') 
                      ? CupertinoIcons.person_circle_fill
                      : CupertinoIcons.lock_shield_fill,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title - Native iOS 18+ style
              Text(
                'Use Face ID to unlock',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Bechaalany Connect',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Error Message - Native iOS 18+ style
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 48),
              
              // Authenticate Button - Native iOS 18+ style
              if (_isLoading)
                const CupertinoActivityIndicator(
                  color: Colors.white,
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: CupertinoButton(
                    onPressed: _authenticate,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _biometricType.contains('Face') 
                              ? CupertinoIcons.person_circle_fill
                              : CupertinoIcons.lock_shield_fill,
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Use Face ID',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Fallback to Settings
              if (widget.onFallback != null)
                TextButton(
                  onPressed: widget.onFallback,
                  child: Text(
                    'Set up Face ID in Settings',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Cancel Button
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
