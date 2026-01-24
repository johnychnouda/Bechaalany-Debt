import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Default trial period: 7 days
  static const int defaultTrialPeriodDays = 7;

  /// Get current user's subscription
  /// Returns null for admin users (admins don't have subscriptions)
  Future<Subscription?> getCurrentUserSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      // Check if user is admin - admins don't have subscriptions
      final data = doc.data();
      if (data?['isAdmin'] == true) {
        return null; // Admins don't need subscriptions
      }
      
      if (!doc.exists) {
        // User doesn't have subscription data yet, initialize trial
        return await initializeTrial(user.uid);
      }

      if (data == null || data['subscriptionStatus'] == null) {
        // No subscription data, initialize trial
        return await initializeTrial(user.uid);
      }

      return Subscription.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Stream of current user's subscription (real-time updates)
  /// Returns null for admin users (admins don't have subscriptions)
  Stream<Subscription?> getCurrentUserSubscriptionStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      // Check if user is admin - admins don't have subscriptions
      final data = doc.data();
      if (data?['isAdmin'] == true) {
        return null; // Admins don't need subscriptions
      }
      
      if (!doc.exists) {
        // Initialize trial if document doesn't exist (only for non-admins)
        initializeTrial(user.uid);
        return null;
      }

      if (data == null || data['subscriptionStatus'] == null) {
        // No subscription data, initialize trial (only for non-admins)
        initializeTrial(user.uid);
        return null;
      }

      return Subscription.fromFirestore(doc);
    });
  }

  /// Initialize trial for new user
  /// This method ensures the user document is created in Firestore
  /// Skips trial initialization for admin users
  Future<Subscription?> initializeTrial(String userId) async {
    // Check if user is admin - admins don't need trials
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final existingData = userDoc.exists ? userDoc.data() : null;
    final isAdmin = existingData?['isAdmin'] == true;
    
    // If user is admin, don't initialize trial - just ensure basic fields exist
    if (isAdmin) {
      // Get user info from auth
      String? userEmail = _auth.currentUser?.email;
      String? userDisplayName = _auth.currentUser?.displayName;
      
      if (userEmail == null || userDisplayName == null) {
        try {
          await _auth.currentUser?.reload();
          userEmail = _auth.currentUser?.email;
          userDisplayName = _auth.currentUser?.displayName;
        } catch (e) {
          // Continue with available info
        }
      }
      
      // For admins, only set isAdmin and email (no other fields)
      final adminData = {
        'email': userEmail,
        'isAdmin': true,
      };
      
      await _firestore.collection('users').doc(userId).set(
        adminData,
        SetOptions(merge: true),
      );
      
      // Remove all other fields using update (FieldValue.delete() works in update)
      try {
        await _firestore.collection('users').doc(userId).update({
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
      
      // Return null for admin users (no subscription needed)
      return null;
    }
    
    // Regular user - initialize trial
    final now = DateTime.now();
    final trialEndDate = now.add(Duration(days: defaultTrialPeriodDays));

    final subscription = Subscription(
      userId: userId,
      status: SubscriptionStatus.trial,
      trialStartDate: now,
      trialEndDate: trialEndDate,
      createdAt: now,
      lastUpdated: now,
    );

    // Get user info from auth (with retry if needed)
    String? userEmail = _auth.currentUser?.email;
    String? userDisplayName = _auth.currentUser?.displayName;
    
    // If user info is not available, try reloading
    if (userEmail == null || userDisplayName == null) {
      try {
        await _auth.currentUser?.reload();
        userEmail = _auth.currentUser?.email;
        userDisplayName = _auth.currentUser?.displayName;
      } catch (e) {
        // If reload fails, continue with available info
      }
    }
    
    // Prepare document data - preserve isAdmin if it exists
    final userData = {
      ...subscription.toFirestore(),
      'email': userEmail,
      'displayName': userDisplayName,
      'createdAt': Timestamp.fromDate(now),
      'lastUpdated': Timestamp.fromDate(now),
      // Preserve isAdmin field if it exists
      if (existingData?['isAdmin'] != null) 'isAdmin': existingData!['isAdmin'],
    };

    // Always use merge to preserve existing fields like isAdmin
    await _firestore.collection('users').doc(userId).set(
      userData,
      SetOptions(merge: true),
    );

    return subscription;
  }

  /// Check if current user has active access
  Future<bool> hasActiveAccess() async {
    try {
      final subscription = await getCurrentUserSubscription();
      if (subscription == null) return false;
      return subscription.hasActiveAccess;
    } catch (e) {
      return false;
    }
  }

  /// Get subscription status for current user
  Future<SubscriptionStatus?> getSubscriptionStatus() async {
    try {
      final subscription = await getCurrentUserSubscription();
      return subscription?.status;
    } catch (e) {
      return null;
    }
  }

  /// Grant subscription to a user (admin only).
  /// If the user was on trial, the trial is deactivated (trial dates cleared).
  Future<void> grantSubscription(
    String userId,
    SubscriptionType type,
  ) async {
    try {
      final now = DateTime.now();
      final endDate = type == SubscriptionType.monthly
          ? now.add(Duration(days: 30))
          : now.add(Duration(days: 365));

      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'active',
        'subscriptionType': type == SubscriptionType.monthly ? 'monthly' : 'yearly',
        'subscriptionStartDate': Timestamp.fromDate(now),
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'trialStartDate': FieldValue.delete(),
        'trialEndDate': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Extend trial period for a user (admin only)
  Future<void> extendTrial(String userId, int additionalDays) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        await initializeTrial(userId);
        return;
      }

      final data = doc.data();
      DateTime? currentTrialEndDate;

      if (data != null && data['trialEndDate'] != null) {
        currentTrialEndDate = (data['trialEndDate'] as Timestamp).toDate();
      } else {
        currentTrialEndDate = DateTime.now().add(Duration(days: defaultTrialPeriodDays));
      }

      final newTrialEndDate = currentTrialEndDate.add(Duration(days: additionalDays));

      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'trial',
        'trialEndDate': Timestamp.fromDate(newTrialEndDate),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Revoke subscription (admin only)
  Future<void> revokeSubscription(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'cancelled',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get all users with their subscription status (admin only)
  Future<List<Map<String, dynamic>>> getAllUsersWithSubscriptions() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        users.add({
          'userId': doc.id,
          'email': data['email'] ?? 'No email',
          'displayName': data['displayName'] ?? 'No name',
          'subscriptionStatus': data['subscriptionStatus'] ?? 'trial',
          'subscriptionType': data['subscriptionType'],
          'trialEndDate': data['trialEndDate'],
          'subscriptionEndDate': data['subscriptionEndDate'],
          'createdAt': data['createdAt'],
          'isAdmin': data['isAdmin'] ?? false,
        });
      }

      return users;
    } catch (e) {
      return [];
    }
  }

  /// Stream of all users with subscriptions (admin only)
  Stream<List<Map<String, dynamic>>> getAllUsersWithSubscriptionsStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'email': data['email'] ?? 'No email',
          'displayName': data['displayName'] ?? 'No name',
          'subscriptionStatus': data['subscriptionStatus'] ?? 'trial',
          'subscriptionType': data['subscriptionType'],
          'trialEndDate': data['trialEndDate'],
          'subscriptionEndDate': data['subscriptionEndDate'],
          'createdAt': data['createdAt'],
          'isAdmin': data['isAdmin'] ?? false,
        };
      }).toList();
    });
  }

  /// Get user subscription by ID (admin only)
  Future<Subscription?> getUserSubscription(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['subscriptionStatus'] == null) {
        return null;
      }

      return Subscription.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }
}
