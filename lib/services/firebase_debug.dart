import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseDebugService {
  static Future<void> debugFirebaseInitialization() async {
    try {
      print('🔍 Starting Firebase debug...');
      print('🔍 Platform: ${kIsWeb ? 'Web' : 'iOS'}');
      
      if (kIsWeb) {
        print('🔍 Web platform detected, using custom config...');
        
        // Try the working configuration
        final webConfig = const FirebaseOptions(
          apiKey: 'AIzaSyAr_fbII2W9n31c4cEo0u8YBECO-MhpLRk',
          appId: '1:1016883344576:web:1115dc80bff5535f80e925',
          messagingSenderId: '1016883344576',
          projectId: 'bechaalany-debt-app',
          authDomain: 'bechaalany-debt-app.firebaseapp.com',
          storageBucket: 'bechaalany-debt-app.firebasestorage.app',
        );
        
        print('🔍 Web config created:');
        print('  - Project ID: ${webConfig.projectId}');
        print('  - App ID: ${webConfig.appId}');
        print('  - Auth Domain: ${webConfig.authDomain}');
        
        print('🔍 Initializing Firebase with web config...');
        await Firebase.initializeApp(options: webConfig);
        print('✅ Firebase initialized successfully with web config!');
        
      } else {
        print('🔍 iOS platform detected, using default config...');
        await Firebase.initializeApp();
        print('✅ Firebase initialized successfully with default config!');
      }
      
      // Test Firestore
      print('🔍 Testing Firestore...');
      final firestore = FirebaseFirestore.instance;
      print('✅ Firestore instance created');
      print('🔍 Firestore project ID: ${firestore.app.options.projectId}');
      
      // Test Auth
      print('🔍 Testing Auth...');
      final auth = FirebaseAuth.instance;
      print('✅ Auth instance created');
      print('🔍 Auth domain: ${auth.app.options.authDomain}');
      
      // Test Storage
      print('🔍 Testing Storage...');
      final storage = FirebaseStorage.instance;
      print('✅ Storage instance created');
      
      print('🎉 All Firebase services working!');
      
    } catch (e) {
      print('❌ Firebase debug failed: $e');
      print('🔍 Error type: ${e.runtimeType}');
      print('🔍 Error details: ${e.toString()}');
      
      if (e is FirebaseException) {
        print('🔍 Firebase error code: ${e.code}');
        print('🔍 Firebase error message: ${e.message}');
      }
      
      rethrow;
    }
  }
}
