import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache admin status to avoid repeated Firestore calls
  bool? _cachedAdminStatus;
  String? _cachedUserId;

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Return cached value if available and user hasn't changed
      if (_cachedAdminStatus != null && _cachedUserId == user.uid) {
        return _cachedAdminStatus!;
      }

      // Check user document for isAdmin flag
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final isAdmin = data?['isAdmin'] == true;
        
        // Cache the result
        _cachedAdminStatus = isAdmin;
        _cachedUserId = user.uid;
        
        return isAdmin;
      }

      // Check admin config collection
      final adminConfig = await _firestore.collection('admin').doc('config').get();
      if (adminConfig.exists) {
        final data = adminConfig.data();
        final adminEmails = (data?['admins'] as List<dynamic>?) ?? [];
        final adminUserIds = (data?['adminUserIds'] as List<dynamic>?) ?? [];
        
        final isAdmin = adminEmails.contains(user.email) || 
                       adminUserIds.contains(user.uid);
        
        // Cache the result
        _cachedAdminStatus = isAdmin;
        _cachedUserId = user.uid;
        
        return isAdmin;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Stream of admin status (real-time updates)
  Stream<bool> isAdminStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    // Listen to user document for isAdmin flag
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data();
        return data?['isAdmin'] == true;
      }
      return false;
    });
  }

  /// Set user as admin (one-time setup - should be done manually in Firestore)
  /// This method is provided for convenience but should be used carefully
  Future<void> setCurrentUserAsAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Set isAdmin flag in user document
      await _firestore.collection('users').doc(user.uid).set({
        'isAdmin': true,
      }, SetOptions(merge: true));

      // Also add to admin config
      await _firestore.collection('admin').doc('config').set({
        'admins': FieldValue.arrayUnion([user.email]),
        'adminUserIds': FieldValue.arrayUnion([user.uid]),
      }, SetOptions(merge: true));

      // Clear cache
      _cachedAdminStatus = true;
      _cachedUserId = user.uid;
    } catch (e) {
      rethrow;
    }
  }

  /// Set a specific user as admin by userId (admin only)
  /// Requires the current user to be an admin
  Future<void> setUserAsAdmin(String userId, String? userEmail) async {
    try {
      // Check if current user is admin
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can set other users as admin');
      }

      // Set isAdmin flag in user document
      await _firestore.collection('users').doc(userId).set({
        'isAdmin': true,
      }, SetOptions(merge: true));

      // Also add to admin config if email is provided
      if (userEmail != null) {
        await _firestore.collection('admin').doc('config').set({
          'admins': FieldValue.arrayUnion([userEmail]),
          'adminUserIds': FieldValue.arrayUnion([userId]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clear admin cache (useful when user signs out)
  void clearCache() {
    _cachedAdminStatus = null;
    _cachedUserId = null;
  }

  /// Force refresh admin status (bypasses cache)
  /// Useful when admin status is changed in Firestore while user is logged in
  Future<bool> refreshAdminStatus() async {
    clearCache();
    return await isAdmin();
  }
}
