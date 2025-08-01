import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    // Text animations
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    _textSlideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start fade animation
    _fadeController.forward();
    
    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();
    
    // Start text animation after logo
    await Future.delayed(const Duration(milliseconds: 1000));
    _textController.forward();
    
    // Wait for animations to complete and navigate
    await Future.delayed(const Duration(milliseconds: 8500));
    if (mounted) {
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 375;
    final isLargeScreen = MediaQuery.of(context).size.width > 428;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Container(
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
                    // Elegant logo design
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Opacity(
                            opacity: _logoOpacityAnimation.value,
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/images/Logolightmode.svg',
                                width: isSmallScreen ? 140 : isLargeScreen ? 180 : 160,
                                height: isSmallScreen ? 140 : isLargeScreen ? 180 : 160,
                                placeholderBuilder: (context) => Container(
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
                        );
                      },
                    ),
                    
                    SizedBox(height: isSmallScreen ? AppTheme.spacing48 : AppTheme.spacing56),
                    
                    // Elegant text design
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: Opacity(
                            opacity: _textOpacityAnimation.value,
                            child: Column(
                              children: [
                                // App name with elegant styling
                                Text(
                                  'Bechaalany Connect',
                                  style: AppTheme.title1.copyWith(
                                    color: Colors.black,
                                    fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
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
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                SizedBox(height: AppTheme.spacing24),
                                
                                // Elegant loading indicator
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                                  'Version 1.0.0',
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
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

 