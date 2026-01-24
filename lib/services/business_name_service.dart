import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_service.dart';

class BusinessNameService {
  static final BusinessNameService _instance = BusinessNameService._internal();
  factory BusinessNameService() => _instance;
  BusinessNameService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminService _adminService = AdminService();

  // Admin business name (hardcoded)
  static const String adminBusinessName = 'Bechaalany Connect';

  // Cache for business name
  String? _cachedBusinessName;
  String? _cachedUserId;
  bool? _cachedIsAdmin;

  /// Get the business name for the current user
  /// Returns "Bechaalany Connect" for admins, or the user's business name for regular users
  Future<String> getBusinessName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return adminBusinessName; // Fallback to admin name

      // Return cached value if available and user hasn't changed
      if (_cachedBusinessName != null && _cachedUserId == user.uid && _cachedIsAdmin != null) {
        return _cachedBusinessName!;
      }

      // Check if user is admin
      final isAdmin = await _adminService.isAdmin();
      
      if (isAdmin) {
        // Admin always uses "Bechaalany Connect"
        _cachedBusinessName = adminBusinessName;
        _cachedUserId = user.uid;
        _cachedIsAdmin = true;
        return adminBusinessName;
      }

      // For regular users, get business name from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final businessName = data?['businessName'] as String?;
        
        if (businessName != null && businessName.trim().isNotEmpty) {
          _cachedBusinessName = businessName.trim();
          _cachedUserId = user.uid;
          _cachedIsAdmin = false;
          return _cachedBusinessName!;
        }
      }

      // If no business name found, return empty string (will need to be set)
      _cachedBusinessName = '';
      _cachedUserId = user.uid;
      _cachedIsAdmin = false;
      return '';
    } catch (e) {
      // On error, return admin name as fallback
      return adminBusinessName;
    }
  }

  /// Set the business name for the current user (only for non-admin users)
  Future<void> setBusinessName(String businessName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is admin
      final isAdmin = await _adminService.isAdmin();
      if (isAdmin) {
        throw Exception('Admin business name cannot be changed');
      }

      // Validate business name
      final trimmedName = businessName.trim();
      if (trimmedName.isEmpty) {
        throw Exception('Business name cannot be empty');
      }

      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'businessName': trimmedName,
      }, SetOptions(merge: true));

      // Update cache
      _cachedBusinessName = trimmedName;
      _cachedUserId = user.uid;
      _cachedIsAdmin = false;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if the current user has a business name set
  Future<bool> hasBusinessName() async {
    try {
      final businessName = await getBusinessName();
      return businessName.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clear cache (useful when user signs out or business name is updated)
  void clearCache() {
    _cachedBusinessName = null;
    _cachedUserId = null;
    _cachedIsAdmin = null;
  }
}
