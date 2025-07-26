import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer.dart';
import '../models/debt.dart';

class CloudKitService {
  static final CloudKitService _instance = CloudKitService._internal();
  factory CloudKitService() => _instance;
  CloudKitService._internal();

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  bool _isInitialized = false;
  DateTime? _lastSyncTime;
  String? _userId;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      
      // Check if user is signed in
      final user = _auth!.currentUser;
      if (user != null) {
        _userId = user.uid;
      }
      
      _isInitialized = true;
      print('CloudKit service initialized successfully');
    } catch (e) {
      print('Error initializing CloudKit service: $e');
      rethrow;
    }
  }

  Future<bool> isUserSignedIn() async {
    if (!_isInitialized) await initialize();
    return _auth!.currentUser != null;
  }

  Future<void> signInAnonymously() async {
    if (!_isInitialized) await initialize();
    
    try {
      final userCredential = await _auth!.signInAnonymously();
      _userId = userCredential.user!.uid;
      print('User signed in anonymously: ${userCredential.user!.uid}');
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow;
    }
  }

  Future<void> syncData(List<Customer> customers, List<Debt> debts) async {
    if (!_isInitialized) await initialize();
    
    // Ensure user is signed in
    if (!await isUserSignedIn()) {
      await signInAnonymously();
    }

    try {
      final batch = _firestore!.batch();
      
      // Sync customers
      for (final customer in customers) {
        final customerRef = _firestore!
            .collection('users')
            .doc(_userId)
            .collection('customers')
            .doc(customer.id);
        
        batch.set(customerRef, {
          'id': customer.id,
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email,
          'address': customer.address,
          'createdAt': customer.createdAt.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      // Sync debts
      for (final debt in debts) {
        final debtRef = _firestore!
            .collection('users')
            .doc(_userId)
            .collection('debts')
            .doc(debt.id);
        
        batch.set(debtRef, {
          'id': debt.id,
          'customerId': debt.customerId,
          'customerName': debt.customerName,
          'description': debt.description,
          'amount': debt.amount,
          'paidAmount': debt.paidAmount,
          'remainingAmount': debt.remainingAmount,
          'type': debt.type.toString(),
          'status': debt.status.toString(),
          'createdAt': debt.createdAt.toIso8601String(),
          'paidAt': debt.paidAt?.toIso8601String(),
          'notes': debt.notes,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      await batch.commit();
      
      // Update last sync time
      _lastSyncTime = DateTime.now();
      
      print('Data synced successfully to CloudKit');
    } catch (e) {
      print('Error syncing data to CloudKit: $e');
      rethrow;
    }
  }

  Future<void> syncCustomers(List<Customer> customers) async {
    if (!_isInitialized) await initialize();
    
    if (!await isUserSignedIn()) {
      await signInAnonymously();
    }

    try {
      final batch = _firestore!.batch();
      
      for (final customer in customers) {
        final customerRef = _firestore!
            .collection('users')
            .doc(_userId)
            .collection('customers')
            .doc(customer.id);
        
        batch.set(customerRef, {
          'id': customer.id,
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email,
          'address': customer.address,
          'createdAt': customer.createdAt.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      await batch.commit();
      print('Customers synced successfully to CloudKit');
    } catch (e) {
      print('Error syncing customers to CloudKit: $e');
      rethrow;
    }
  }

  Future<void> syncDebts(List<Debt> debts) async {
    if (!_isInitialized) await initialize();
    
    if (!await isUserSignedIn()) {
      await signInAnonymously();
    }

    try {
      final batch = _firestore!.batch();
      
      for (final debt in debts) {
        final debtRef = _firestore!
            .collection('users')
            .doc(_userId)
            .collection('debts')
            .doc(debt.id);
        
        batch.set(debtRef, {
          'id': debt.id,
          'customerId': debt.customerId,
          'customerName': debt.customerName,
          'description': debt.description,
          'amount': debt.amount,
          'paidAmount': debt.paidAmount,
          'remainingAmount': debt.remainingAmount,
          'type': debt.type.toString(),
          'status': debt.status.toString(),
          'createdAt': debt.createdAt.toIso8601String(),
          'paidAt': debt.paidAt?.toIso8601String(),
          'notes': debt.notes,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      await batch.commit();
      print('Debts synced successfully to CloudKit');
    } catch (e) {
      print('Error syncing debts to CloudKit: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    if (!_isInitialized) await initialize();
    
    if (!await isUserSignedIn()) {
      await signInAnonymously();
    }

    try {
      await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('customers')
          .doc(customerId)
          .delete();
      
      print('Customer deleted from CloudKit successfully');
    } catch (e) {
      print('Error deleting customer from CloudKit: $e');
      rethrow;
    }
  }

  Future<void> deleteDebt(String debtId) async {
    if (!_isInitialized) await initialize();
    
    if (!await isUserSignedIn()) {
      await signInAnonymously();
    }

    try {
      await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('debts')
          .doc(debtId)
          .delete();
      
      print('Debt deleted from CloudKit successfully');
    } catch (e) {
      print('Error deleting debt from CloudKit: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchCloudData() async {
    if (!_isInitialized) await initialize();
    
    if (!await isUserSignedIn()) {
      await signInAnonymously();
    }

    try {
      final customersSnapshot = await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('customers')
          .get();
      
      final debtsSnapshot = await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('debts')
          .get();
      
      final customers = customersSnapshot.docs.map((doc) {
        final data = doc.data();
        return Customer(
          id: data['id'],
          name: data['name'],
          phone: data['phone'],
          email: data['email'],
          address: data['address'],
          createdAt: DateTime.parse(data['createdAt']),
        );
      }).toList();
      
      final debts = debtsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Debt(
          id: data['id'],
          customerId: data['customerId'],
          customerName: data['customerName'],
          description: data['description'],
          amount: data['amount'].toDouble(),
          type: DebtType.values.firstWhere(
            (e) => e.toString() == 'DebtType.${data['type']}',
            orElse: () => DebtType.credit,
          ),
          status: DebtStatus.values.firstWhere(
            (e) => e.toString() == 'DebtStatus.${data['status']}',
            orElse: () => DebtStatus.pending,
          ),
          createdAt: DateTime.parse(data['createdAt']),
          paidAt: data['paidAt'] != null ? DateTime.parse(data['paidAt']) : null,
          notes: data['notes'],
          paidAmount: data['paidAmount']?.toDouble() ?? 0.0,
        );
      }).toList();
      
      return {
        'customers': customers,
        'debts': debts,
        'lastModified': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error fetching cloud data: $e');
      return null;
    }
  }

  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isInitialized => _isInitialized;
  String? get userId => _userId;

  bool isSyncNeeded() {
    if (_lastSyncTime == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastSync = now.difference(_lastSyncTime!);
    
    // Sync if more than 1 hour has passed
    return timeSinceLastSync.inHours >= 1;
  }

  Map<String, dynamic> getSyncStatus() {
    return {
      'isInitialized': _isInitialized,
      'isUserSignedIn': _auth?.currentUser != null,
      'userId': _userId,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'isSyncNeeded': isSyncNeeded(),
    };
  }

  Future<void> resetSyncState() async {
    _lastSyncTime = null;
    _userId = null;
    if (_auth?.currentUser != null) {
      await _auth!.signOut();
    }
  }

  Future<void> clearAllData() async {
    try {
      if (!_isInitialized || _userId == null) {
        await initialize();
      }
      
      final batch = _firestore!.batch();
      
      // Clear customers
      final customersQuery = await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('customers')
          .get();
      
      for (final doc in customersQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Clear debts
      final debtsQuery = await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('debts')
          .get();
      
      for (final doc in debtsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      _lastSyncTime = DateTime.now();
      
      print('All data cleared from CloudKit successfully');
    } catch (e) {
      print('Error clearing data from CloudKit: $e');
      rethrow;
    }
  }
} 