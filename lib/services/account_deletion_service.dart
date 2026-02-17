import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_auth_service.dart';

/// Service for deleting user accounts and all associated data
/// Complies with App Store Guideline 5.1.1(v) - Account Deletion Requirements
class AccountDeletionService {
  static final AccountDeletionService _instance = AccountDeletionService._internal();
  factory AccountDeletionService() => _instance;
  AccountDeletionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAuthService _authService = FirebaseAuthService();

  /// Delete the current user's account and all associated data
  /// This method:
  /// 1. Deletes all user data from Firestore (customers, debts, activities, backups, etc.)
  /// 2. Deletes the user document itself
  /// 3. Deletes the Firebase Auth account
  /// 
  /// Throws an exception if deletion fails at any step
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    final userId = user.uid;

    try {
      // Step 1: Delete all user data from Firestore subcollections
      await _deleteAllUserData(userId);

      // Step 2: Delete the user document itself
      await _firestore.collection('users').doc(userId).delete();

      // Step 3: Delete the Firebase Auth account
      // This must be done last, as it will invalidate the user session
      await _authService.deleteAccount();
    } catch (e) {
      // If Firebase Auth deletion fails, we've already deleted the data
      // This is acceptable - the user won't be able to sign in again anyway
      // But we should still throw the error so the UI can inform the user
      rethrow;
    }
  }

  /// Delete all user data from Firestore subcollections
  Future<void> _deleteAllUserData(String userId) async {
    try {
      // Delete all subcollections in batches
      await Future.wait([
        _deleteCollection('users/$userId/customers'),
        _deleteCollection('users/$userId/debts'),
        _deleteCollection('users/$userId/activities'),
        _deleteCollection('users/$userId/backups'),
        _deleteCollection('users/$userId/categories'),
        _deleteCollection('users/$userId/product_purchases'),
        _deleteCollection('users/$userId/currency_settings'),
        _deleteCollection('users/$userId/partial_payments'),
      ]);
    } catch (e) {
      // If deletion fails, throw an error
      throw Exception('Failed to delete user data: $e');
    }
  }

  /// Delete all documents in a collection using batch operations
  /// Firestore has a limit of 500 operations per batch, so we handle large collections
  Future<void> _deleteCollection(String collectionPath) async {
    try {
      final collectionRef = _firestore.collection(collectionPath);
      final batchSize = 500; // Firestore batch limit
      
      while (true) {
        // Get a batch of documents
        final snapshot = await collectionRef.limit(batchSize).get();
        
        if (snapshot.docs.isEmpty) {
          break; // No more documents to delete
        }

        // Delete documents in batches
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();

        // If we got fewer documents than the limit, we're done
        if (snapshot.docs.length < batchSize) {
          break;
        }
      }
    } catch (e) {
      // Log error but continue with other collections
      // We want to delete as much as possible even if one collection fails
      throw Exception('Failed to delete collection $collectionPath: $e');
    }
  }

  /// Check if account deletion is possible (user is authenticated)
  bool canDeleteAccount() {
    return _auth.currentUser != null;
  }
}
