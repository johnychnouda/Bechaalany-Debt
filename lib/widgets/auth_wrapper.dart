import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    // Show splash screen for minimum duration
    _showSplashForMinimumDuration();
  }

  Future<void> _showSplashForMinimumDuration() async {
    // Show splash screen for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
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
        if (_isLoading) {
          return const SplashScreen();
        }
        
        // Handle connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        // Handle errors
        if (snapshot.hasError) {
          // If there's an error, show sign-in screen
          return const SignInScreen();
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
