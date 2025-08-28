import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();
  
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  late FirebaseStorage _storage;
  
  // Initialize Firebase
  Future<void> initialize() async {
    try {
      // Use the same config that works in the web test
      if (kIsWeb) {
        // For web, use the working configuration
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyAr_fbII2W9n31c4cEo0u8YBECO-MhpLRk',
            appId: '1:1016883344576:web:1115dc80bff5535f80e925',
            messagingSenderId: '1016883344576',
            projectId: 'bechaalany-debt-app',
            authDomain: 'bechaalany-debt-app.firebaseapp.com',
            storageBucket: 'bechaalany-debt-app.firebasestorage.app',
          ),
        );
      } else {
        // For iOS, use the default options
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _storage = FirebaseStorage.instance;
      
      print('Firebase initialized successfully');
      print('Firebase project ID: ${_firestore.app.options.projectId}');
      print('Firebase auth domain: ${_auth.app.options.authDomain}');
    } catch (e) {
      print('Error initializing Firebase: $e');
      print('Error details: ${e.toString()}');
      rethrow;
    }
  }
  
  // Authentication methods
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
  
  User? get currentUser => _auth.currentUser;
  
  // Firestore methods for debt tracking
  Future<void> syncCustomerToFirestore(Map<String, dynamic> customerData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .doc(customerData['id'])
          .set(customerData, SetOptions(merge: true));
          
      print('Customer synced to Firestore');
    } catch (e) {
      print('Error syncing customer: $e');
    }
  }
  
  Future<void> syncDebtToFirestore(Map<String, dynamic> debtData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('debts')
          .doc(debtData['id'])
          .set(debtData, SetOptions(merge: true));
          
      print('Debt synced to Firestore');
    } catch (e) {
      print('Error syncing debt: $e');
    }
  }
  
  Future<void> syncCategoryToFirestore(Map<String, dynamic> categoryData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryData['id'])
          .set(categoryData, SetOptions(merge: true));
          
      print('Category synced to Firestore');
    } catch (e) {
      print('Error syncing category: $e');
    }
  }
  
  Future<void> syncActivityToFirestore(Map<String, dynamic> activityData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .doc(activityData['id'])
          .set(activityData, SetOptions(merge: true));
          
      print('Activity synced to Firestore');
    } catch (e) {
      print('Error syncing activity: $e');
    }
  }
  
  // Data retrieval methods
  Stream<QuerySnapshot> getCustomersStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('customers')
        .snapshots();
  }
  
  Stream<QuerySnapshot> getDebtsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('debts')
        .snapshots();
  }
  
  Stream<QuerySnapshot> getCategoriesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots();
  }
  
  Stream<QuerySnapshot> getActivitiesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .snapshots();
  }
  
  // Backup and restore methods
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      final backupData = {
        'timestamp': FieldValue.serverTimestamp(),
        'customers': [],
        'debts': [],
        'categories': [],
        'activities': [],
      };
      
      // Get all data
      final customersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .get();
      
      final debtsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('debts')
          .get();
      
      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();
      
      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .get();
      
      // Add data to backup
      backupData['customers'] = customersSnapshot.docs.map((doc) => doc.data()).toList();
      backupData['debts'] = debtsSnapshot.docs.map((doc) => doc.data()).toList();
      backupData['categories'] = categoriesSnapshot.docs.map((doc) => doc.data()).toList();
      backupData['activities'] = activitiesSnapshot.docs.map((doc) => doc.data()).toList();
      
      // Save backup
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .add(backupData);
      
      print('Backup created successfully');
      return backupData;
    } catch (e) {
      print('Error creating backup: $e');
      rethrow;
    }
  }
  
  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
  
  // Get user ID
  String? get userId => _auth.currentUser?.uid;
}
