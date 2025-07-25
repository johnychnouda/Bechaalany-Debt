import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import 'add_debt_screen.dart';
import 'add_customer_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  List<Debt> _customerDebts = [];
  late Customer _currentCustomer;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _loadCustomerDebts();
  }

  void _loadCustomerDebts() {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      // Only show pending debts in the debts list, but keep all debts for financial summary
      _customerDebts = appState.debts.where((d) => d.customerId == _currentCustomer.id && d.status != DebtStatus.paid).toList();
    });
  }

  Future<void> _markAsPaid(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark as Paid'),
          content: Text('Are you sure you want to mark this debt as paid?\n\nAmount: ${CurrencyFormatter.formatAmount(context, debt.amount)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await appState.markDebtAsPaid(debt.id);
                  _loadCustomerDebts(); // Re-load after status change
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debt marked as paid successfully'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        margin: EdgeInsets.all(16),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to mark debt as paid: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                }
              },
              child: const Text('Mark as Paid'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDebt(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Debt'),
          content: Text('Are you sure you want to delete this debt?\n\nAmount: ${CurrencyFormatter.formatAmount(context, debt.amount)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await appState.deleteDebt(debt.id);
                  _loadCustomerDebts(); // Re-load after deletion
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debt deleted successfully'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        margin: EdgeInsets.all(16),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete debt: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Calculate totals from all customer debts (including paid ones)
        final allCustomerDebts = appState.debts.where((d) => d.customerId == _currentCustomer.id).toList();
        final totalDebt = allCustomerDebts.where((d) => d.status == DebtStatus.pending).fold(0.0, (sum, debt) => sum + debt.amount);
        final totalPaid = allCustomerDebts.where((d) => d.status == DebtStatus.paid).fold(0.0, (sum, debt) => sum + debt.amount);
        
        // Get pending debts for the customer (this will update automatically when AppState changes)
        final customerPendingDebts = appState.debts.where((d) => d.customerId == _currentCustomer.id && d.status != DebtStatus.paid).toList();

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              _currentCustomer.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.grey[50],
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCustomerScreen(customer: _currentCustomer),
                    ),
                  );
                  // Refresh the screen after editing
                  if (result == true) {
                    setState(() {
                      // Refresh customer data from AppState
                      final appState = Provider.of<AppState>(context, listen: false);
                      final updatedCustomer = appState.customers.firstWhere(
                        (c) => c.id == _currentCustomer.id,
                        orElse: () => _currentCustomer,
                      );
                      _currentCustomer = updatedCustomer;
                    });
                    // Refresh customer debts
                    _loadCustomerDebts();
                  }
                },
                icon: Icon(
                  Icons.edit,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Customer Information Section
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'CUSTOMER INFORMATION',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Customer ID
                      ListTile(
                        leading: Icon(
                          Icons.tag,
                          color: Colors.grey[600],
                        ),
                        title: const Text(
                          'Customer ID',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          _currentCustomer.id,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // Name
                      ListTile(
                        leading: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                        ),
                        title: const Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          _currentCustomer.name,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // Phone
                      ListTile(
                        leading: Icon(
                          Icons.phone,
                          color: Colors.grey[600],
                        ),
                        title: const Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          _currentCustomer.phone,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // Email (if available)
                      if (_currentCustomer.email != null)
                        ListTile(
                          leading: Icon(
                            Icons.email,
                            color: Colors.grey[600],
                          ),
                          title: const Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            _currentCustomer.email!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      // Address (if available)
                      if (_currentCustomer.address != null)
                        ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: Colors.grey[600],
                          ),
                          title: const Text(
                            'Address',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            _currentCustomer.address!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Financial Summary Section
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'FINANCIAL SUMMARY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Total Debt
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                        title: const Text(
                          'Total Pending Debt',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          CurrencyFormatter.formatAmount(context, totalDebt),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Total Paid
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                        ),
                        title: const Text(
                          'Total Paid',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          CurrencyFormatter.formatAmount(context, totalPaid),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Debts Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DEBTS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddDebtScreen(customer: _currentCustomer),
                            ),
                          );
                          
                          // Refresh the debt list if a debt was added
                          if (result == true) {
                            _loadCustomerDebts();
                          }
                        },
                        child: const Text(
                          'Add Debt',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Debts List
                customerPendingDebts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No pending debts',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All debts have been paid or add a new debt',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: customerPendingDebts.length,
                        itemBuilder: (context, index) {
                          final debt = customerPendingDebts[index];
                          return _DebtCard(
                            debt: debt,
                            onMarkAsPaid: () => _markAsPaid(debt),
                            onDelete: () => _deleteDebt(debt),
                          );
                        },
                      ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onMarkAsPaid;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.onMarkAsPaid,
    required this.onDelete,
  });

  Color _getStatusColor() {
    switch (debt.status) {
      case DebtStatus.paid:
        return Colors.green;
      case DebtStatus.pending:
      default:
        return Colors.orange;
    }
  }

  String _getStatusText() {
    switch (debt.status) {
      case DebtStatus.paid:
        return 'Paid';
      case DebtStatus.pending:
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    debt.status == DebtStatus.paid ? Icons.check_circle : Icons.attach_money,
                    color: _getStatusColor(),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        debt.status == DebtStatus.paid 
                            ? 'Paid: ${_formatDate(debt.paidAt ?? debt.createdAt)}'
                            : 'Created: ${_formatDate(debt.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatAmount(context, debt.amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (debt.status != DebtStatus.paid) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onMarkAsPaid,
                      child: const Text(
                        'Mark as Paid',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onDelete,
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return '${difference.abs()} days ago';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return 'in $difference days';
    }
  }
} 