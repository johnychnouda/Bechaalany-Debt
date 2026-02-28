import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/sign_in_screen.dart';
import '../screens/main_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/contact_owner_screen.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';
import '../services/access_service.dart';
import '../services/admin_service.dart';
import '../services/business_name_service.dart';
import '../services/data_service.dart';
import '../models/access.dart';
import '../screens/required_setup_screen.dart';

/// Caches the access-check future in initState to prevent FutureBuilder from
/// recreating it on every rebuild. Without this, parent rebuilds (e.g. from
/// AppState.notifyListeners) would restart the future repeatedly, causing
/// the app to appear unresponsive—especially on iPad.
class _SignedInAccessChecker extends StatefulWidget {
  final AuthService authService;
  final Future<Map<String, dynamic>> Function() ensureUserDocumentAndGetStatus;

  const _SignedInAccessChecker({
    super.key,
    required this.authService,
    required this.ensureUserDocumentAndGetStatus,
  });

  @override
  State<_SignedInAccessChecker> createState() => _SignedInAccessCheckerState();
}

class _SignedInAccessCheckerState extends State<_SignedInAccessChecker> {
  late Future<Map<String, dynamic>> _accessFuture;
  bool _userDeletedRetryScheduled = false;

  @override
  void initState() {
    super.initState();
    _accessFuture = widget.ensureUserDocumentAndGetStatus();
  }

