import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class EmailVerificationModal extends StatefulWidget {
  final VoidCallback? onVerified;
  final VoidCallback? onDismiss;

  const EmailVerificationModal({
    Key? key,
    this.onVerified,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<EmailVerificationModal> createState() => _EmailVerificationModalState();
}

class _EmailVerificationModalState extends State<EmailVerificationModal> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  /// Start checking for verification status every 2 seconds
  void _startVerificationCheck() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkVerificationStatus();
      }
    });
  }

  /// Check if email is verified
  Future<void> _checkVerificationStatus() async {
    try {
      final isVerified = await _authService.checkEmailVerification();
      if (isVerified && mounted) {
        // Email is verified, close modal
        widget.onVerified?.call();
        return;
      }
      
      // Continue checking every 2 seconds
      _startVerificationCheck();
    } catch (e) {
      // Continue checking even if there's an error
      _startVerificationCheck();
    }
  }

  /// Resend verification email
  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _statusMessage = '';
    });

    try {
      await _authService.sendEmailVerification();
      setState(() {
        _statusMessage = 'Verification email sent! Please check your inbox.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to send verification email. Please try again.';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  /// Dismiss modal (for cases where user wants to continue without verification)
  void _dismissModal() {
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mail,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicTextPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                'We\'ve sent a verification link to your email address. Please check your inbox and click the link to verify your account.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.dynamicTextSecondary(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // User's email
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _authService.currentUser?.email ?? 'your-email@example.com',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Status message
              if (_statusMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusMessage.contains('Failed') 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusMessage.contains('Failed') 
                            ? Icons.warning
                            : Icons.check_circle,
                        color: _statusMessage.contains('Failed') 
                            ? Colors.red
                            : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: _statusMessage.contains('Failed') 
                              ? Colors.red
                              : Colors.green,
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Resend button
              ElevatedButton(
                onPressed: _isResending ? null : _resendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 16),
              
              // Continue without verification (optional)
              TextButton(
                onPressed: _dismissModal,
                child: Text(
                  'Continue Later',
                  style: TextStyle(
                    color: AppColors.dynamicTextSecondary(context),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Auto-verification notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will automatically close once you verify your email',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
