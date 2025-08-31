import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

class FirebaseTestService {
  static Future<void> testFirebaseConnection() async {
    try {
      print('🧪 Testing Firebase connection...');
      
      // Test 1: Initialize Firebase
      print('1️⃣ Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
      
      // Test 2: Test Firestore connection
      print('2️⃣ Testing Firestore connection...');
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').doc('connection_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase connection test successful',
        'platform': 'iOS',
      });
      print('✅ Firestore write successful');
      
      // Test 3: Test read
      print('3️⃣ Testing Firestore read...');
      final doc = await firestore.collection('test').doc('connection_test').get();
      print('✅ Firestore read successful: ${doc.data()}');
      
      // Test 4: Test authentication
      print('4️⃣ Testing anonymous authentication...');
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.signInAnonymously();
      print('✅ Anonymous auth successful: ${userCredential.user?.uid}');
      
      // Test 5: Test user-specific data
      print('5️⃣ Testing user-specific data write...');
      final userId = userCredential.user?.uid;
      if (userId != null) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('test_data')
            .add({
          'message': 'User-specific data test',
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('✅ User-specific data write successful');
      }
      
      print('🎉 All Firebase tests passed!');
      
    } catch (e) {
      print('❌ Firebase test failed: $e');
      print('🔍 Error details: ${e.toString()}');
      rethrow;
    }
  }
  
  static Future<void> testCustomerSync() async {
    try {
      print('🧪 Testing customer sync...');
      
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      
      final userId = auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('No authenticated user');
      }
      
      // Test customer sync
      final testCustomerId = 'test_customer_${DateTime.now().millisecondsSinceEpoch}';
      final testCustomer = {
        'id': testCustomerId,
        'name': 'Test Customer',
        'phone': '+1234567890',
        'email': 'test@example.com',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      await firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .doc(testCustomerId)
          .set(testCustomer);
      
      print('✅ Customer sync test successful');
      print('📱 Customer ID: ${testCustomer['id']}');
      
    } catch (e) {
      print('❌ Customer sync test failed: $e');
      rethrow;
    }
  }
}
