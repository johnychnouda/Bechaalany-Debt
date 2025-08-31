import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Test Firebase connection
  Future<bool> testConnection() async {
    try {
      // Try to access Firestore
      await _firestore.collection('test').doc('connection').get();
      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Sign in anonymously (for testing)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Anonymous sign in failed: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Test Firestore write
  Future<bool> testWrite() async {
    try {
      await _firestore.collection('test').doc('write_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase is working!',
        'platform': 'web',
      });
      return true;
    } catch (e) {
      print('Firestore write test failed: $e');
      return false;
    }
  }

  // Test Firestore read
  Future<Map<String, dynamic>?> testRead() async {
    try {
      final doc = await _firestore.collection('test').doc('write_test').get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Firestore read test failed: $e');
      return null;
    }
  }
}
