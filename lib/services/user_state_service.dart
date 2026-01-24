import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_service.dart';

class UserStateService {
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();

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

  /// Check if user has any data in Firestore (uses user-specific subcollections)
  Future<bool> _hasUserData(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      final customersSnapshot = await userRef.collection('customers').limit(1).get();
      if (customersSnapshot.docs.isNotEmpty) return true;

      final debtsSnapshot = await userRef.collection('debts').limit(1).get();
      if (debtsSnapshot.docs.isNotEmpty) return true;

      final activitiesSnapshot = await userRef.collection('activities').limit(1).get();
      return activitiesSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Mark user as having completed onboarding in Firebase
  /// Skips for admin users (admins don't need onboarding tracking)
  Future<void> markOnboardingComplete() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Check if user is admin - admins don't need onboarding tracking
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final isAdmin = userDoc.data()?['isAdmin'] == true;
        
        if (isAdmin) {
          // Admins don't need onboarding fields
          return;
        }
        
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
        // Check if user document exists
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        // If user doesn't exist, initialize trial
        if (!userDoc.exists || userDoc.data()?['subscriptionStatus'] == null) {
          await _subscriptionService.initializeTrial(user.uid);
        }
        
        // Create a user document in Firestore to mark them as verified
        // Preserve isAdmin field if it exists
        final existingData = userDoc.exists ? userDoc.data() : null;
        final isAdmin = existingData?['isAdmin'] == true;
        
        if (isAdmin) {
          // For admins, only set isAdmin and email
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'isAdmin': true,
          }, SetOptions(merge: true));
          
