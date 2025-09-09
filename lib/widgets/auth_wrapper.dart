import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/sign_in_screen.dart';
import '../screens/main_screen.dart';
import '../screens/splash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasShownSplash = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Clear any cached authentication state to ensure clean start
    _clearCachedAuthState();
    
    // Show splash screen for minimum duration
    _showSplashForMinimumDuration();
  }

  Future<void> _clearCachedAuthState() async {
    try {
      // Force refresh the authentication state
      await FirebaseAuth.instance.authStateChanges().first;
    } catch (e) {
      // Handle any errors silently
    }
  }

  Future<void> _showSplashForMinimumDuration() async {
    // Show splash screen for at least 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash screen while loading or during minimum duration
        if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        // If user is signed in, show main app
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }
        
        // If user is not signed in, show sign-in screen
        return const SignInScreen();
      },
    );
  }
}
