import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Email and Password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Create account with Email and Password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Send email verification after account creation
      await sendEmailVerification();
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send verification email. Please try again.');
    }
  }

  /// Check if email is verified
  bool get isEmailVerified {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Reload user data to get latest verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to refresh user data. Please try again.');
    }
  }

  /// Get verification status
  Future<bool> checkEmailVerification() async {
    try {
      await reloadUser();
      return isEmailVerified;
    } catch (e) {
      return false;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Provide more specific error messages for password reset
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email address. Please check your email or create a new account.');
        case 'invalid-email':
          throw Exception('Please enter a valid email address.');
        case 'too-many-requests':
          throw Exception('Too many password reset attempts. Please wait a few minutes before trying again.');
        case 'user-disabled':
          throw Exception('This account has been disabled. Please contact support.');
        default:
          throw _handleAuthException(e);
      }
    } catch (e) {
      throw Exception('Failed to send password reset email. Please check your internet connection and try again.');
    }
  }

  /// Sign in with Phone Number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
    int? timeout,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: Duration(seconds: timeout ?? 60),
        forceResendingToken: forceResendingToken,
      );
    } catch (e) {
      throw Exception('Phone verification failed. Please try again.');
    }
  }

  /// Sign in with Phone Auth Credential
  Future<UserCredential?> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Handle Firebase Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please create an account first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please check your email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check your phone number.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'credential-already-in-use':
        return 'This phone number is already associated with another account.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'No account found with this email address. Please create an account first.';
      case 'user-mismatch':
        return 'No account found with this email address. Please create an account first.';
      default:
        // Check if it's a credential-related error
        if (e.message?.contains('credential') == true || 
            e.message?.contains('auth') == true) {
          return 'No account found with this email address. Please create an account first.';
        }
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      throw Exception('Sign out failed. Please try again.');
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

  /// Get user phone number
  String? get userPhoneNumber {
    return currentUser?.phoneNumber;
  }

  /// Get user photo URL
  String? get userPhotoUrl {
    return currentUser?.photoURL;
  }

  /// Get provider name for display
  String get providerName {
    final user = currentUser;
    if (user == null) return 'Unknown';
    
    // Check provider data to determine authentication method
    if (user.providerData.any((provider) => provider.providerId == 'password')) {
      return 'Email/Password';
    } else if (user.providerData.any((provider) => provider.providerId == 'phone')) {
      return 'Phone';
    }
    
    return 'Unknown';
  }

  /// Check if user is signed in with email
  bool get isEmailUser {
    final user = currentUser;
    if (user == null) return false;
    
    return user.providerData.any((provider) => provider.providerId == 'password');
  }

  /// Check if user is signed in with phone
  bool get isPhoneUser {
    final user = currentUser;
    if (user == null) return false;
    
    return user.providerData.any((provider) => provider.providerId == 'phone');
  }
}