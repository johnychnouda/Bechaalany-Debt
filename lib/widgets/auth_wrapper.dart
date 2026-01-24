import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/sign_in_screen.dart';
import '../screens/main_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/contact_owner_screen.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';
import '../services/subscription_service.dart';
import '../services/admin_service.dart';
import '../models/subscription.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  final UserStateService _userStateService = UserStateService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AdminService _adminService = AdminService();

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
    // Reduced splash duration to 1 second for faster app startup
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Ensure user document exists, get user status, and check subscription access.
  /// Used to decide: MainScreen (has access or admin) vs ContactOwnerScreen (revoked/expired).
  Future<Map<String, dynamic>> _ensureUserDocumentAndGetStatus() async {
    try {
      await _userStateService.initializeUserSubscription();
      final userStatus = await _userStateService.getUserStatus();
      final userDeleted = userStatus['userDeleted'] == true;
      if (userDeleted) {
        return {...userStatus, 'hasAccess': false, 'isAdmin': false, 'accessDeniedReason': null};
      }
      final hasAccess = await _subscriptionService.hasActiveAccess();
      final isAdmin = await _adminService.isAdmin();
      
      // Determine the reason for access denial if user doesn't have access
      AccessDeniedReason? accessDeniedReason;
      if (!hasAccess && !isAdmin) {
        final subscription = await _subscriptionService.getCurrentUserSubscription();
        if (subscription != null) {
          if (subscription.status == SubscriptionStatus.cancelled) {
            accessDeniedReason = AccessDeniedReason.subscriptionCancelled;
          } else if (subscription.status == SubscriptionStatus.expired) {
            accessDeniedReason = AccessDeniedReason.subscriptionExpired;
          } else if (subscription.status == SubscriptionStatus.active && 
                     subscription.subscriptionEndDate != null &&
                     DateTime.now().isAfter(subscription.subscriptionEndDate!)) {
            accessDeniedReason = AccessDeniedReason.subscriptionExpired;
          } else if (subscription.status == SubscriptionStatus.trial &&
                     subscription.trialEndDate != null &&
                     DateTime.now().isAfter(subscription.trialEndDate!)) {
            accessDeniedReason = AccessDeniedReason.trialExpired;
          } else {
            // Default to trial expired if we can't determine
            accessDeniedReason = AccessDeniedReason.trialExpired;
          }
        } else {
          // No subscription data, default to trial expired
          accessDeniedReason = AccessDeniedReason.trialExpired;
        }
      }
      
      return {
        ...userStatus, 
        'hasAccess': hasAccess, 
        'isAdmin': isAdmin,
        'accessDeniedReason': accessDeniedReason,
      };
    } catch (e) {
      try {
        await _userStateService.initializeUserSubscription();
      } catch (_) {}
      return {
        'isNewUser': false,
        'isVerified': false,
        'hasEmail': false,
        'emailVerified': false,
        'userId': null,
        'needsOnboarding': false,
        'needsVerification': false,
        'hasAccess': true,
        'isAdmin': false,
        'accessDeniedReason': null,
      };
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
            future: _ensureUserDocumentAndGetStatus(),
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
              final hasAccess = userStatus['hasAccess'] ?? false;
              final isAdmin = userStatus['isAdmin'] ?? false;
              final accessDeniedReason = userStatus['accessDeniedReason'] as AccessDeniedReason?;

              if (userDeleted) {
                _authService.signOut();
                return const SignInScreen();
              }

              // Admins always have access. Others need active subscription (trial or paid).
              if (isAdmin || hasAccess) {
                return const MainScreen();
              }
              // Revoked or expired: block app features, show contact owner screen with appropriate reason
              return ContactOwnerScreen(
                reason: accessDeniedReason ?? AccessDeniedReason.trialExpired,
              );
            },
          );
        }
        
        // If user is not signed in, show sign-in screen
        return const SignInScreen();
      },
    );
  }
}
