import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Initialize Google Sign-In
  Future<void> initialize() async {
    await _googleSignIn.initialize(
      clientId: '908856160324-rifpo3dibqilhhee82mfcchc9t8rd500.apps.googleusercontent.com',
    );
  }

  /// Sign in with Google (Native iOS)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out any existing Google session to ensure fresh authentication
      await _googleSignIn.signOut();
      
      // Trigger the native iOS authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: null, // Not available in new API
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      // This will create a new user if they don't exist, or sign in existing user
      final result = await _auth.signInWithCredential(credential);
      
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // iOS implementation using native package
      return await _signInWithAppleIOS();
    } catch (e) {
      // Provide more user-friendly error messages
      if (e.toString().contains('1001') || e.toString().contains('canceled')) {
        throw Exception('Apple Sign-In was cancelled. Please try again.');
      } else if (e.toString().contains('not available')) {
        throw Exception('Apple Sign-In is not available. Please check your device settings.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection.');
      } else {
        throw Exception('Apple Sign-In failed. Please try again or use Google Sign-In instead.');
      }
    }
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
