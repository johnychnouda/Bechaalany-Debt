import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';
import '../utils/currency_formatter.dart';
import 'add_debt_screen.dart';
import 'customer_details_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _filteredDebts = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  Set<String> _lastKnownDebtIds = {};
  String _sortBy = 'date'; // date, amount, customer, status
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
      _filteredDebts = debts.where((debt) {
        final matchesSearch = debt.customerName.toLowerCase().contains(query) ||
                             debt.description.toLowerCase().contains(query);
        
        final matchesStatus = _selectedStatus == 'All' ||
                             debt.status.toString().split('.').last == _selectedStatus.toLowerCase();
        
        return matchesSearch && matchesStatus;
      }).toList();
      
      // Sort the filtered debts
      _sortDebts();
    });
  }

  void _sortDebts() {
    switch (_sortBy) {
      case 'date':
        _filteredDebts.sort((a, b) => _sortAscending 
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
      case 'amount':
        _filteredDebts.sort((a, b) => _sortAscending 
            ? a.amount.compareTo(b.amount)
            : b.amount.compareTo(a.amount));
        break;
      case 'customer':
        _filteredDebts.sort((a, b) => _sortAscending 
            ? a.customerName.compareTo(b.customerName)
            : b.customerName.compareTo(a.customerName));
        break;
      case 'status':
        _filteredDebts.sort((a, b) => _sortAscending 
            ? a.status.toString().compareTo(b.status.toString())
            : b.status.toString().compareTo(a.status.toString()));
        break;
    }
  }

  Future<void> _markAsPaid(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark as Paid'),
          content: Text('Are you sure you want to mark this debt as paid?\n\nCustomer: ${debt.customerName}\nAmount: ${CurrencyFormatter.formatAmount(context, debt.amount)}'),
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
                  _filterDebts(); // Re-filter after status change
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debt marked as paid successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to mark debt as paid: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Mark as Paid', style: TextStyle(color: AppColors.success)),
            ),
          ],
        );
      },
    );
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

        final l10n = AppLocalizations.of(context);
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Debt History'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            actions: [
              IconButton(
                onPressed: _exportDebts,
                icon: const Icon(Icons.download),
                tooltip: 'Export Report',
              ),
            ],
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
                        hintText: l10n.searchByNameDescription,
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
                    // Sort Options
                    Row(
                      children: [
                        const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _sortBy,
                          items: [
                            DropdownMenuItem(value: 'date', child: const Text('Date')),
                            DropdownMenuItem(value: 'amount', child: const Text('Amount')),
                            DropdownMenuItem(value: 'customer', child: const Text('Customer')),
                            DropdownMenuItem(value: 'status', child: const Text('Status')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                            _filterDebts();
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _sortAscending = !_sortAscending;
                            });
                            _filterDebts();
                          },
                          icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Debts list
              Expanded(
                child: _filteredDebts.isEmpty
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
                        itemCount: _filteredDebts.length,
                        itemBuilder: (context, index) {
                          final debt = _filteredDebts[index];
                          return _DebtCard(
                            debt: debt,
                            onMarkAsPaid: () => _markAsPaid(debt),
                            onDelete: () => _deleteDebt(debt),
                            onViewCustomer: () => _viewCustomerDetails(debt),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddDebtScreen(),
                ),
              );
              // No need to manually refresh - AppState handles it
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  void _viewCustomerDetails(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final customer = appState.customers.firstWhere((c) => c.id == debt.customerId);
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customer: customer),
      ),
    );
    // No need to manually refresh - AppState handles it
  }

  String _getEmptyStateMessage() {
    switch (_selectedStatus) {
      case 'Pending':
        return 'No pending debts';
      case 'Paid':
        return 'No paid debts';
      case 'All':
      default:
        return 'No debts found';
    }
  }

  String _getEmptyStateSubMessage() {
    switch (_selectedStatus) {
      case 'Pending':
        return 'All debts have been paid';
      case 'Paid':
        return 'No debts have been marked as paid yet';
      case 'All':
      default:
        return 'Add a new debt to get started';
    }
  }

  Future<void> _exportDebts() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final debts = appState.debts;
      
      // Create CSV content
      final csvContent = StringBuffer();
      csvContent.writeln('Customer Name,Description,Amount,Status,Payment Date,Notes');
      
      for (final debt in debts) {
        final paymentDate = debt.paidAt != null ? debt.paidAt!.toString().split(' ')[0] : '';
        final notes = debt.notes ?? '';
        csvContent.writeln('${debt.customerName},"${debt.description}",${debt.amount},${debt.statusText},$paymentDate,"$notes"');
      }
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/debts_report.csv');
      await file.writeAsString(csvContent.toString());
      
      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Debts Report');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debts report exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export debts: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onMarkAsPaid;
  final VoidCallback onDelete;
  final VoidCallback onViewCustomer;

  const _DebtCard({
    required this.debt,
    required this.onMarkAsPaid,
    required this.onDelete,
    required this.onViewCustomer,
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
                        debt.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        debt.description,
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
                    Text(
                      CurrencyFormatter.formatAmount(context, debt.amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
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
                  'Created: ${_formatDate(debt.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (debt.status == DebtStatus.paid && debt.paidAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Paid: ${_formatDate(debt.paidAt!)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            
            // Payment method and notes
            if (debt.notes != null && debt.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      debt.notes!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Action buttons
            if (debt.status != DebtStatus.paid) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onMarkAsPaid,
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Mark as Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewCustomer,
                      icon: const Icon(Icons.person, size: 16),
                      label: const Text('View Customer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewCustomer,
                      icon: const Icon(Icons.person, size: 16),
                      label: const Text('View Customer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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

  IconData _getStatusIcon() {
    switch (debt.status) {
      case DebtStatus.paid:
        return Icons.check_circle;
      case DebtStatus.pending:
      default:
        return Icons.pending;
    }
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