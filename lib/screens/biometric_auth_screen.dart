import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';
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
      backgroundColor: AppColors.dynamicBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Biometric Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  _biometricType.contains('Face') 
                      ? CupertinoIcons.person_circle
                      : CupertinoIcons.lock_shield,
                  color: AppColors.primary,
                  size: 50,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Authenticate with $_biometricType',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Use your $_biometricType to access Bechaalany Connect',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: AppColors.systemRed,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 48),
              
              // Authenticate Button
              if (_isLoading)
                const CupertinoActivityIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: CupertinoButton(
                    onPressed: _authenticate,
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _biometricType.contains('Face') 
                              ? CupertinoIcons.person_circle
                              : CupertinoIcons.lock_shield,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Authenticate with $_biometricType',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Fallback to PIN
              if (widget.onFallback != null)
                TextButton(
                  onPressed: widget.onFallback,
                  child: const Text(
                    'Use PIN instead',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Cancel Button
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
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
