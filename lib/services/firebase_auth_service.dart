import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Anonymous authentication removed - now using Email/Password and Phone sign-in

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {

      return null;
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {

      return null;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {

      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {

      rethrow;
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      // In Firebase Auth 6.0.1, updateEmail is deprecated
      // We need to use sendEmailVerification(beforeUpdatingEmail:) instead
      // For now, we'll throw an error indicating this needs to be implemented
      throw UnimplementedError('updateEmail is deprecated in Firebase Auth 6.0.1. Use sendEmailVerification(beforeUpdatingEmail:) instead.');
    } catch (e) {

      rethrow;
    }
  }

  /// Re-authenticate the current user (required before delete and other sensitive operations).
  Future<void> reauthenticateWithCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.reauthenticateWithCredential(credential);
  }

  // Delete account (call reauthenticateWithCredential first if you get requires-recent-login)
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {

      rethrow;
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Stream of user changes
  Stream<User?> get userChanges => _auth.userChanges();
  
  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> profile) async {
    try {
      await _auth.currentUser?.updateDisplayName(profile['displayName']);
      if (profile.containsKey('photoURL')) {
        await _auth.currentUser?.updatePhotoURL(profile['photoURL']);
      }
    } catch (e) {

      rethrow;
    }
  }
  
  // Get user settings
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};
      
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'creationTime': user.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      };
    } catch (e) {

      return {};
    }
  }
  
  // Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('displayName')) {
        await _auth.currentUser?.updateDisplayName(settings['displayName']);
      }
      if (settings.containsKey('photoURL')) {
        await _auth.currentUser?.updatePhotoURL(settings['photoURL']);
      }
    } catch (e) {

      rethrow;
    }
  }
  
  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      // This would typically come from Firestore or SharedPreferences
      // For now, return basic user info
      final user = _auth.currentUser;
      if (user == null) return {};
      
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
      };
    } catch (e) {

      return {};
    }
  }
  
  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      // This would typically save to Firestore or SharedPreferences
      // For now, just update basic profile info
      if (preferences.containsKey('displayName')) {
        await _auth.currentUser?.updateDisplayName(preferences['displayName']);
      }
    } catch (e) {

      rethrow;
    }
  }

  // Get auth error message
  String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
