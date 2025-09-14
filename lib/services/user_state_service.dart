import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStateService {
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // All user state is now Firebase-based, no local storage needed

  /// Check if user is new (first time signing in) - Firebase-based only
  Future<bool> isNewUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return true;

      // Check if user has any data in Firestore (Firebase-based)
      final hasData = await _hasUserData(user.uid);
      return !hasData;
    } catch (e) {
      // If there's an error, assume new user for safety
      return true;
    }
  }

  /// Check if user has completed verification
  Future<bool> isUserVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check Firebase user email verification status
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      // If reload fails, user might have been deleted from Firebase
      // Return false to trigger sign out
      return false;
    }
  }

  /// Check if user has any data in Firestore
  Future<bool> _hasUserData(String userId) async {
    try {
      // Check multiple collections to see if user has any data
      final customersSnapshot = await _firestore
          .collection('customers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (customersSnapshot.docs.isNotEmpty) return true;

      final debtsSnapshot = await _firestore
          .collection('debts')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (debtsSnapshot.docs.isNotEmpty) return true;

      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return activitiesSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Mark user as having completed onboarding in Firebase
  Future<void> markOnboardingComplete() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'onboardingCompleted': true,
          'onboardingCompletedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Mark user as verified in Firebase (after email verification)
  Future<void> markUserVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Create a user document in Firestore to mark them as verified
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'emailVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Reset user state (for testing or logout) - Firebase-based
  Future<void> resetUserState() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update user document in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'lastSignOut': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get user onboarding status
  Future<Map<String, dynamic>> getUserStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'isNewUser': true,
          'isVerified': false,
          'hasEmail': false,
          'emailVerified': false,
          'userId': null,
          'needsOnboarding': true,
          'needsVerification': true,
        };
      }

      // Force check if user still exists in Firebase
      try {
        await user.reload();
      } catch (e) {
        // If reload fails, user was deleted from Firebase
        // Return status that will trigger sign out
        return {
          'isNewUser': true,
          'isVerified': false,
          'hasEmail': false,
          'emailVerified': false,
          'userId': null,
          'needsOnboarding': true,
          'needsVerification': true,
          'userDeleted': true, // Flag to indicate user was deleted
        };
      }

      final isNew = await isNewUser();
      final isVerified = await isUserVerified();
      
      return {
        'isNewUser': isNew,
        'isVerified': isVerified,
        'hasEmail': user.email != null,
        'emailVerified': user.emailVerified,
        'userId': user.uid,
        'needsOnboarding': isNew,
        'needsVerification': !isVerified,
      };
    } catch (e) {
      return {
        'isNewUser': true,
        'isVerified': false,
        'hasEmail': false,
        'emailVerified': false,
        'userId': null,
        'needsOnboarding': true,
        'needsVerification': true,
      };
    }
  }

  /// Check if user needs to complete onboarding
  Future<bool> needsOnboarding() async {
    return await isNewUser();
  }

  /// Check if user needs verification
  Future<bool> needsVerification() async {
    return !(await isUserVerified());
  }

  /// Get user's verification status with details
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'isVerified': false,
          'reason': 'No user signed in',
          'canVerify': false,
        };
      }

      // Check Firebase user verification status
      await user.reload();
      final isVerified = user.emailVerified;
      
      if (isVerified) {
        return {
          'isVerified': true,
          'reason': 'Email verified in Firebase',
          'canVerify': false,
        };
      } else {
        return {
          'isVerified': false,
          'reason': 'Email not verified',
          'canVerify': true,
        };
      }
    } catch (e) {
      return {
        'isVerified': false,
        'reason': 'Error checking verification status',
        'canVerify': true,
      };
    }
  }
}
