import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  static FirebaseService get instance => _instance;
  FirebaseService._internal();

  // Initialize Firebase
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      rethrow;
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Anonymous authentication removed - now using Google/Apple sign-in

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Check Firebase connection
  Future<bool> checkConnection() async {
    try {
      await _firestore.collection('_health').doc('ping').get();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get Firebase app instance
  FirebaseApp get app => Firebase.app();
  
  // Get Firestore instance
  FirebaseFirestore get firestore => _firestore;
  
  // Get Auth instance
  FirebaseAuth get auth => _auth;
  
  // Initialize with custom options
  Future<void> initializeWithOptions(FirebaseOptions options) async {
    try {
      await Firebase.initializeApp(options: options);
    } catch (e) {
      rethrow;
    }
  }
  
  // Check if Firebase is initialized
  bool get isInitialized => Firebase.apps.isNotEmpty;
  
  // Get Firebase configuration
  Map<String, dynamic> getFirebaseConfig() {
    try {
      final app = Firebase.app();
      return {
        'name': app.name,
        'options': {
          'apiKey': app.options.apiKey,
          'appId': app.options.appId,
          'messagingSenderId': app.options.messagingSenderId,
          'projectId': app.options.projectId,
        },
      };
    } catch (e) {
      return {};
    }
  }
}
