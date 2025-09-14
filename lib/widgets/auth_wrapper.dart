import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/sign_in_screen.dart';
import '../screens/main_screen.dart';
import '../screens/splash_screen.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  final UserStateService _userStateService = UserStateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Show splash screen for minimum duration
    _showSplashForMinimumDuration();
    // Handle any pending email verification links
    _handlePendingEmailVerification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handle verification status
  Future<void> _handlePendingEmailVerification() async {
    try {
      // Check if there's a pending verification
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Force reload user data to check if user still exists in Firebase
          await user.reload();
          
          // If email was verified, track the completion
          if (user.emailVerified) {
            await _authService.trackEmailVerificationCompletion(user.email ?? '');
          }
        } catch (e) {
          // If reload fails, user might have been deleted from Firebase
          // Sign out the user to clear the cached state
          await _authService.signOut();
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, check for verification status
      _handlePendingEmailVerification();
    }
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

        // Show splash screen while loading
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
        
        // If user is signed in, check their state
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _userStateService.getUserStatus(),
            builder: (context, userStatusSnapshot) {
              if (userStatusSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              
              if (userStatusSnapshot.hasError) {
                // If there's an error checking user state, show main screen
                return const MainScreen();
              }
              
              final userStatus = userStatusSnapshot.data ?? {};
              final userDeleted = userStatus['userDeleted'] ?? false;
              
              // If user was deleted from Firebase, sign them out
              if (userDeleted) {
                _authService.signOut();
                return const SignInScreen();
              }
              
              // User is signed in and ready to use the app (skip onboarding/verification)
              return const MainScreen();
            },
          );
        }
        
        // If user is not signed in, show sign-in screen
        return const SignInScreen();
      },
    );
  }
}
