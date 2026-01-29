import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_access_keys.dart';
import '../models/access.dart';

class AccessService {
  static final AccessService _instance = AccessService._internal();
  factory AccessService() => _instance;
  AccessService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int defaultTrialPeriodDays = 7;

  /// Get current user's access
  /// Returns null for admin users (admins don't have access records)
  /// Uses Source.server so revoke/expiry is seen immediately (no stale cache).
  Future<Access?> getCurrentUserAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get(
        const GetOptions(source: Source.server),
      );

      final data = doc.data();
      if (data?['isAdmin'] == true) {
        return null;
      }

      if (!doc.exists) {
        return await initializeTrial(user.uid);
      }

      if (data == null || data[FirestoreAccessKeys.status] == null) {
        return await initializeTrial(user.uid);
      }

      return Access.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Stream of current user's access (real-time updates)
  Stream<Access?> getCurrentUserAccessStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data?['isAdmin'] == true) return null;
      if (!doc.exists) {
        initializeTrial(user.uid);
        return null;
      }
      if (data == null || data[FirestoreAccessKeys.status] == null) {
        initializeTrial(user.uid);
        return null;
      }
      return Access.fromFirestore(doc);
    });
  }

  Future<Access?> initializeTrial(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final existingData = userDoc.exists ? userDoc.data() : null;
    final isAdmin = existingData?['isAdmin'] == true;

    if (isAdmin) {
      String? userEmail = _auth.currentUser?.email;
      String? userDisplayName = _auth.currentUser?.displayName;
      if (userEmail == null || userDisplayName == null) {
        try {
          await _auth.currentUser?.reload();
          userEmail = _auth.currentUser?.email;
          userDisplayName = _auth.currentUser?.displayName;
        } catch (e) {}
      }
      final adminData = {'email': userEmail, 'isAdmin': true};
      await _firestore.collection('users').doc(userId).set(
            adminData,
            SetOptions(merge: true),
          );
      try {
        await _firestore.collection('users').doc(userId).update({
          'displayName': FieldValue.delete(),
          'lastUpdated': FieldValue.delete(),
          FirestoreAccessKeys.status: FieldValue.delete(),
          FirestoreAccessKeys.type: FieldValue.delete(),
          FirestoreAccessKeys.startDate: FieldValue.delete(),
          FirestoreAccessKeys.endDate: FieldValue.delete(),
          'trialStartDate': FieldValue.delete(),
          'trialEndDate': FieldValue.delete(),
          'createdAt': FieldValue.delete(),
          'lastSignIn': FieldValue.delete(),
          'verifiedAt': FieldValue.delete(),
          'emailVerified': FieldValue.delete(),
          'onboardingCompleted': FieldValue.delete(),
          'onboardingCompletedAt': FieldValue.delete(),
        });
      } catch (e) {}
      return null;
    }

    final now = DateTime.now();
    final trialEndDate = now.add(Duration(days: defaultTrialPeriodDays));

    final access = Access(
      userId: userId,
      status: AccessStatus.trial,
      trialStartDate: now,
      trialEndDate: trialEndDate,
      createdAt: now,
      lastUpdated: now,
    );

    String? userEmail = _auth.currentUser?.email;
    String? userDisplayName = _auth.currentUser?.displayName;
    if (userEmail == null || userDisplayName == null) {
      try {
        await _auth.currentUser?.reload();
        userEmail = _auth.currentUser?.email;
        userDisplayName = _auth.currentUser?.displayName;
      } catch (e) {}
    }

    final userData = {
      ...access.toFirestore(),
      'email': userEmail,
      'displayName': userDisplayName,
      'createdAt': Timestamp.fromDate(now),
      'lastUpdated': Timestamp.fromDate(now),
      if (existingData?['isAdmin'] != null) 'isAdmin': existingData!['isAdmin'],
    };

    await _firestore.collection('users').doc(userId).set(
          userData,
          SetOptions(merge: true),
        );

    return access;
  }

  Future<bool> hasActiveAccess() async {
    try {
      final access = await getCurrentUserAccess();
      if (access == null) return false;
      return access.hasActiveAccess;
    } catch (e) {
      return false;
    }
  }

  Future<AccessStatus?> getAccessStatus() async {
    try {
      final access = await getCurrentUserAccess();
      return access?.status;
    } catch (e) {
      return null;
    }
  }

  /// Grant access to a user (admin only).
  Future<void> grantAccess(String userId, AccessType type) async {
    try {
      final now = DateTime.now();
      final endDate = type == AccessType.monthly
          ? now.add(Duration(days: 30))
          : now.add(Duration(days: 365));

      await _firestore.collection('users').doc(userId).update({
        FirestoreAccessKeys.status: 'active',
        FirestoreAccessKeys.type: type == AccessType.monthly ? 'monthly' : 'yearly',
        FirestoreAccessKeys.startDate: Timestamp.fromDate(now),
        FirestoreAccessKeys.endDate: Timestamp.fromDate(endDate),
        'trialStartDate': FieldValue.delete(),
        'trialEndDate': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

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
        currentTrialEndDate =
            DateTime.now().add(Duration(days: defaultTrialPeriodDays));
      }
      final newTrialEndDate =
          currentTrialEndDate.add(Duration(days: additionalDays));
      await _firestore.collection('users').doc(userId).update({
        FirestoreAccessKeys.status: 'trial',
        'trialEndDate': Timestamp.fromDate(newTrialEndDate),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Revoke access (admin only)
  Future<void> revokeAccess(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        FirestoreAccessKeys.status: 'cancelled',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get all users with their access status (admin only)
  Future<List<Map<String, dynamic>>> getAllUsersWithAccess() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final statusVal = data[FirestoreAccessKeys.status];
        final typeVal = data[FirestoreAccessKeys.type];
        final endVal = data[FirestoreAccessKeys.endDate];
        users.add({
          'userId': doc.id,
          'email': data['email'] ?? 'No email',
          'displayName': data['displayName'] ?? 'No name',
          FirestoreAccessKeys.status: statusVal ?? 'trial',
          FirestoreAccessKeys.type: typeVal,
          'trialEndDate': data['trialEndDate'],
          FirestoreAccessKeys.endDate: endVal,
          'createdAt': data['createdAt'],
          'isAdmin': data['isAdmin'] ?? false,
        });
      }
      return users;
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getAllUsersWithAccessStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final statusVal = data[FirestoreAccessKeys.status];
        final typeVal = data[FirestoreAccessKeys.type];
        final endVal = data[FirestoreAccessKeys.endDate];
        return {
          'userId': doc.id,
          'email': data['email'] ?? 'No email',
          'displayName': data['displayName'] ?? 'No name',
          FirestoreAccessKeys.status: statusVal ?? 'trial',
          FirestoreAccessKeys.type: typeVal,
          'trialEndDate': data['trialEndDate'],
          FirestoreAccessKeys.endDate: endVal,
          'createdAt': data['createdAt'],
          'isAdmin': data['isAdmin'] ?? false,
        };
      }).toList();
    });
  }

  Future<Access?> getUserAccess(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data[FirestoreAccessKeys.status] == null) return null;
      return Access.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }
}
