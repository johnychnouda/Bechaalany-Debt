import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../services/data_service.dart';
import 'add_debt_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final DataService _dataService = DataService();
  List<Debt> _customerDebts = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadCustomerDebts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    _loadCustomerDebts();
  }

  void _loadCustomerDebts() {
    setState(() {
      _customerDebts = _dataService.getDebtsByCustomer(widget.customer.id);
    });
  }

  List<Debt> get _filteredDebts {
    switch (_selectedFilter) {
      case 'pending':
        return _customerDebts.where((debt) => debt.status == DebtStatus.pending).toList();
      case 'paid':
        return _customerDebts.where((debt) => debt.status == DebtStatus.paid).toList();
      case 'overdue':
        return _customerDebts.where((debt) => debt.isOverdue).toList();
      default:
        return _customerDebts;
    }
  }

  double get _totalDebt {
    return _customerDebts
        .where((d) => d.status == DebtStatus.pending)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }

  double get _totalPaid {
    return _customerDebts
        .where((d) => d.status == DebtStatus.paid)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          IconButton(
            onPressed: () {
              _loadCustomerDebts();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadCustomerDebts();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              widget.customer.name.split(' ').map((e) => e[0]).join(''),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.customer.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.customer.phone,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                                if (widget.customer.email != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.customer.email!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.customer.address != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.customer.address!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              title: 'Total Debt',
                              value: '\$${_totalDebt.toStringAsFixed(0)}',
                              color: AppColors.error,
                              icon: Icons.account_balance_wallet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoCard(
                              title: 'Total Paid',
                              value: '\$${_totalPaid.toStringAsFixed(0)}',
                              color: AppColors.success,
                              icon: Icons.check_circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Debts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Debts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddDebtScreen(selectedCustomer: widget.customer),
                        ),
                      );
                      if (result == true) {
                        _loadCustomerDebts();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Debt'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All (${_customerDebts.length})',
                      isSelected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pending (${_customerDebts.where((d) => d.status == DebtStatus.pending).length})',
                      isSelected: _selectedFilter == 'pending',
                      onTap: () => setState(() => _selectedFilter = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Paid (${_customerDebts.where((d) => d.status == DebtStatus.paid).length})',
                      isSelected: _selectedFilter == 'paid',
                      onTap: () => setState(() => _selectedFilter = 'paid'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Overdue (${_customerDebts.where((d) => d.isOverdue).length})',
                      isSelected: _selectedFilter == 'overdue',
                      onTap: () => setState(() => _selectedFilter = 'overdue'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Debts List
              if (_filteredDebts.isEmpty)
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                      SizedBox(height: 8),
                      Text('No debts found', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              else
                ...(_filteredDebts.map((debt) => _DebtCard(
                  debt: debt,
                  onMarkAsPaid: () => _markAsPaid(debt),
                  onDelete: () => _deleteDebt(debt),
                ))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsPaid(Debt debt) async {
    try {
      await _dataService.markDebtAsPaid(debt.id);
      _loadCustomerDebts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debt marked as paid'),
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
  }

  Future<void> _deleteDebt(Debt debt) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Debt'),
          content: const Text('Are you sure you want to delete this debt?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _dataService.deleteDebt(debt.id);
                  _loadCustomerDebts();
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
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
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
    if (debt.status == DebtStatus.paid) {
      return AppColors.success;
    } else if (debt.isOverdue) {
      return AppColors.error;
    } else {
      return AppColors.warning;
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${_formatDate(debt.dueDate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${debt.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                        debt.statusText,
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
            if (debt.status == DebtStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMarkAsPaid,
                      child: const Text('Mark as Paid'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Delete'),
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