          // Remove all other fields
          try {
            await _firestore.collection('users').doc(user.uid).update({
              'emailVerified': FieldValue.delete(),
              'verifiedAt': FieldValue.delete(),
              'lastSignIn': FieldValue.delete(),
            });
          } catch (e) {
            // Ignore if fields don't exist
          }
        } else {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'emailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
            'lastSignIn': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Initialize subscription for new user (called on first sign-in)
  /// Always ensures user document exists in Firestore with basic info
  Future<void> initializeUserSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // User not authenticated, cannot create document
        return;
      }

      // Ensure user is reloaded to get latest info
      try {
        await user.reload();
      } catch (e) {
        // If reload fails, continue with current user data
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.exists ? userDoc.data() : null;
      final isAdmin = userData?['isAdmin'] == true;
      
      // If user is admin, skip trial initialization and clean up all fields except isAdmin and email
      if (isAdmin) {
        // For admins, only set isAdmin and email (no other fields)
        final adminData = {
          'email': user.email,
          'isAdmin': true,
        };
        
        await _firestore.collection('users').doc(user.uid).set(
          adminData,
          SetOptions(merge: true),
        );
        
        // Remove all other fields using update (FieldValue.delete() works in update)
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'displayName': FieldValue.delete(),
            'lastUpdated': FieldValue.delete(),
            'subscriptionStatus': FieldValue.delete(),
            'subscriptionType': FieldValue.delete(),
            'subscriptionStartDate': FieldValue.delete(),
            'subscriptionEndDate': FieldValue.delete(),
            'trialStartDate': FieldValue.delete(),
            'trialEndDate': FieldValue.delete(),
            'createdAt': FieldValue.delete(),
            'lastSignIn': FieldValue.delete(),
            'verifiedAt': FieldValue.delete(),
            'emailVerified': FieldValue.delete(),
            'onboardingCompleted': FieldValue.delete(),
            'onboardingCompletedAt': FieldValue.delete(),
          });
        } catch (e) {
          // If update fails (e.g., fields don't exist), that's fine
        }
        
        return; // Skip rest of initialization for admins
      }
      
      // If user document doesn't exist or doesn't have subscription data, initialize trial
      if (!userDoc.exists || userData?['subscriptionStatus'] == null) {
        // This will create the document with all required fields
        await _subscriptionService.initializeTrial(user.uid);
      } else {
        // Even if document exists, ensure it has basic user info (email, displayName)
        // This ensures admin dashboard can always see user information
        final data = userDoc.data();
        final currentEmail = user.email;
        final currentDisplayName = user.displayName;
        
        final needsUpdate = data?['email'] == null || 
                           data?['email'] != currentEmail ||
                           (currentDisplayName != null && data?['displayName'] != currentDisplayName);
        
        // Don't update admin users - they should only have isAdmin and email
        if (data?['isAdmin'] == true) {
          // For admins, ensure only isAdmin and email exist
          final adminData = {
            if (currentEmail != null) 'email': currentEmail,
            'isAdmin': true,
          };
          
          await _firestore.collection('users').doc(user.uid).set(
            adminData,
            SetOptions(merge: true),
          );
          
          // Remove all other fields
          try {
            await _firestore.collection('users').doc(user.uid).update({
              'displayName': FieldValue.delete(),
              'lastSignIn': FieldValue.delete(),
              'lastUpdated': FieldValue.delete(),
            });
          } catch (e) {
            // Ignore if fields don't exist
          }
          return; // Skip rest for admins
        }
        
        if (needsUpdate) {
          try {
            await _firestore.collection('users').doc(user.uid).set({
              if (currentEmail != null) 'email': currentEmail,
              if (currentDisplayName != null) 'displayName': currentDisplayName,
              'lastSignIn': FieldValue.serverTimestamp(),
              // Preserve isAdmin field if it exists
              if (data?['isAdmin'] != null) 'isAdmin': data!['isAdmin'],
            }, SetOptions(merge: true));
          } catch (e) {
            // If update fails, try to at least ensure document exists
            // This is a fallback to ensure user appears in admin dashboard
            try {
              // Only set subscriptionStatus if user is not admin
              final updateData = {
                'email': currentEmail ?? 'No email',
                'displayName': currentDisplayName ?? 'No name',
                'lastSignIn': FieldValue.serverTimestamp(),
                // Preserve isAdmin field if it exists
                if (data?['isAdmin'] != null) 'isAdmin': data!['isAdmin'],
              };
              
              // Only add subscriptionStatus for non-admin users
              if (data?['isAdmin'] != true) {
                updateData['subscriptionStatus'] = data?['subscriptionStatus'] ?? 'trial';
              }
              
              await _firestore.collection('users').doc(user.uid).set(
                updateData,
                SetOptions(merge: true),
              );
            } catch (fallbackError) {
              // Swallow error - we want the app to continue
            }
          }
        }
      }
    } catch (e) {
      // Last resort: try to create a minimal user document
      try {
        final user = _auth.currentUser;
        if (user != null) {
          // Check if document exists to preserve isAdmin
          final existingDoc = await _firestore.collection('users').doc(user.uid).get();
          final existingData = existingDoc.exists ? existingDoc.data() : null;
          final isAdmin = existingData?['isAdmin'] == true;
          
          if (isAdmin) {
            // For admins, only set isAdmin and email
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email ?? 'No email',
              'isAdmin': true,
            }, SetOptions(merge: true));
            
            // Remove all other fields
            try {
              await _firestore.collection('users').doc(user.uid).update({
                'displayName': FieldValue.delete(),
                'createdAt': FieldValue.delete(),
                'lastUpdated': FieldValue.delete(),
              });
            } catch (e) {
              // Ignore if fields don't exist
            }
          } else {
            final minimalData = {
              'email': user.email ?? 'No email',
              'displayName': user.displayName ?? 'No name',
              'subscriptionStatus': 'trial',
              'createdAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
            };
            
            await _firestore.collection('users').doc(user.uid).set(
              minimalData,
              SetOptions(merge: true),
            );
          }
        }
      } catch (finalError) {
        // Swallow - minimal user doc creation failed
      }
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
