import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../utils/logo_utils.dart';
import 'main_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _appVersion = '1.1.1'; // Default fallback

  @override
  void initState() {
    super.initState();
    
    // Load app version
    _loadAppVersion();
    
    // Simplified animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start simple animation
    _startAnimation();
  }

  Future<void> _loadAppVersion() async {
    try {
      // Load asynchronously to avoid blocking main thread
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      // Keep default version if loading fails
    }
  }

  void _startAnimation() async {
    // Simple fade in
    _fadeController.forward();
    
    // Reduced delay - only wait for animation to complete (1s) + minimal buffer (500ms)
    // Total: 1.5s instead of 4s for faster app startup
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200), // Faster transition
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 375;
    final isLargeScreen = MediaQuery.of(context).size.width > 428;

    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(
        builder: (context) => Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  AppColors.primary.withValues(alpha: 0.05),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Elegant logo design - simplified to single AnimatedBuilder
                    Transform.scale(
                      scale: _fadeAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Center(
                          child: LogoUtils.buildLogo(
                            context: context,
                            width: isSmallScreen ? 140 : isLargeScreen ? 180 : 160,
                            height: isSmallScreen ? 140 : isLargeScreen ? 180 : 160,
                            placeholder: Container(
                              width: isSmallScreen ? 140 : isLargeScreen ? 180 : 160,
                              height: isSmallScreen ? 140 : isLargeScreen ? 180 : 160,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppTheme.radius20),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: isSmallScreen ? 50 : isLargeScreen ? 70 : 60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? AppTheme.spacing48 : AppTheme.spacing56),
                    
                    // Elegant text design - simplified to single AnimatedBuilder
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          // App name with elegant styling - split colors
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Bechaalany ',
                                  style: AppTheme.title1.copyWith(
                                    color: Colors.black,
                                    fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Connect',
                                  style: AppTheme.title1.copyWith(
                                    color: Colors.red,
                                    fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: AppTheme.spacing12),
                          
                          // Tagline with elegant styling
                          Text(
                            'Smart debt management',
                            style: AppTheme.body.copyWith(
                              color: Colors.grey[600],
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: AppTheme.spacing16),
                          
                          // Enhanced loading text
                          Text(
                            'Preparing your financial dashboard...',
                            style: AppTheme.body.copyWith(
                              color: AppColors.primary.withValues(alpha: 0.7),
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: AppTheme.spacing24),
                          
                          // Loading indicator
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: AppTheme.spacing32),
                          
                          // Developer information
                          Text(
                            'Developed By Johny Chnouda',
                            style: AppTheme.body.copyWith(
                              color: Colors.grey[500],
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: AppTheme.spacing8),
                          
                          // App version
                          Text(
                            'Version $_appVersion',
                            style: AppTheme.body.copyWith(
                              color: Colors.grey[400],
                              fontSize: isSmallScreen ? 11 : 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
    ),
    );
  }
}

 