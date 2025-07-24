import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/debt.dart';
import '../services/data_service.dart';
import 'add_debt_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  String _selectedFilter = 'all';
  final DataService _dataService = DataService();
  List<Debt> _debts = [];
  List<Debt> _filteredDebts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDebts();
    _searchController.addListener(_filterDebts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    _loadDebts();
  }

  void _loadDebts() {
    setState(() {
      _debts = _dataService.debts;
      _filterDebts();
    });
  }

  void _filterDebts() {
    final query = _searchController.text.toLowerCase();
    List<Debt> filtered = _debts;
    
    // Apply search filter
    if (query.isNotEmpty) {
      filtered = filtered.where((debt) {
        return debt.customerName.toLowerCase().contains(query) ||
               debt.description.toLowerCase().contains(query) ||
               debt.amount.toString().contains(query);
      }).toList();
    }
    
    // Apply status filter
    switch (_selectedFilter) {
      case 'pending':
        filtered = filtered.where((debt) => debt.status == DebtStatus.pending).toList();
        break;
      case 'paid':
        filtered = filtered.where((debt) => debt.status == DebtStatus.paid).toList();
        break;
      case 'overdue':
        filtered = filtered.where((debt) => debt.isOverdue).toList();
        break;
    }
    
    setState(() {
      _filteredDebts = filtered;
    });
  }

  Future<void> _markAsPaid(Debt debt) async {
    try {
      await _dataService.markDebtAsPaid(debt.id);
      _loadDebts();
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
                  _loadDebts();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts'),
        actions: [
          IconButton(
            onPressed: () {
              _loadDebts();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadDebts();
        },
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search debts...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
            ),
            // Filter chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All (${_debts.length})',
                      isSelected: _selectedFilter == 'all',
                      onTap: () {
                        setState(() => _selectedFilter = 'all');
                        _filterDebts();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pending (${_debts.where((d) => d.status == DebtStatus.pending).length})',
                      isSelected: _selectedFilter == 'pending',
                      onTap: () {
                        setState(() => _selectedFilter = 'pending');
                        _filterDebts();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Paid (${_debts.where((d) => d.status == DebtStatus.paid).length})',
                      isSelected: _selectedFilter == 'paid',
                      onTap: () {
                        setState(() => _selectedFilter = 'paid');
                        _filterDebts();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Overdue (${_debts.where((d) => d.isOverdue).length})',
                      isSelected: _selectedFilter == 'overdue',
                      onTap: () {
                        setState(() => _selectedFilter = 'overdue');
                        _filterDebts();
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Debts list
            Expanded(
              child: _filteredDebts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No debts found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add a new debt to get started',
                            style: TextStyle(
                              color: AppColors.textLight,
                            ),
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddDebtScreen(),
            ),
          );
          // Refresh the list when returning from add debt screen
          if (result == true) {
            _loadDebts();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
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
                        debt.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        debt.description,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Due: ${_formatDate(debt.dueDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const Spacer(),
                if (debt.status == DebtStatus.pending) ...[
                  TextButton(
                    onPressed: onMarkAsPaid,
                    child: const Text('Mark as Paid'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ],
            ),
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