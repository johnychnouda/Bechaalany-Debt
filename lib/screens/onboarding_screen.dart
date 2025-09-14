import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../utils/logo_utils.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AuthService _authService = AuthService();
  final UserStateService _userStateService = UserStateService();
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 375;
    final isLargeScreen = MediaQuery.of(context).size.width > 428;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF),
              const Color(0xFFF8F9FA),
              const Color(0xFFF2F2F7),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Design
                LogoUtils.buildLogo(
                  context: context,
                  width: isSmallScreen ? 120 : isLargeScreen ? 160 : 140,
                  height: isSmallScreen ? 120 : isLargeScreen ? 160 : 140,
                  placeholder: Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                    size: isSmallScreen ? 50 : isLargeScreen ? 70 : 60,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? AppTheme.spacing32 : AppTheme.spacing40),
                
                // Welcome Title
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome to ',
                        style: AppTheme.title1.copyWith(
                          color: Colors.black,
                          fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Bechaalany Connect',
                        style: AppTheme.title1.copyWith(
                          color: const Color(0xFFFF3B30),
                          fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacing16),
                
                // Description
                Text(
                  'To ensure the security of your financial data, we need to verify your email address before you can start using the app.',
                  style: AppTheme.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppTheme.spacing16),
                
                // Note about Google OAuth
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Text(
                          'Note: Google may show "signing back in" - this is normal for new users. Your account will be created automatically.',
                          style: AppTheme.caption1.copyWith(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? AppTheme.spacing48 : AppTheme.spacing56),
                
                // Security Features
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radius16),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Security Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.security,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacing16),
                      
                      Text(
                        'Why Verification?',
                        style: AppTheme.headline.copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppTheme.spacing12),
                      
                      // Security reasons
                      Column(
                        children: [
                          _buildSecurityReason(
                            icon: Icons.email_outlined,
                            title: 'Email Verification',
                            description: 'Verify your email address for account security',
                          ),
                          const SizedBox(height: AppTheme.spacing12),
                          _buildSecurityReason(
                            icon: Icons.lock_outline,
                            title: 'Protect Your Data',
                            description: 'Your financial information is encrypted and secure',
                          ),
                          const SizedBox(height: AppTheme.spacing12),
                          _buildSecurityReason(
                            icon: Icons.verified_user_outlined,
                            title: 'Secure Access',
                            description: 'Ensure only you can access your debt records',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? AppTheme.spacing40 : AppTheme.spacing48),
                
                // Status Message
                if (_statusMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: _statusMessage!.contains('Failed') || _statusMessage!.contains('Error')
                          ? AppColors.error.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(
                        color: _statusMessage!.contains('Failed') || _statusMessage!.contains('Error')
                            ? AppColors.error.withValues(alpha: 0.3)
                            : Colors.blue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusMessage!.contains('Failed') || _statusMessage!.contains('Error')
                              ? CupertinoIcons.exclamationmark_triangle
                              : Icons.info_outline,
                          color: _statusMessage!.contains('Failed') || _statusMessage!.contains('Error')
                              ? AppColors.error
                              : Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: AppTheme.callout.copyWith(
                              color: _statusMessage!.contains('Failed') || _statusMessage!.contains('Error')
                                  ? AppColors.error
                                  : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_statusMessage != null) SizedBox(height: AppTheme.spacing24),
                
                // Verification Button
                if (_isLoading || _isVerifying)
                  Column(
                    children: [
                      const CupertinoActivityIndicator(
                        color: AppColors.primary,
                        radius: 20,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      Text(
                        _isVerifying ? 'Verifying email...' : 'Preparing verification...',
                        style: AppTheme.callout.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      onPressed: _startEmailVerification,
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Verify Email Address',
                            style: AppTheme.headline.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                SizedBox(height: isSmallScreen ? AppTheme.spacing32 : AppTheme.spacing40),
                
                // Privacy Notice
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Text(
                          'We will send a verification email to your registered email address. Please check your inbox and click the verification link.',
                          style: AppTheme.caption1.copyWith(
                            color: Colors.blue[700],
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
      ),
    );
  }

  Widget _buildSecurityReason({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.callout.copyWith(
                  color: AppColors.dynamicTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTheme.caption1.copyWith(
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startEmailVerification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _statusMessage = 'No user found. Please sign in again.';
        });
        return;
      }

      // Check if email is already verified
      if (user.emailVerified) {
        setState(() {
          _statusMessage = 'Email is already verified!';
        });
        await _onVerificationComplete();
        return;
      }

      // Send email verification
      setState(() {
        _isVerifying = true;
        _statusMessage = 'Sending verification email...';
      });

      await user.sendEmailVerification();
      
      setState(() {
        _statusMessage = 'Verification email sent! Please check your inbox and click the verification link.';
      });

      // Start checking for verification
      _checkEmailVerification();
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to send verification email: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkEmailVerification() {
    // Check verification status every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final user = _authService.currentUser;
        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            timer.cancel();
            await _onVerificationComplete();
          }
        }
      } catch (e) {
        // Handle error silently
      }
    });
  }

  Future<void> _onVerificationComplete() async {
    try {
      // Mark user as verified
      await _userStateService.markUserVerified();
      await _userStateService.markOnboardingComplete();
      
      setState(() {
        _statusMessage = 'Email verified successfully!';
      });

      // Wait a moment to show success message
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Navigate to main screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Verification completed but there was an error: ${e.toString()}';
      });
    }
  }
}
