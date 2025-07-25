import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import 'customer_details_screen.dart';
import 'add_debt_from_product_screen.dart';

class DebtHistoryScreen extends StatefulWidget {
  const DebtHistoryScreen({super.key});

  @override
  State<DebtHistoryScreen> createState() => _DebtHistoryScreenState();
}

class _DebtHistoryScreenState extends State<DebtHistoryScreen> {
  List<Map<String, dynamic>> _groupedDebts = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  Set<String> _lastKnownDebtIds = {};
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterDebts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDebts() {
    final appState = Provider.of<AppState>(context, listen: false);
    final debts = appState.debts;
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      // Filter debts first
      final filteredDebts = debts.where((debt) {
        final matchesSearch = debt.customerName.toLowerCase().contains(query) ||
                             debt.description.toLowerCase().contains(query);
        
        final matchesStatus = _selectedStatus == 'All' ||
                             (_selectedStatus == 'Pending' && !debt.isFullyPaid) ||
                             (_selectedStatus == 'Paid' && debt.isFullyPaid);
        
        return matchesSearch && matchesStatus;
      }).toList();
      
      // Group debts by customer
      _groupDebtsByCustomer(filteredDebts);
    });
  }

  void _groupDebtsByCustomer(List<Debt> debts) {
    final Map<String, List<Debt>> groupedMap = {};
    
    // Group debts by customer ID
    for (final debt in debts) {
      if (!groupedMap.containsKey(debt.customerId)) {
        groupedMap[debt.customerId] = [];
      }
      groupedMap[debt.customerId]!.add(debt);
    }
    
    // Convert to list of maps for easier handling
    _groupedDebts = groupedMap.entries.map((entry) {
      final customerDebts = entry.value;
      final totalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalPaidAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
      final totalRemainingAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
      
      final pendingDebts = customerDebts.where((d) => !d.isFullyPaid).toList();
      final paidDebts = customerDebts.where((d) => d.isFullyPaid).toList();
      final partiallyPaidDebts = customerDebts.where((d) => d.isPartiallyPaid).toList();
      
      return {
        'customerId': entry.key,
        'customerName': customerDebts.first.customerName,
        'debts': customerDebts,
        'totalAmount': totalAmount,
        'totalPaidAmount': totalPaidAmount,
        'totalRemainingAmount': totalRemainingAmount,
        'totalDebts': customerDebts.length,
        'pendingDebts': pendingDebts.length,
        'paidDebts': paidDebts.length,
        'partiallyPaidDebts': partiallyPaidDebts.length,
      };
    }).toList();
    
    // Sort grouped debts
    _sortGroupedDebts();
  }

  void _sortGroupedDebts() {
    // Sort by the most recent debt date (newest first by default, oldest first when ascending)
    _groupedDebts.sort((a, b) {
      final aLatestDebt = (a['debts'] as List<Debt>).reduce((curr, next) => 
          curr.createdAt.isAfter(next.createdAt) ? curr : next);
      final bLatestDebt = (b['debts'] as List<Debt>).reduce((curr, next) => 
          curr.createdAt.isAfter(next.createdAt) ? curr : next);
      
      return _sortAscending 
          ? aLatestDebt.createdAt.compareTo(bLatestDebt.createdAt)  // ascending: oldest first
          : bLatestDebt.createdAt.compareTo(aLatestDebt.createdAt); // descending: newest first
    });
  }

  Future<void> _markAsPaid(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      await appState.updateDebt(debt);
      _filterDebts(); // Re-filter after status change
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(debt.isFullyPaid ? 'Debt marked as paid successfully' : 'Payment applied successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update debt: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteDebt(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Debt'),
          content: Text('Are you sure you want to delete this debt?\n\nCustomer: ${debt.customerName}\nAmount: ${CurrencyFormatter.formatAmount(context, debt.amount)}'),
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
                  _filterDebts(); // Re-filter after deletion
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debt deleted successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete debt: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
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
        // Update filtered debts when app state changes
        final currentDebtIds = appState.debts.map((d) => '${d.id}_${d.status}').toSet();
        if (_lastKnownDebtIds != currentDebtIds) {
          _lastKnownDebtIds = currentDebtIds;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _filterDebts();
          });
        }
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Debt History'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddDebtFromProductScreen(),
                ),
              );
              // Refresh the debt history after adding a new debt
              if (mounted) {
                _filterDebts();
              }
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(
              Icons.add_shopping_cart,
              color: Colors.white,
            ),
          ),
          body: Column(
            children: [
              // Search and filter bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by customer name or description',
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Paid'].map((status) {
                          final isSelected = _selectedStatus == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatus = status;
                                });
                                _filterDebts();
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sort Direction Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _sortAscending = !_sortAscending;
                            });
                            _filterDebts();
                          },
                          icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                          tooltip: _sortAscending ? 'Oldest first' : 'Newest first',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Debts list
              Expanded(
                child: _groupedDebts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
                            const SizedBox(height: 16),
                            Text(
                              _getEmptyStateMessage(),
                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 18, fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getEmptyStateSubMessage(),
                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _groupedDebts.length,
                        itemBuilder: (context, index) {
                          final group = _groupedDebts[index];
                          return _GroupedDebtCard(
                            group: group,
                            onMarkAsPaid: (debt) => _markAsPaid(debt),
                            onDelete: (debt) => _deleteDebt(debt),
                            onViewCustomer: () => _viewCustomerDetails(group['customerId'] as String),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewCustomerDetails(String customerId) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final customer = appState.customers.firstWhere((c) => c.id == customerId);
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(
          customer: customer,
          showDebtsSection: false,
        ),
      ),
    );
    
    // Force refresh of debt history when returning from customer details
    if (mounted) {
      _filterDebts();
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedStatus) {
      case 'Pending':
        return 'No pending debts';
      case 'Paid':
        return 'No fully paid debts';
      case 'All':
      default:
        return 'No debts found';
    }
  }

  String _getEmptyStateSubMessage() {
    switch (_selectedStatus) {
      case 'Pending':
        return 'All debts have been fully paid';
      case 'Paid':
        return 'No debts have been fully paid yet';
      case 'All':
      default:
        return 'Add a new debt to get started';
    }
  }
}

