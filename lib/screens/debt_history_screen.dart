import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../services/notification_service.dart';
import 'add_debt_from_product_screen.dart';
import 'customer_debt_receipt_screen.dart';

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
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

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
      // Filter debts individually based on their own status
      final filteredDebts = debts.where((debt) {
        final matchesSearch = debt.customerName.toLowerCase().contains(query) ||
                             debt.customerId.toLowerCase().contains(query);
        
        // Determine individual debt status
        String debtStatus;
        if (debt.isFullyPaid) {
          debtStatus = 'fully paid';
        } else if (debt.paidAmount > 0) {
          debtStatus = 'partially paid';
        } else {
          debtStatus = 'pending';
        }
        
        final matchesStatus = _selectedStatus == 'All' ||
                             debtStatus == _selectedStatus.toLowerCase();
        
        return matchesSearch && matchesStatus;
      }).toList();
      
      // Always show each debt individually (not grouped by customer)
      // This ensures each new debt creates a separate receipt
      _groupDebtsIndividually(filteredDebts);
    });
  }

  void _groupDebtsIndividually(List<Debt> debts) {
    // Show each debt as a separate entry (not grouped by customer)
    _groupedDebts = debts.map((debt) {
      return {
        'customerId': debt.customerId,
        'customerName': debt.customerName,
        'debts': [debt], // Single debt per entry
        'totalAmount': debt.amount,
        'totalPaidAmount': debt.paidAmount,
        'totalRemainingAmount': debt.remainingAmount,
        'totalDebts': 1,
        'pendingDebts': debt.isFullyPaid ? 0 : (debt.paidAmount > 0 ? 0 : 1),
        'paidDebts': debt.isFullyPaid ? 1 : 0,
        'partiallyPaidDebts': debt.isFullyPaid ? 0 : (debt.paidAmount > 0 ? 1 : 0),
      };
    }).toList();
    
    // Sort individual debts
    _sortGroupedDebts();
  }



  void _sortGroupedDebts() {
    // Sort by the most recent debt date (newest first by default, oldest first when ascending)
    _groupedDebts.sort((a, b) {
      final aLatestDebt = (a['debts'] as List<Debt>).reduce((curr, next) {
        final currLatestDate = curr.paidAt ?? curr.createdAt;
        final nextLatestDate = next.paidAt ?? next.createdAt;
        return currLatestDate.isAfter(nextLatestDate) ? curr : next;
      });
      final bLatestDebt = (b['debts'] as List<Debt>).reduce((curr, next) {
        final currLatestDate = curr.paidAt ?? curr.createdAt;
        final nextLatestDate = next.paidAt ?? next.createdAt;
        return currLatestDate.isAfter(nextLatestDate) ? curr : next;
      });
      
      final aLatestDate = aLatestDebt.paidAt ?? aLatestDebt.createdAt;
      final bLatestDate = bLatestDebt.paidAt ?? bLatestDebt.createdAt;
      
      return _sortAscending 
          ? aLatestDate.compareTo(bLatestDate)  // ascending: oldest first
          : bLatestDate.compareTo(aLatestDate); // descending: newest first
    });
  }

  Future<void> _markAsPaid(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      await appState.markDebtAsPaid(debt.id);
      _filterDebts(); // Re-filter after status change
    } catch (e) {
      if (mounted) {
        // Show error notification
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Error',
          body: 'Failed to mark debt as paid: $e',
        );
      }
    }
  }

  Future<void> _deleteDebt(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Don't allow deletion of fully paid debts
    if (debt.isFullyPaid) {
      _scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Cannot delete fully paid debts. Use the "Clear" button to remove completed transactions.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
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
                } catch (e) {
                  if (mounted) {
                    // Show error notification
                    final notificationService = NotificationService();
                    await notificationService.showErrorNotification(
                      title: 'Error',
                      body: 'Failed to delete debt: $e',
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
        final currentDebtIds = appState.debts.map((d) => '${d.id}_${d.status}_${d.paidAt?.millisecondsSinceEpoch ?? 0}_${d.amount}_${d.paidAmount}').toSet();
        if (_lastKnownDebtIds != currentDebtIds) {
          _lastKnownDebtIds = currentDebtIds;
          // Use a small delay to prevent infinite loops
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _filterDebts();
            }
          });
        }
        
        return Scaffold(
          key: const Key('debt_history_screen'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Debt History'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          ),
          floatingActionButton: FloatingActionButton(
            key: const Key('debt_history_fab'),
            heroTag: 'debt_history_fab_hero',
            onPressed: () async {
              await Navigator.push(
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
              Icons.add,
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
                        hintText: 'Search by customer name or ID',
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
                        children: ['All', 'Pending', 'Partially Paid', 'Fully Paid'].map((status) {
                          final isSelected = _selectedStatus == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                status,
                                style: TextStyle(
                                  color: isSelected 
                                      ? (status == 'Pending' 
                                          ? Colors.red[700] 
                                          : status == 'Partially Paid' 
                                              ? Colors.orange[700] 
                                              : status == 'Fully Paid' 
                                                  ? Colors.green[700] 
                                                  : AppColors.primary)
                                      : null,
                                  fontWeight: isSelected ? FontWeight.w600 : null,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatus = status;
                                });
                                _filterDebts();
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: isSelected 
                                  ? (status == 'Pending' 
                                      ? Colors.red[50] 
                                      : status == 'Partially Paid' 
                                          ? Colors.orange[50] 
                                          : status == 'Fully Paid' 
                                              ? Colors.green[50] 
                                              : AppColors.primary.withValues(alpha: 0.2))
                                  : Colors.grey[200],
                              checkmarkColor: isSelected 
                                  ? (status == 'Pending' 
                                      ? Colors.red[700] 
                                      : status == 'Partially Paid' 
                                          ? Colors.orange[700] 
                                          : status == 'Fully Paid' 
                                              ? Colors.green[700] 
                                              : AppColors.primary)
                                  : AppColors.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      ),
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
                            onViewCustomer: (debt) => _viewCustomerDetails(group['customerId'] as String, debt),
                            selectedStatus: _selectedStatus,
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

  void _viewCustomerDetails(String customerId, Debt specificDebt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final customer = appState.customers.firstWhere((c) => c.id == customerId);
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDebtReceiptScreen(
          customer: customer,
          customerDebts: [specificDebt], // Only show this specific debt
          partialPayments: appState.partialPayments,
        ),
      ),
    );
    
    // Force refresh of debt history when returning from receipt
    if (mounted) {
      _filterDebts();
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedStatus) {
      case 'Pending':
        return 'No pending debts';
      case 'Partially Paid':
        return 'No partially paid debts';
      case 'Fully Paid':
        return 'No fully paid debts';
      case 'All':
      default:
        return 'No debts found';
    }
  }

  String _getEmptyStateSubMessage() {
    switch (_selectedStatus) {
      case 'Pending':
        return 'All debts are either partially or fully paid';
      case 'Partially Paid':
        return 'No debts have been partially paid yet';
      case 'Fully Paid':
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
  final Function(Debt) onViewCustomer;
  final String selectedStatus;

  const _GroupedDebtCard({
    required this.group,
    required this.onMarkAsPaid,
    required this.onDelete,
    required this.onViewCustomer,
    required this.selectedStatus,
  });

  Color _getStatusColor() {
    final debts = group['debts'] as List<Debt>;
    
    // Since we're filtering by status, all debts in this group should have the same status
    // Check the first debt to determine the color
    if (debts.isEmpty) return Colors.grey;
    
    final firstDebt = debts.first;
    if (firstDebt.isFullyPaid) {
      return Colors.green; // Fully paid
    } else if (firstDebt.paidAmount > 0) {
      return Colors.orange; // Partially paid
    } else {
      return Colors.red; // Pending (new debt)
    }
  }

  String _getStatusText() {
    final debts = group['debts'] as List<Debt>;
    
    // Since we're filtering by status, all debts in this group should have the same status
    if (debts.isEmpty) return 'No Debts';
    
    final firstDebt = debts.first;
    if (firstDebt.isFullyPaid) {
      return 'Fully Paid';
    } else if (firstDebt.paidAmount > 0) {
      return 'Partially Paid';
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
                    color: _getStatusColor().withValues(alpha: 0.1),
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
                      // Customer name and amount on same line
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group['customerName'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Amount on the same line as customer name
                          // Always show individual debt amount since each debt is now a separate receipt
                          Text(
                            _getAmountText(context),
                            style: TextStyle(
                              color: _getAmountColor(),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Status text below the amount
                      Row(
                        children: [
                          const Spacer(),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                  'Latest: ${_formatDate(_getLatestActivityDate())}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            // Action buttons
            const SizedBox(height: 12),
            Row(
              children: [
                if ((group['totalRemainingAmount'] as double) > 0) ...[
                  // Show "Make Payment" button when there are remaining debts
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
                ] else ...[
                  // Show "Clear" button when all debts are fully paid
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showClearDialog(context),
                      icon: const Icon(Icons.delete_forever, size: 16),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onViewCustomer((group['debts'] as List<Debt>).first),
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: const Text('View Receipt'),
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
    final debts = group['debts'] as List<Debt>;
    
    // Since we're filtering by status, all debts in this group should have the same status
    if (debts.isEmpty) return Icons.help_outline;
    
    final firstDebt = debts.first;
    if (firstDebt.isFullyPaid) {
      return Icons.check_circle; // Fully paid
    } else if (firstDebt.paidAmount > 0) {
      return Icons.pending; // Partially paid
    } else {
      return Icons.schedule; // Pending (new debt)
    }
  }

  String _getAmountText(BuildContext context) {
    final debts = group['debts'] as List<Debt>;
    if (debts.isEmpty) return '';
    
    final debt = debts.first; // Since we're showing individual debts in "All" view
    
    if (debt.isFullyPaid) {
      return '${CurrencyFormatter.formatAmount(context, debt.amount)} paid';
    } else if (debt.paidAmount > 0) {
      return '${CurrencyFormatter.formatAmount(context, debt.remainingAmount)} remaining';
    } else {
      return '${CurrencyFormatter.formatAmount(context, debt.amount)}';
    }
  }

  Color _getAmountColor() {
    final debts = group['debts'] as List<Debt>;
    if (debts.isEmpty) return Colors.grey;
    
    final debt = debts.first; // Since we're showing individual debts in "All" view
    
    if (debt.isFullyPaid) {
      return Colors.green[600]!;
    } else if (debt.paidAmount > 0) {
      return Colors.orange[600]!;
    } else {
      return Colors.red[600]!;
    }
  }

  Debt _getLatestDebt() {
    final debts = group['debts'] as List<Debt>;
    return debts.reduce((curr, next) {
      // Get the most recent activity date for each debt
      final currLatestDate = curr.paidAt ?? curr.createdAt;
      final nextLatestDate = next.paidAt ?? next.createdAt;
      
      return currLatestDate.isAfter(nextLatestDate) ? curr : next;
    });
  }

  DateTime _getLatestActivityDate() {
    final latestDebt = _getLatestDebt();
    final result = latestDebt.paidAt ?? latestDebt.createdAt;
    // Return the most recent activity date (paidAt if available, otherwise createdAt)
    return result;
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
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0 && amount <= totalRemaining) {
                  Navigator.of(dialogContext).pop();
                  await _applyPartialPayment(context, unpaidDebts, amount);
                }
              },
              child: const Text('Apply Payment'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyPartialPayment(BuildContext context, List<Debt> unpaidDebts, double paymentAmount) async {
    
    double remainingPayment = paymentAmount;
    final appState = Provider.of<AppState>(context, listen: false);
    
    for (final debt in unpaidDebts) {
      if (remainingPayment <= 0) break;
      
      final debtRemaining = debt.remainingAmount;
      final paymentForThisDebt = remainingPayment > debtRemaining ? debtRemaining : remainingPayment;
      
      // Use the new partial payment method
      await appState.applyPartialPayment(debt.id, paymentForThisDebt);
      remainingPayment -= paymentForThisDebt;
    }
    
  }

  void _showClearDialog(BuildContext context) {
    final customerName = group['customerName'] as String;
    final allDebts = group['debts'] as List<Debt>;
    final completedDebts = allDebts.where((debt) => debt.isFullyPaid).toList();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Completed Debts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to clear all completed debts for $customerName?'),
              const SizedBox(height: 16),
              const Text(
                'This action will permanently delete all fully paid debts for this customer. This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _clearCompletedDebts(context, completedDebts, group['customerName'] as String);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _clearCompletedDebts(BuildContext context, List<Debt> completedDebts, String customerName) async {
    final appState = Provider.of<AppState>(context, listen: false);
    for (final debt in completedDebts) {
      await appState.deleteDebt(debt.id);
    }
    // Show success notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared ${completedDebts.length} completed debts for $customerName'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    
    // Compare only the date part (without time)
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;
    
    // Format time in 12-hour format
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';
    final timeString = 'at $hour:$minute $period';
    

    
    if (difference == 0) {
      return 'Today $timeString';
    } else if (difference == 1) {
      return 'Yesterday $timeString';
    } else {
      // For 3rd day and above, show date in format: 3-12-2024 at 3:45 pm
      final day = date.day;
      final month = date.month;
      final year = date.year;
      return '$day-$month-$year $timeString';
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