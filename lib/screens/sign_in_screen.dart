import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../utils/logo_utils.dart';
import 'main_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    _authService.authStateChanges.listen((user) {
      if (user != null && mounted) {
        // User is signed in, navigate to main screen
        _navigateToMainScreen();
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        // Success - navigation will be handled by auth state listener
      } else {
        setState(() {
          _errorMessage = 'Google sign-in was cancelled';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithApple();
      if (result != null) {
        // Success - navigation will be handled by auth state listener
      } else {
        setState(() {
          _errorMessage = 'Apple sign-in was cancelled';
        });
      }
    } catch (e) {
      setState(() {
        // Check if it's a cancellation error
        if (e.toString().contains('cancelled')) {
          _errorMessage = 'Apple sign-in was cancelled';
        } else if (e.toString().contains('not available')) {
          _errorMessage = 'Apple Sign-In is not available on this device';
        } else {
          _errorMessage = 'Apple sign-in failed: ${e.toString()}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToMainScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 375;
    final isLargeScreen = MediaQuery.of(context).size.width > 428;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main gradient background
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF000000),
                          const Color(0xFF1C1C1E),
                          const Color(0xFF2C2C2E),
                          const Color(0xFF1C1C1E),
                        ]
                      : [
                          const Color(0xFFFFFFFF),
                          const Color(0xFFF8FAFF),
                          const Color(0xFFF0F4FF),
                          const Color(0xFFE8F2FF),
                        ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Subtle overlay pattern
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      (isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF8FAFF))
                          .withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            // Additional subtle accent
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDarkMode ? const Color(0xFF2C2C2E) : AppColors.primary)
                          .withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom accent
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDarkMode ? const Color(0xFF1C1C1E) : AppColors.primaryLight)
                          .withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
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
                    color: isDarkMode ? Colors.white : AppColors.primary,
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
                        text: 'Bechaalany ',
                        style: AppTheme.title1.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Connect',
                        style: AppTheme.title1.copyWith(
                          color: isDarkMode ? AppColors.primaryLight : AppColors.primary,
                          fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacing16),
                
                // Subtitle with Elegant Styling
                Text(
                  'Sign in to manage your debt records',
                  style: AppTheme.body.copyWith(
                    color: isDarkMode 
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
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
                        'Signing you in...',
                        style: AppTheme.callout.copyWith(
                          color: isDarkMode 
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      // Google Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: CupertinoButton(
                          onPressed: _signInWithGoogle,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radius16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Logo
                              SvgPicture.asset(
                                'assets/images/google_logo.svg',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: AppTheme.spacing12),
                              Text(
                                'Continue with Google',
                                style: AppTheme.headline.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacing16),
                      
                      // Apple Sign In Button
                      if (Platform.isIOS)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: CupertinoButton(
                            onPressed: _signInWithApple,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radius16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Apple Logo
                                SvgPicture.asset(
                                  'assets/images/apple_logo.svg',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: AppTheme.spacing12),
                                Text(
                                  'Continue with Apple',
                                  style: AppTheme.headline.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}