  /// Retry access check once when userDeleted is reported. Right after sign-in,
  /// user.reload() can fail transiently and be reported as user-not-found.
  void _retryAccessCheckIfUserDeleted() {
    if (_userDeletedRetryScheduled) return;
    _userDeletedRetryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () async {
        if (!mounted) return;
        final status = await widget.ensureUserDocumentAndGetStatus();
        if (!mounted) return;
        setState(() {
          _accessFuture = Future.value(status);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _accessFuture,
      builder: (context, userStatusSnapshot) {
        if (userStatusSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (userStatusSnapshot.hasError) {
          return const ContactOwnerScreen(
            reason: AccessDeniedReason.trialExpired,
          );
        }

        final userStatus = userStatusSnapshot.data ?? {};
        final userDeleted = userStatus['userDeleted'] ?? false;
        final hasAccess = userStatus['hasAccess'] ?? false;
        final isAdmin = userStatus['isAdmin'] ?? false;
        final needsSetup = userStatus['needsSetup'] == true;
        final isNewUser = userStatus['isNewUser'] == true;
        final accessDeniedReason = userStatus['accessDeniedReason'] as AccessDeniedReason?;

        // Only treat as deleted and sign out after confirming with a retry.
        // Right after sign-in (e.g. returning from Google/Apple OAuth), user.reload()
        // can fail transiently and be reported as user-not-found, which would incorrectly
        // kick the user back to the sign-in screen.
        if (userDeleted) {
          if (!_userDeletedRetryScheduled) {
            _retryAccessCheckIfUserDeleted();
            return const SplashScreen();
          }
          widget.authService.signOut();
          return const SignInScreen();
        }

        // Show "Before you start" when setup is needed: either user has access (or is admin)
        // or is a new user (so they see setup first even if access check is still settling).
        if (needsSetup && (hasAccess || isAdmin || isNewUser)) {
          return RequiredSetupScreen(
            onComplete: () {
              setState(() {
                _accessFuture = widget.ensureUserDocumentAndGetStatus();
              });
            },
          );
        }

        // Admins or users with active access: go to main app
        if (isAdmin || hasAccess) {
          return const MainScreen();
        }

        // If the user does not have access (including expired trial),
        // show the ContactOwnerScreen with the appropriate reason.
        final reason = accessDeniedReason ?? AccessDeniedReason.trialExpired;
        return ContactOwnerScreen(reason: reason);
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  final UserStateService _userStateService = UserStateService();
  final AccessService _accessService = AccessService();
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
          // Do not sign out on reload failure. Reload can fail due to network
          // or timing (e.g. right after returning from Google OAuth). Signing out
          // here caused new users to be kicked back to the sign-in screen after
          // tapping "Continue" on the Google consent page.
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

  /// Ensure user document exists, get user status, and check access.
  /// Used to decide: MainScreen (has access or admin) vs ContactOwnerScreen (revoked/expired).
  Future<Map<String, dynamic>> _ensureUserDocumentAndGetStatus() async {
    try {
      await _userStateService.initializeUserAccess();
      final userStatus = await _userStateService.getUserStatus();
      final userDeleted = userStatus['userDeleted'] == true;
      if (userDeleted) {
        return {...userStatus, 'hasAccess': false, 'isAdmin': false, 'accessDeniedReason': null};
      }
      final hasAccess = await _accessService.hasActiveAccess();
      final isAdmin = await _adminService.isAdmin();

      // Always check if required setup (shop name + exchange rate) is complete,
      // so new users see "Before you start" even when access check is still settling.
      final hasBusinessName = await BusinessNameService().hasBusinessName();
      final currencySettings = await DataService().getCurrencySettings();
      final hasExchangeRate = currencySettings?.exchangeRate != null && currencySettings!.exchangeRate! > 0;
      final needsSetup = !hasBusinessName || !hasExchangeRate;
      
      // Determine the reason for access denial if user doesn't have access
      AccessDeniedReason? accessDeniedReason;
      if (!hasAccess && !isAdmin) {
        final access = await _accessService.getCurrentUserAccess();
        if (access != null) {
          if (access.status == AccessStatus.cancelled) {
            accessDeniedReason = AccessDeniedReason.accessRevoked;
          } else if (access.status == AccessStatus.expired) {
            accessDeniedReason = AccessDeniedReason.accessExpired;
          } else if (access.status == AccessStatus.active &&
                     access.accessEndDate != null &&
                     DateTime.now().isAfter(access.accessEndDate!)) {
            accessDeniedReason = AccessDeniedReason.accessExpired;
          } else if (access.status == AccessStatus.trial &&
                     access.trialEndDate != null &&
                     DateTime.now().isAfter(access.trialEndDate!)) {
            accessDeniedReason = AccessDeniedReason.trialExpired;
          } else {
            accessDeniedReason = AccessDeniedReason.trialExpired;
          }
        } else {
          accessDeniedReason = AccessDeniedReason.trialExpired;
        }
      }
      
      return {
        ...userStatus, 
        'hasAccess': hasAccess, 
        'isAdmin': isAdmin,
        'needsSetup': needsSetup,
        'accessDeniedReason': accessDeniedReason,
      };
    } catch (e) {
      try {
        await _userStateService.initializeUserAccess();
      } catch (_) {}
      // Fail closed: on error, deny access so revoked/expired users are never let through
      return {
        'isNewUser': false,
        'isVerified': false,
        'hasEmail': false,
        'emailVerified': false,
        'userId': null,
        'needsOnboarding': false,
        'needsVerification': false,
        'hasAccess': false,
        'isAdmin': false,
        'needsSetup': false,
        'accessDeniedReason': AccessDeniedReason.trialExpired,
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
        
        // If user is signed in, check their state.
        // CRITICAL: Use a dedicated widget that caches the future in initState.
        // Passing future: _ensureUserDocumentAndGetStatus() inline would recreate
        // the future on every parent rebuild (e.g. from AppState.notifyListeners),
        // causing infinite re-fetches and an unresponsive app—especially on iPad.
        if (snapshot.hasData && snapshot.data != null) {
          return _SignedInAccessChecker(
            key: ValueKey(snapshot.data!.uid),
            authService: _authService,
            ensureUserDocumentAndGetStatus: _ensureUserDocumentAndGetStatus,
          );
        }
        
        // If user is not signed in, show sign-in screen
        return const SignInScreen();
      },
    );
  }
}
