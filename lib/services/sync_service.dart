import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
import '../models/debt.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isInitialized = false;
  DateTime? _lastSyncTime;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString('last_sync_time');
    if (lastSyncString != null) {
      _lastSyncTime = DateTime.parse(lastSyncString);
    }

    _isInitialized = true;
  }

  Future<void> syncData(List<Customer> customers, List<Debt> debts) async {
    if (!_isInitialized) await initialize();

    try {
      // In a real implementation, this would sync with a cloud service
      // For now, we'll simulate the sync process
      await _simulateCloudSync(customers, debts);
      
      // Update last sync time
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      if (_lastSyncTime != null) {
        await prefs.setString('last_sync_time', _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncCustomers(List<Customer> customers) async {
    if (!_isInitialized) await initialize();

    try {
      // Simulate customer sync
      await _simulateCustomerSync(customers);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncDebts(List<Debt> debts) async {
    if (!_isInitialized) await initialize();

    try {
      // Simulate debt sync
      await _simulateDebtSync(debts);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    if (!_isInitialized) await initialize();

    try {
      // Simulate customer deletion from cloud
      await _simulateCustomerDeletion(customerId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDebt(String debtId) async {
    if (!_isInitialized) await initialize();

    try {
      // Simulate debt deletion from cloud
      await _simulateDebtDeletion(debtId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchCloudData() async {
    if (!_isInitialized) await initialize();

    try {
      // Simulate fetching data from cloud
      final cloudData = await _simulateCloudFetch();
      return cloudData;
    } catch (e) {
      return null;
    }
  }

  DateTime? get lastSyncTime => _lastSyncTime;

  bool get isInitialized => _isInitialized;

  // Simulate cloud operations (replace with actual cloud service)
  Future<void> _simulateCloudSync(List<Customer> customers, List<Debt> debts) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a real implementation, this would:
    // 1. Upload customers to cloud storage
    // 2. Upload debts to cloud storage
    // 3. Handle conflicts and merge data
    // 4. Update timestamps
  }

  Future<void> _simulateCustomerSync(List<Customer> customers) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _simulateDebtSync(List<Debt> debts) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _simulateCustomerDeletion(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _simulateDebtDeletion(String debtId) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<Map<String, dynamic>> _simulateCloudFetch() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Simulate cloud data
    return {
      'customers': [],
      'debts': [],
      'lastModified': DateTime.now().toIso8601String(),
    };
  }

  // Check if sync is needed
  bool isSyncNeeded() {
    if (_lastSyncTime == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastSync = now.difference(_lastSyncTime!);
    
    // Sync if more than 1 hour has passed
    return timeSinceLastSync.inHours >= 1;
  }

  // Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'isInitialized': _isInitialized,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'isSyncNeeded': isSyncNeeded(),
    };
  }

  // Reset sync state (for testing)
  Future<void> resetSyncState() async {
    _lastSyncTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_time');
  }
} 