import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io' show Platform;
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/logo_utils.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        // Success — AuthWrapper will run access check and show MainScreen or ContactOwnerScreen
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.googleSignInCancelled;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.googleSignInFailed(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithApple();
      if (result != null) {
        // Success — AuthWrapper will run access check and show MainScreen or ContactOwnerScreen
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.appleSignInCancelled;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Provide user-friendly error messages
          final l10n = AppLocalizations.of(context)!;
          if (e.toString().contains('cancelled')) {
            _errorMessage = l10n.appleSignInCancelledTryAgain;
          } else if (e.toString().contains('not available')) {
            _errorMessage = l10n.appleSignInNotAvailable;
          } else if (e.toString().contains('network')) {
            _errorMessage = l10n.networkError;
          } else {
            _errorMessage = l10n.appleSignInFailed;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                
                // App Title with Elegant Styling
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context)!.signInTitleBechaalany,
                        style: AppTheme.title1.copyWith(
                          color: Colors.black,
                          fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: AppLocalizations.of(context)!.signInTitleConnect,
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
                
                // Subtitle with Elegant Styling (1 line, scales to fit)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Platform.isIOS
                          ? AppLocalizations.of(context)!.signInSubtitle
                          : AppLocalizations.of(context)!.signInSubtitleGoogleOnly,
                      style: AppTheme.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: isSmallScreen ? 15 : 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? AppTheme.spacing48 : AppTheme.spacing56),
                
                // Error Message with Elegant Styling
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTheme.callout.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_errorMessage != null) SizedBox(height: AppTheme.spacing24),
                
                // Sign In Buttons with Elegant Styling
                if (_isLoading)
                  Column(
                    children: [
                      const CupertinoActivityIndicator(
                        color: AppColors.primary,
                        radius: 20,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      Text(
                        AppLocalizations.of(context)!.signingIn,
                        style: AppTheme.callout.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      // Google Sign In Button - iOS 18.6 Native Style
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                        child: CupertinoButton(
                          onPressed: _signInWithGoogle,
                          padding: EdgeInsets.zero,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Logo
                              SvgPicture.asset(
                                'assets/images/google_logo.svg',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)!.continueWithGoogle,
                                style: AppTheme.headline.copyWith(
                                  color: const Color(0xFF1C1C1E),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacing16),
                      
                      // Apple Sign In Button - iOS only
                      if (Platform.isIOS)
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                          child: CupertinoButton(
                            onPressed: _signInWithApple,
                            padding: EdgeInsets.zero,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Apple Logo
                                SvgPicture.asset(
                                  'assets/images/apple_logo.svg',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)!.continueWithApple,
                                  style: AppTheme.headline.copyWith(
                                    color: const Color(0xFF1C1C1E),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                
                SizedBox(height: isSmallScreen ? AppTheme.spacing40 : AppTheme.spacing48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

