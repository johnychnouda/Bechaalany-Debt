import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // First, check if Google Sign-In is available
      // Try to get current user first (this tests if the plugin is working)
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      
      // Check if user is already signed in
      if (currentUser != null) {
        await _googleSignIn.signOut();
      }
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final result = await _auth.signInWithCredential(credential);
      
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Only available on iOS
      if (!Platform.isIOS) {
        throw Exception('Apple Sign-In is only available on iOS');
      }

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with Apple credential
      return await _auth.signInWithCredential(oauthCredential);
    } catch (e) {
      return null;
    }
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
}
