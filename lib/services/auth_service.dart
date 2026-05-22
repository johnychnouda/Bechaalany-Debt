import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../utils/platform_utils.dart';
import 'admin_service.dart';
import 'business_name_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Single init future; initialize() must be called exactly once per plugin docs.
  Future<void>? _initFuture;

  /// Set when [completeWebOAuthRedirectIfPending] fails (e.g. Apple misconfiguration).
  String? _pendingWebOAuthError;

  /// Consumes and clears a stored OAuth redirect error for the sign-in screen.
  String? takePendingWebOAuthError() {
    final message = _pendingWebOAuthError;
    _pendingWebOAuthError = null;
    return message;
  }

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Initialize Google Sign-In (platform-specific client IDs).
  /// Must be called exactly once; use ensureInitialized() to await safely.
  Future<void> initialize() async {
    const serverClientId =
        '908856160324-8ft1tgo1lv5jmp1dr4astcankuq54u4a.apps.googleusercontent.com';

    if (kIsWeb) {
      await _googleSignIn.initialize(
        clientId: serverClientId,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _googleSignIn.initialize(
        clientId:
            '908856160324-0n5oi3n60e2mj09nogg0998lj54sfajq.apps.googleusercontent.com',
        serverClientId: serverClientId,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _googleSignIn.initialize(
        clientId:
            '908856160324-rifpo3dibqilhhee82mfcchc9t8rd500.apps.googleusercontent.com',
        serverClientId: serverClientId,
      );
    }
  }

  /// Ensures Google Sign-In is initialized before use. Idempotent; safe to call from
  /// main() and from signInWithGoogle(). Prevents "No credential available" / unknownError
  /// when user taps sign-in before async init completes.
  Future<void> ensureInitialized() async {
    _initFuture ??= initialize();
    await _initFuture!;
  }

  /// Sign in with Google (mobile via google_sign_in, web via Firebase popup).
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (PlatformUtils.isBrowserContext) {
        return await _signInWithGoogleWeb();
      }

      await ensureInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('Google Sign-In is not supported on this device');
      }

      // Use authenticate() for both platforms (v7 API)
      // Credential Manager is disabled via AndroidManifest metadata
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        // Firebase may already have a session (iOS OAuth timing / re-sign-in).
        if (_auth.currentUser != null) {
          return null;
        }
        try {
          final recovered = await _googleSignIn.attemptLightweightAuthentication();
          if (recovered != null) {
            final auth = recovered.authentication;
            final credential = GoogleAuthProvider.credential(
              idToken: auth.idToken,
            );
            return await _auth.signInWithCredential(credential);
          }
        } catch (_) {}
        return null;
      }

      // Obtain the auth details from the request (idToken is enough for Firebase).
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Use only idToken for the credential. Do not call authorizeScopes() here:
      // that triggers a second consent screen which Google shows as "You're signing
      // back in" and confuses new users.
      final credential = GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      // This will create a new user if they don't exist, or sign in existing user
      final result = await _auth.signInWithCredential(credential);
      
      return result;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }

      throw Exception('Google Sign-In failed: ${e.toString()} (Code: ${e.code})');
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Apple (iOS native, or web via Firebase popup).
  Future<UserCredential?> signInWithApple() async {
    try {
      if (PlatformUtils.isBrowserContext) {
        if (!PlatformUtils.isAppleWebSignInAvailable) {
          throw Exception(
            'Apple Sign-In on web is not available on localhost. '
            'Use Google Sign-In here, or test at https://bechaalany-debt-app-e1bb0.web.app',
          );
        }
        return await _signInWithAppleWeb();
      }
      if (!PlatformUtils.isIOS) {
        throw Exception('Apple Sign-In is only available on iOS.');
      }
      return await _signInWithAppleIOS();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      if (PlatformUtils.isBrowserContext) {
        rethrow;
      }
      // Provide more user-friendly error messages (mobile / generic)
      if (e.toString().contains('1001') || e.toString().contains('canceled')) {
        throw Exception('Apple Sign-In was cancelled. Please try again.');
      } else if (e.toString().contains('not available')) {
        throw Exception('Apple Sign-In is not available. Please check your device settings.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection.');
      } else if (e.toString().contains('localhost')) {
        rethrow;
      } else {
        throw Exception('Apple Sign-In failed. Please try again or use Google Sign-In instead.');
      }
    }
  }

  /// Web Google Sign-In via Firebase Auth popup.
  Future<UserCredential?> _signInWithGoogleWeb() async {
    final provider = GoogleAuthProvider();

    try {
      return await _auth.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-cancelled') {
        return null;
      }
      rethrow;
    }
  }

  /// Completes Apple/Google OAuth after [signInWithRedirect] on web. Call once before runApp.
  Future<UserCredential?> completeWebOAuthRedirectIfPending() async {
    if (!PlatformUtils.isBrowserContext) return null;

    _pendingWebOAuthError = null;
    try {
      final result = await _auth.getRedirectResult();
      if (result.user != null) {
        return result;
      }

      // Flutter web sometimes sets currentUser without populating redirect result.
      if (_auth.currentUser != null) {
        return result;
      }

      // Wait briefly for auth state after handler redirect back to this origin.
      try {
        await _auth
            .authStateChanges()
            .where((user) => user != null)
            .first
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        // Auth state not ready yet.
      }
      return _auth.currentUser != null ? result : null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-cancelled') {
        return null;
      }
      _pendingWebOAuthError = _formatAuthError(e);
      return null;
    }
  }

  /// Web Apple Sign-In via Firebase popup (same session; no redirect round-trip).
  Future<UserCredential?> _signInWithAppleWeb() async {
    final provider = AppleAuthProvider()..addScope('email');

    try {
      return await _auth.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-cancelled') {
        return null;
      }
      throw FirebaseAuthException(
        code: e.code,
        message: _formatAuthError(e),
      );
    }
  }

  static String _formatAuthError(FirebaseAuthException e) {
    final detail = e.message?.trim();
    if (detail != null && detail.isNotEmpty) return detail;
    return 'Apple Sign-In failed (${e.code}). '
        'In Apple Developer → Services ID → Sign in with Apple → Web, set domain '
        'bechaalany-debt-app-e1bb0.firebaseapp.com and return URL '
        'https://bechaalany-debt-app-e1bb0.firebaseapp.com/__/auth/handler';
  }

  /// iOS-specific Apple Sign-In implementation
  Future<UserCredential?> _signInWithAppleIOS() async {
    // Check if Apple Sign-In is available
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw Exception('Apple Sign-In is not available on this device. Please check your device settings.');
    }

    // Request Apple ID credential with minimal scopes for better compatibility
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
      ],
    );

    // Check if user cancelled or if credential is invalid
    if (appleCredential.identityToken == null || appleCredential.identityToken!.isEmpty) {
      throw Exception('Apple Sign-In was cancelled or failed. Please try again.');
    }

    // Create Firebase credential
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    // Sign in to Firebase with Apple credential
    return await _auth.signInWithCredential(oauthCredential);
  }


  /// Sign out
  Future<void> signOut() async {
    try {
      // Clear admin cache before signing out
      try {
        final adminService = AdminService();
        adminService.clearCache();
      } catch (e) {
        // Ignore admin service errors
      }
      
      // Clear business name cache before signing out
      try {
        final businessNameService = BusinessNameService();
        businessNameService.clearCache();
      } catch (e) {
        // Ignore business name service errors
      }
      
      // Sign out from Firebase first
      await _auth.signOut();
      
      // Then sign out from Google
      await _googleSignIn.signOut();
      
      // Force a small delay to ensure auth state is updated
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      // Handle sign out error silently
    }
  }

  /// Force clear all authentication (for debugging)
  Future<void> forceSignOut() async {
    try {
      // Clear Firebase auth
      await _auth.signOut();
      
      // Clear Google Sign-In
      await _googleSignIn.signOut();
      
      // Clear any cached credentials
      await _googleSignIn.disconnect();
      
      // Force a longer delay to ensure everything is cleared
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      // Handle sign out error silently
    }
  }

  /// Get user display name
  String? get userDisplayName {
    final user = currentUser;
    if (user == null) return null;
    
    return user.displayName ?? user.email?.split('@').first ?? 'User';
  }

  /// Get user email
  String? get userEmail {
    return currentUser?.email;
  }

  /// Get user photo URL
  String? get userPhotoUrl {
    return currentUser?.photoURL;
  }

  /// Check if user is signed in with Google
  bool get isGoogleUser {
    final user = currentUser;
    if (user == null) return false;
    
    return user.providerData.any((provider) => provider.providerId == 'google.com');
  }

  /// Check if user is signed in with Apple
  bool get isAppleUser {
    final user = currentUser;
    if (user == null) return false;
    
    return user.providerData.any((provider) => provider.providerId == 'apple.com');
  }

  /// Get provider name for display
  String get providerName {
    if (isGoogleUser) return 'Google';
    if (isAppleUser) return 'Apple';
    return 'Unknown';
  }

  /// Returns true if the current user signed in with email/password (needs password for re-auth).
  bool get isEmailPasswordUser {
    final user = currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  /// Obtain a credential for re-authentication (e.g. before account deletion).
  /// For Google/Apple: runs the sign-in flow and returns the credential.
  /// For email/password: returns null — UI must ask for password and use
  /// EmailAuthProvider.credential(email, password).
  /// Throws if user cancels or flow fails.
  Future<AuthCredential?> getCredentialForReauth() async {
    if (isGoogleUser) return _getGoogleReauthCredential();
    if (isAppleUser) return _getAppleReauthCredential();
    return null;
  }

  Future<AuthCredential?> _getGoogleReauthCredential() async {
    if (PlatformUtils.isBrowserContext) {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Not signed in');
      }
      await user.reauthenticateWithPopup(GoogleAuthProvider());
      return null;
    }

    await ensureInitialized();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw Exception('Google Sign-In is not supported on this device');
    }
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      String? accessToken;
      try {
        final authorization = await googleUser.authorizationClient.authorizeScopes(['openid', 'email', 'profile']);
        accessToken = authorization.accessToken;
      } catch (e) {
        // idToken is sufficient for Firebase credential
      }
      return GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<AuthCredential?> _getAppleReauthCredential() async {
    if (PlatformUtils.isBrowserContext) {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Not signed in');
      }
      final provider = AppleAuthProvider()..addScope('email');
      await user.reauthenticateWithPopup(provider);
      // Reauth already completed via popup.
      return null;
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
    );
    if (appleCredential.identityToken == null ||
        appleCredential.identityToken!.isEmpty) {
      throw Exception('Apple Sign-In was cancelled or failed');
    }
    return OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
  }

  /// Track email verification completion
  Future<void> trackEmailVerificationCompletion(String email) async {
    try {
      // This method can be used to track analytics or perform other actions
      // when email verification is completed
    } catch (e) {
    }
  }

  /// Reload user data to get latest verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      // Handle error silently
    }
  }

}