class _GroupedDebtCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final Function(Debt) onMarkAsPaid;
  final Function(Debt) onDelete;
  final VoidCallback onViewCustomer;

  const _GroupedDebtCard({
    required this.group,
    required this.onMarkAsPaid,
    required this.onDelete,
    required this.onViewCustomer,
  });

  Color _getStatusColor() {
    final pendingDebts = (group['debts'] as List<Debt>).where((d) => !d.isFullyPaid).length;
    final partiallyPaidDebts = (group['debts'] as List<Debt>).where((d) => d.isPartiallyPaid).length;
    final fullyPaidDebts = (group['debts'] as List<Debt>).where((d) => d.isFullyPaid).length;
    
    if (fullyPaidDebts > 0 && pendingDebts > 0) {
      return Colors.blue; // Mixed status
    } else if (partiallyPaidDebts > 0) {
      return Colors.blue; // Partially paid
    } else if (pendingDebts > 0) {
      return Colors.orange; // All pending
    } else {
      return Colors.green; // All fully paid
    }
  }

  String _getStatusText() {
    final pendingDebts = (group['debts'] as List<Debt>).where((d) => !d.isFullyPaid).length;
    final partiallyPaidDebts = (group['debts'] as List<Debt>).where((d) => d.isPartiallyPaid).length;
    final fullyPaidDebts = (group['debts'] as List<Debt>).where((d) => d.isFullyPaid).length;
    
    if (pendingDebts == 0) {
      return 'All Paid';
    } else if (partiallyPaidDebts > 0) {
      return 'Partially Paid';
    } else if (fullyPaidDebts > 0 && pendingDebts > 0) {
      return 'Mixed';
    } else {
      return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status icon and customer name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['customerName'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${group['totalDebts']} debts • ${group['totalRemainingAmount'] as double > 0 ? '${CurrencyFormatter.formatAmount(context, group['totalRemainingAmount'] as double)} remaining' : 'All paid'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatAmount(context, group['totalRemainingAmount'] as double),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if ((group['totalPaidAmount'] as double) > 0) ...[
                          Text(
                            'Paid: ${CurrencyFormatter.formatAmount(context, group['totalPaidAmount'] as double)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor().withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date information
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Latest: ${_formatDate(_getLatestDebt().createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (group['paidDebts'] > 0) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '${group['paidDebts']} paid',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            
            // Action buttons
            const SizedBox(height: 12),
            Row(
              children: [
                if ((group['totalRemainingAmount'] as double) > 0) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentDialog(context),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Make Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewCustomer,
                    icon: const Icon(Icons.person, size: 16),
                    label: const Text('View Debts'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    final pendingDebts = (group['debts'] as List<Debt>).where((d) => !d.isFullyPaid).length;
    final partiallyPaidDebts = (group['debts'] as List<Debt>).where((d) => d.isPartiallyPaid).length;
    final fullyPaidDebts = (group['debts'] as List<Debt>).where((d) => d.isFullyPaid).length;
    
    if (fullyPaidDebts > 0 && pendingDebts > 0) {
      return Icons.payment; // Mixed status
    } else if (partiallyPaidDebts > 0) {
      return Icons.payment; // Partially paid
    } else if (pendingDebts > 0) {
      return Icons.pending; // All pending
    } else {
      return Icons.check_circle; // All fully paid
    }
  }

  Debt _getLatestDebt() {
    final debts = group['debts'] as List<Debt>;
    return debts.reduce((curr, next) => 
        curr.createdAt.isAfter(next.createdAt) ? curr : next);
  }

  void _showPaymentDialog(BuildContext context) {
    final unpaidDebts = (group['debts'] as List<Debt>)
        .where((d) => !d.isFullyPaid)
        .toList();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Payment for ${group['customerName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Remaining: ${CurrencyFormatter.formatAmount(context, group['totalRemainingAmount'] as double)}'),
              const SizedBox(height: 16),
              const Text('Payment Options:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _PaymentOption(
                title: 'Pay All Remaining',
                subtitle: 'Mark all debts as fully paid',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _payAllRemaining(unpaidDebts);
                },
              ),
              const SizedBox(height: 8),
              _PaymentOption(
                title: 'Partial Payment',
                subtitle: 'Enter amount to pay',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showPartialPaymentDialog(context, unpaidDebts);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _payAllRemaining(List<Debt> unpaidDebts) {
    for (final debt in unpaidDebts) {
      final updatedDebt = debt.copyWith(
        paidAmount: debt.amount,
        status: DebtStatus.paid,
        paidAt: DateTime.now(),
      );
      onMarkAsPaid(updatedDebt);
    }
  }

  void _showPartialPaymentDialog(BuildContext context, List<Debt> unpaidDebts) {
    final TextEditingController amountController = TextEditingController();
    final totalRemaining = unpaidDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Partial Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Remaining: ${CurrencyFormatter.formatAmount(context, totalRemaining)}'),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0 && amount <= totalRemaining) {
                  Navigator.of(dialogContext).pop();
                  _applyPartialPayment(unpaidDebts, amount);
                }
              },
              child: const Text('Apply Payment'),
            ),
          ],
        );
      },
    );
  }

  void _applyPartialPayment(List<Debt> unpaidDebts, double paymentAmount) {
    double remainingPayment = paymentAmount;
    
    for (final debt in unpaidDebts) {
      if (remainingPayment <= 0) break;
      
      final debtRemaining = debt.remainingAmount;
      final paymentForThisDebt = remainingPayment > debtRemaining ? debtRemaining : remainingPayment;
      
      final updatedDebt = debt.copyWith(
        paidAmount: debt.paidAmount + paymentForThisDebt,
        status: (debt.paidAmount + paymentForThisDebt) >= debt.amount ? DebtStatus.paid : DebtStatus.pending,
        paidAt: (debt.paidAmount + paymentForThisDebt) >= debt.amount ? DateTime.now() : debt.paidAt,
      );
      
      onMarkAsPaid(updatedDebt);
      remainingPayment -= paymentForThisDebt;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
} 