import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../utils/debt_description_utils.dart';
import '../services/notification_service.dart';

// Type-safe class for grouped debt data
class GroupedDebtData {
  final String customerId;
  final String customerName;
  final List<Debt> debts;
  final double totalAmount;
  final double totalPaidAmount;
  final double totalRemainingAmount;
  final int totalDebts;
  final int pendingDebts;
  final int paidDebts;
  final int partiallyPaidDebts;

  const GroupedDebtData({
    required this.customerId,
    required this.customerName,
    required this.debts,
    required this.totalAmount,
    required this.totalPaidAmount,
    required this.totalRemainingAmount,
    required this.totalDebts,
    required this.pendingDebts,
    required this.paidDebts,
    required this.partiallyPaidDebts,
  });

  bool get hasPendingDebts => pendingDebts > 0;
  bool get hasPartiallyPaidDebts => partiallyPaidDebts > 0;
  bool get isAllPaid => paidDebts == totalDebts;
  
  // Customer-level status based on total amounts
  bool get isCustomerFullyPaid => totalPaidAmount >= totalAmount;
  bool get isCustomerPartiallyPaid => totalPaidAmount > 0 && totalPaidAmount < totalAmount;
  bool get isCustomerPending => totalPaidAmount == 0;
}

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<GroupedDebtData> _groupedDebts = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  bool _sortAscending = false; // true = ascending, false = descending
  List<Debt> _previousDebts = []; // Track previous debt state for auto-switching

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

  // Method to determine the appropriate chip based on debt status
  String _determineAppropriateChip(List<Debt> currentDebts) {
    if (currentDebts.isEmpty) return 'All';
    
    // Find the most recently added or modified debt
    final mostRecentDebt = currentDebts.reduce((curr, next) => 
        curr.createdAt.isAfter(next.createdAt) ? curr : next);
    
    // Group debts by customer to determine customer-level status
    final Map<String, List<Debt>> customerDebtsMap = {};
    for (final debt in currentDebts) {
      if (!customerDebtsMap.containsKey(debt.customerId)) {
        customerDebtsMap[debt.customerId] = [];
      }
      customerDebtsMap[debt.customerId]!.add(debt);
    }
    
    // Get the customer status for the most recent debt
    final customerDebts = customerDebtsMap[mostRecentDebt.customerId] ?? [];
    final totalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
    final totalPaidAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
    
    if (totalPaidAmount >= totalAmount) {
      return 'Fully Paid';
    } else if (totalPaidAmount > 0) {
      return 'Partially Paid';
    } else {
      return 'Pending';
    }
  }

  // Method to check if debts have changed and auto-switch chips
  void _checkAndAutoSwitchChips(List<Debt> currentDebts) {
    if (_previousDebts.isEmpty) {
      // First time loading, just update previous debts
      _previousDebts = List.from(currentDebts);
      return;
    }
    
    final hasNewDebts = currentDebts.length > _previousDebts.length;
    final hasDeletedDebts = currentDebts.length < _previousDebts.length;
    final hasStatusChanges = _hasDebtStatusChanges(currentDebts);
    
    // Auto-switch logic for different scenarios
    if (hasNewDebts) {
      // When new debts are added, only auto-switch if we're on 'All' chip
      if (_selectedStatus == 'All') {
        final appropriateChip = _determineAppropriateChip(currentDebts);
        if (appropriateChip != 'All') {
          setState(() {
            _selectedStatus = appropriateChip;
          });
        }
      }
    } else if (hasStatusChanges) {
      // When debt status changes, check if we should switch chips
      if (_selectedStatus == 'All') {
        // If on 'All' chip, check what type of status change occurred
        final hasFullyPaidDebts = _hasFullyPaidDebts(currentDebts);
        final hasPartiallyPaidDebts = _hasPartiallyPaidDebts(currentDebts);
        
        if (hasFullyPaidDebts) {
          setState(() {
            _selectedStatus = 'Fully Paid';
          });
        } else if (hasPartiallyPaidDebts) {
          setState(() {
            _selectedStatus = 'Partially Paid';
          });
        }
      } else {
        // If on a specific chip, check if current selection still has debts
        final currentChipHasDebts = _doesCurrentChipHaveDebts(currentDebts);
        if (!currentChipHasDebts) {
          // Switch back to 'All' if current chip has no debts
          setState(() {
            _selectedStatus = 'All';
          });
        }
      }
    } else if (hasDeletedDebts) {
      // When debts are deleted, check if current chip still has debts
      final currentChipHasDebts = _doesCurrentChipHaveDebts(currentDebts);
      if (!currentChipHasDebts) {
        // Switch back to 'All' if current chip has no debts
        setState(() {
          _selectedStatus = 'All';
        });
      }
    }
    
    // Update previous debts for next comparison
    _previousDebts = List.from(currentDebts);
  }

  // Method to check if any debt statuses have changed
  bool _hasDebtStatusChanges(List<Debt> currentDebts) {
    if (_previousDebts.isEmpty) return false;
    
    // Create maps for easy comparison
    final Map<String, Debt> previousDebtsMap = {
      for (var debt in _previousDebts) debt.id: debt
    };
    
    for (final currentDebt in currentDebts) {
      final previousDebt = previousDebtsMap[currentDebt.id];
      if (previousDebt != null) {
        // Check if status or paid amount has changed
        if (previousDebt.status != currentDebt.status ||
            previousDebt.paidAmount != currentDebt.paidAmount) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Method to check if there are any fully paid debts
  bool _hasFullyPaidDebts(List<Debt> allDebts) {
    // Group debts by customer to determine customer-level status
    final Map<String, List<Debt>> customerDebtsMap = {};
    for (final debt in allDebts) {
      if (!customerDebtsMap.containsKey(debt.customerId)) {
        customerDebtsMap[debt.customerId] = [];
      }
      customerDebtsMap[debt.customerId]!.add(debt);
    }
    
    for (final entry in customerDebtsMap.entries) {
      final customerDebts = entry.value;
      final totalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalPaidAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
      
      if (totalPaidAmount >= totalAmount) {
        return true;
      }
    }
    
    return false;
  }

  // Method to check if there are any partially paid debts
  bool _hasPartiallyPaidDebts(List<Debt> allDebts) {
    // Group debts by customer to determine customer-level status
    final Map<String, List<Debt>> customerDebtsMap = {};
    for (final debt in allDebts) {
      if (!customerDebtsMap.containsKey(debt.customerId)) {
        customerDebtsMap[debt.customerId] = [];
      }
      customerDebtsMap[debt.customerId]!.add(debt);
    }
    
    for (final entry in customerDebtsMap.entries) {
      final customerDebts = entry.value;
      final totalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalPaidAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
      
      if (totalPaidAmount > 0 && totalPaidAmount < totalAmount) {
        return true;
      }
    }
    
    return false;
  }

  // Method to check if the current selected chip has any debts
  bool _doesCurrentChipHaveDebts(List<Debt> allDebts) {
    if (_selectedStatus == 'All') return true;
    
    // Group debts by customer to determine customer-level status
    final Map<String, List<Debt>> customerDebtsMap = {};
    for (final debt in allDebts) {
      if (!customerDebtsMap.containsKey(debt.customerId)) {
        customerDebtsMap[debt.customerId] = [];
      }
      customerDebtsMap[debt.customerId]!.add(debt);
    }
    
    for (final entry in customerDebtsMap.entries) {
      final customerDebts = entry.value;
      final totalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalPaidAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
      
      String customerStatus;
      if (totalPaidAmount >= totalAmount) {
        customerStatus = 'fully paid';
      } else if (totalPaidAmount > 0) {
        customerStatus = 'partially paid';
      } else {
        customerStatus = 'pending';
      }
      
      if (customerStatus == _selectedStatus.toLowerCase()) {
        return true;
      }
    }
    
    return false;
  }

  void _updateFilteredData(List<Debt> allDebts) {
    // Check and auto-switch chips if needed
    _checkAndAutoSwitchChips(allDebts);
    
    final query = _searchController.text.toLowerCase();
    
    // First, group all debts by customer to determine customer-level status
    final Map<String, List<Debt>> customerDebtsMap = {};
    for (final debt in allDebts) {
      if (!customerDebtsMap.containsKey(debt.customerId)) {
        customerDebtsMap[debt.customerId] = [];
      }
      customerDebtsMap[debt.customerId]!.add(debt);
    }
    
    // Determine which customers match the status filter
    final Set<String> matchingCustomerIds = {};
    for (final entry in customerDebtsMap.entries) {
      final customerDebts = entry.value;
      final totalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalPaidAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
      
      String customerStatus;
      if (totalPaidAmount >= totalAmount) {
        customerStatus = 'fully paid';
      } else if (totalPaidAmount > 0) {
        customerStatus = 'partially paid';
      } else {
        customerStatus = 'pending';
      }
      
      final matchesStatus = _selectedStatus == 'All' ||
                           customerStatus == _selectedStatus.toLowerCase();
      
      if (matchesStatus) {
        matchingCustomerIds.add(entry.key);
      }
    }
    
    // Filter debts to only include customers that match the status
    final filteredDebts = allDebts.where((debt) {
      final matchesSearch = debt.customerName.toLowerCase().contains(query) ||
                           debt.description.toLowerCase().contains(query) ||
                           debt.customerId.toLowerCase().contains(query);
      
      return matchesSearch && matchingCustomerIds.contains(debt.customerId);
    }).toList();
    
    // Group debts by customer
    _groupDebtsByCustomer(filteredDebts);
  }

  void _filterDebts() {
    final appState = Provider.of<AppState>(context, listen: false);
    _updateFilteredData(appState.debts);
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
    
    // Sort debts within each group by date and time in descending order (newest first)
    for (final customerDebts in groupedMap.values) {
      customerDebts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    // Convert to list of GroupedDebtData for better type safety
    _groupedDebts = groupedMap.entries.map((entry) {
      final customerDebts = entry.value;
      final totalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalPaidAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
      final totalRemainingAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
      
      // Determine customer-level status
      int pendingDebts, paidDebts, partiallyPaidDebts;
      if (totalPaidAmount >= totalAmount) {
        // All debts are fully paid
        pendingDebts = 0;
        paidDebts = customerDebts.length;
        partiallyPaidDebts = 0;
      } else if (totalPaidAmount > 0) {
        // Customer has some payments but not fully paid
        pendingDebts = 0;
        paidDebts = customerDebts.where((d) => d.isFullyPaid).length;
        partiallyPaidDebts = customerDebts.length - paidDebts;
      } else {
        // No payments made
        pendingDebts = customerDebts.length;
        paidDebts = 0;
        partiallyPaidDebts = 0;
      }
      
      return GroupedDebtData(
        customerId: entry.key,
        customerName: customerDebts.first.customerName,
        debts: customerDebts,
        totalAmount: totalAmount,
        totalPaidAmount: totalPaidAmount,
        totalRemainingAmount: totalRemainingAmount,
        totalDebts: customerDebts.length,
        pendingDebts: pendingDebts,
        paidDebts: paidDebts,
        partiallyPaidDebts: partiallyPaidDebts,
      );
    }).toList();
    
    // Sort grouped debts
    _sortGroupedDebts();
  }

  void _sortGroupedDebts() {
    // Sort by the most recent debt date (newest first by default, oldest first when ascending)
    _groupedDebts.sort((a, b) {
      final aLatestDebt = a.debts.reduce((curr, next) => 
          curr.createdAt.isAfter(next.createdAt) ? curr : next);
      final bLatestDebt = b.debts.reduce((curr, next) => 
          curr.createdAt.isAfter(next.createdAt) ? curr : next);
      
      return _sortAscending 
          ? aLatestDebt.createdAt.compareTo(bLatestDebt.createdAt)  // ascending: oldest first
          : bLatestDebt.createdAt.compareTo(aLatestDebt.createdAt); // descending: newest first
    });
  }

  Future<void> _markAsPaid(Debt debt) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.markDebtAsPaid(debt.id);
    } catch (e) {
      // Show error notification
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'Error',
        body: 'Failed to mark debt as paid: $e',
      );
    }
  }

  Future<void> _deleteDebt(Debt debt) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.deleteDebt(debt.id);
    } catch (e) {
      // Show error notification
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'Error',
        body: 'Failed to delete debt: $e',
      );
    }
  }

  void _exportDebts() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.exportData();
    } catch (e) {
      // Show error notification
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'Export Failed',
        body: 'Failed to export debts: $e',
      );
    }
  }

  String _getEmptyStateMessage() {
    if (_searchController.text.isNotEmpty) {
      return 'No debts found matching "${_searchController.text}"';
    }
    if (_selectedStatus != 'All') {
      return 'No ${_selectedStatus.toLowerCase()} debts found';
    }
    return 'No debts found';
  }

  String _getEmptyStateSubMessage() {
    if (_searchController.text.isNotEmpty) {
      return 'Try adjusting your search terms';
    }
    if (_selectedStatus != 'All') {
      return 'Add some debts or change the status filter';
    }
    return 'Add your first debt to get started';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Update filtered data whenever AppState changes
        _updateFilteredData(appState.debts);

        return Scaffold(
          key: const Key('debts_screen'),
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Debts'),
            backgroundColor: Colors.grey[50],
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                    _sortGroupedDebts();
                  });
                },
                tooltip: 'Sort by date',
              ),
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: _exportDebts,
                tooltip: 'Export debts',
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
                    // Search field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or ID',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Status filter
                    Consumer<AppState>(
                      builder: (context, appState, child) {
                        return SingleChildScrollView(
                          key: ValueKey('filter_chips_${appState.debts.length}_${appState.debts.fold(0, (sum, debt) => sum + (debt.isFullyPaid ? 1 : 0))}'),
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', _selectedStatus == 'All', appState.debts),
                              const SizedBox(width: 8),
                              _buildFilterChip('Pending', _selectedStatus == 'Pending', appState.debts),
                              const SizedBox(width: 8),
                              _buildFilterChip('Partially Paid', _selectedStatus == 'Partially Paid', appState.debts),
                              const SizedBox(width: 8),
                              _buildFilterChip('Fully Paid', _selectedStatus == 'Fully Paid', appState.debts),
                            ],
                          ),
                        );
                      },
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
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getEmptyStateMessage(),
                              style: AppTheme.getDynamicTitle3(context).copyWith(
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getEmptyStateSubMessage(),
                              style: AppTheme.getDynamicCallout(context).copyWith(
                                color: Colors.grey[600],
                              ),
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
                            onMarkAsPaid: _markAsPaid,
                            onDelete: _deleteDebt,
                            onViewCustomer: () {
                              // Navigate to customer details
                              // This would be implemented based on your navigation structure
                            },
                            selectedStatus: _selectedStatus,
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            key: const Key('debts_fab'),
            heroTag: 'debts_fab_hero',
            onPressed: () async {
              await Navigator.pushNamed(context, '/add-debt');
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, List<Debt> allDebts) {
    int count = 0;
    if (label == 'All') {
      count = allDebts.length;
    } else {
      // Group debts by customer to determine customer-level status
      final Map<String, List<Debt>> customerDebtsMap = {};
      for (final debt in allDebts) {
        if (!customerDebtsMap.containsKey(debt.customerId)) {
          customerDebtsMap[debt.customerId] = [];
        }
        customerDebtsMap[debt.customerId]!.add(debt);
      }
      
      for (final entry in customerDebtsMap.entries) {
        final customerDebts = entry.value;
        final totalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
        final totalPaidAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
        
        String customerStatus;
        if (totalPaidAmount >= totalAmount) {
          customerStatus = 'fully paid';
        } else if (totalPaidAmount > 0) {
          customerStatus = 'partially paid';
        } else {
          customerStatus = 'pending';
        }
        
        if (customerStatus == label.toLowerCase()) {
          count++;
        }
      }
    }
    
    return FilterChip(
      key: ValueKey('${label}_${count}_${allDebts.length}'),
      label: Text('$label${count > 0 ? ' ($count)' : ''}'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? label : 'All';
        });
      },
      selectedColor: AppColors.primary.withAlpha(51), // 0.2 * 255
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

}

