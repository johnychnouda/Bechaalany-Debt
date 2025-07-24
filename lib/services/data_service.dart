import 'package:hive/hive.dart';
import '../models/customer.dart';
import '../models/debt.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
  
  Box<Customer>? _customerBox;
  Box<Debt>? _debtBox;
  
  Box<Customer> get _customerBoxSafe {
    _customerBox ??= Hive.box<Customer>('customers');
    return _customerBox!;
  }
  
  Box<Debt> get _debtBoxSafe {
    _debtBox ??= Hive.box<Debt>('debts');
    return _debtBox!;
  }

  // Customer methods
  List<Customer> get customers {
    try {
      return _customerBoxSafe.values.toList();
    } catch (e) {
      print('Error accessing customers box: $e');
      return [];
    }
  }
  
  Future<void> addCustomer(Customer customer) async {
    try {
      _customerBoxSafe.put(customer.id, customer);
      print('Customer added successfully to local storage');
    } catch (e) {
      print('Error adding customer: $e');
      rethrow;
    }
  }
  
  Future<void> updateCustomer(Customer customer) async {
    try {
      _customerBoxSafe.put(customer.id, customer);
      print('Customer updated successfully in local storage');
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }
  
  Future<void> deleteCustomer(String customerId) async {
    try {
      _customerBoxSafe.delete(customerId);
      // Also remove related debts
      _debtBoxSafe.values.where((d) => d.customerId == customerId).toList().forEach((d) {
        _debtBoxSafe.delete(d.id);
      });
      print('Customer and related debts deleted successfully from local storage');
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }
  
  Customer? getCustomer(String customerId) {
    try {
      return _customerBoxSafe.get(customerId);
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  // Debt methods
  List<Debt> get debts {
    try {
      return _debtBoxSafe.values.toList();
    } catch (e) {
      print('Error accessing debts box: $e');
      return [];
    }
  }
  
  List<Debt> getDebtsByCustomer(String customerId) {
    try {
      return _debtBoxSafe.values.where((d) => d.customerId == customerId).toList();
    } catch (e) {
      print('Error getting customer debts: $e');
      return [];
    }
  }
  
  Future<void> addDebt(Debt debt) async {
    try {
      _debtBoxSafe.put(debt.id, debt);
      print('Debt added successfully to local storage');
    } catch (e) {
      print('Error adding debt: $e');
      rethrow;
    }
  }
  
  Future<void> updateDebt(Debt debt) async {
    try {
      _debtBoxSafe.put(debt.id, debt);
      print('Debt updated successfully in local storage');
    } catch (e) {
      print('Error updating debt: $e');
      rethrow;
    }
  }
  
  Future<void> deleteDebt(String debtId) async {
    try {
      _debtBoxSafe.delete(debtId);
      print('Debt deleted successfully from local storage');
    } catch (e) {
      print('Error deleting debt: $e');
      rethrow;
    }
  }
  
  Future<void> markDebtAsPaid(String debtId) async {
    try {
      final debt = _debtBoxSafe.get(debtId);
      if (debt != null) {
        final updated = debt.copyWith(
          status: DebtStatus.paid,
          paidAt: DateTime.now(),
        );
        _debtBoxSafe.put(debtId, updated);
        print('Debt marked as paid in local storage');
      }
    } catch (e) {
      print('Error marking debt as paid: $e');
      rethrow;
    }
  }

  // Statistics methods
  double get totalDebt {
    return debts
        .where((d) => d.status == DebtStatus.pending)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }
  
  double get totalPaid {
    return debts
        .where((d) => d.status == DebtStatus.paid)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }
  
  double get overdueDebt {
    return debts
        .where((d) => d.isOverdue)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }
  
  int get pendingDebtsCount {
    return debts.where((d) => d.status == DebtStatus.pending).length;
  }
  
  int get paidDebtsCount {
    return debts.where((d) => d.status == DebtStatus.paid).length;
  }
  
  int get overdueDebtsCount {
    return debts.where((d) => d.isOverdue).length;
  }

  // Recent debts (last 5)
  List<Debt> get recentDebts {
    final sortedDebts = List<Debt>.from(debts);
    sortedDebts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedDebts.take(5).toList();
  }

  // Generate unique IDs
  String generateCustomerId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  String generateDebtId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
} 