class _GroupedDebtCard extends StatelessWidget {
  final GroupedDebtData group;
  final Function(Debt) onMarkAsPaid;
  final Function(Debt) onDelete;
  final VoidCallback onViewCustomer;
  final String selectedStatus;

  const _GroupedDebtCard({
    required this.group,
    required this.onMarkAsPaid,
    required this.onDelete,
    required this.onViewCustomer,
    required this.selectedStatus,
  });

  Color _getStatusColor() {
    if (group.isCustomerFullyPaid) {
      return Colors.green; // All paid
    } else if (group.isCustomerPartiallyPaid) {
      return Colors.orange; // Partially paid
    } else {
      return Colors.red; // Pending
    }
  }

  String _getStatusText() {
    if (group.isCustomerFullyPaid) {
      return 'Fully Paid';
    } else if (group.isCustomerPartiallyPaid) {
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
                    color: _getStatusColor().withAlpha(26), // 0.1 * 255
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
                        group.customerName,
                        style: AppTheme.getDynamicCallout(context).copyWith(
                          color: Colors.black,
                        ),
                      ),
                      // Show different subtitle based on filter
                      if (selectedStatus == 'All') ...[
                        Text(
                          group.totalRemainingAmount > 0 
                              ? '${CurrencyFormatter.formatAmount(context, group.totalRemainingAmount)} remaining'
                              : 'All paid',
                          style: TextStyle(
                            color: group.totalRemainingAmount > 0 ? Colors.red[600] : Colors.green[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (selectedStatus == 'Pending') ...[
                        Text(
                          '${group.pendingDebts} pending debt${group.pendingDebts == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (selectedStatus == 'Partially Paid') ...[
                        Text(
                          '${group.partiallyPaidDebts} partially paid debt${group.partiallyPaidDebts == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (selectedStatus == 'Fully Paid') ...[
                        Text(
                          '${group.paidDebts} fully paid debt${group.paidDebts == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withAlpha(26), // 0.1 * 255
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusColor().withAlpha(77), // 0.3 * 255
                    ),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Debt details
            ...group.debts.map((debt) => _buildDebtItem(debt)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtItem(Debt debt) {
    final isFullyPaid = debt.isFullyPaid;
    
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DebtDescriptionUtils.cleanDescription(debt.description),
                    style: AppTheme.getDynamicCallout(context).copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.formatAmount(context, debt.amount),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (debt.paidAmount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${CurrencyFormatter.formatAmount(context, debt.paidAmount)} paid)',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${_formatDate(debt.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isFullyPaid) ...[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => onMarkAsPaid(debt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Mark Paid'),
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => onDelete(debt),
              icon: const Icon(Icons.delete, color: Colors.red),
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    if (group.isCustomerFullyPaid) {
      return Icons.check_circle;
    } else if (group.isCustomerPartiallyPaid) {
      return Icons.payment;
    } else {
      return Icons.pending;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}