import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
      // Filter debts individually based on their own status
      final filteredDebts = debts.where((debt) {
        final matchesSearch = debt.customerName.toLowerCase().contains(query) ||
                             debt.customerId.toLowerCase().contains(query);
        
        // Determine individual debt status
        String debtStatus;
        if (debt.isFullyPaid) {
          debtStatus = 'fully paid';
        } else if (debt.isPartiallyPaid) {
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
    // Get all debts from the app state to check for partially paid debts
    final appState = Provider.of<AppState>(context, listen: false);
    final allDebts = appState.debts;
    
    // Group debts by customer
    final Map<String, List<Debt>> customerDebtsMap = {};
    
    for (final debt in debts) {
      final customerKey = debt.customerId;
      
      if (!customerDebtsMap.containsKey(customerKey)) {
        customerDebtsMap[customerKey] = [];
      }
      
      customerDebtsMap[customerKey]!.add(debt);
    }
    
    _groupedDebts = [];
    
    for (final entry in customerDebtsMap.entries) {
      final customerDebts = entry.value;
      final customerId = entry.key;
      
      // Skip customers with no debts
      if (customerDebts.isEmpty) continue;
      
      // Get ALL debts for this customer (not just filtered ones) to check status
      final allCustomerDebts = allDebts.where((d) => d.customerId == customerId).toList();
      
      // Categorize debts by status
      final pendingDebts = customerDebts.where((d) => !d.isPartiallyPaid && !d.isFullyPaid).toList();
      final partiallyPaidDebts = customerDebts.where((d) => d.isPartiallyPaid).toList();
      final fullyPaidDebts = customerDebts.where((d) => d.isFullyPaid).toList();
      
      // Check if customer has ANY partially paid debts in the entire system
      final hasPartiallyPaidDebts = allCustomerDebts.any((d) => d.isPartiallyPaid);
      
      // PHASE 1: PENDING PHASE - Customer has no partial payments yet
      // Show grouped pending card (combines all pending debts)
      // Only show pending grouped card if there are NO partially paid debts for this customer
      // AND we're on the "Pending" or "All" filter
      if (pendingDebts.isNotEmpty && 
          !hasPartiallyPaidDebts && 
          (_selectedStatus == 'Pending' || _selectedStatus == 'All')) {
        final totalAmount = pendingDebts.fold(0.0, (sum, debt) => sum + debt.amount);
        final totalRemainingAmount = pendingDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        
        _groupedDebts.add({
          'customerId': pendingDebts.first.customerId,
          'customerName': pendingDebts.first.customerName,
          'debts': pendingDebts,
          'totalAmount': totalAmount,
          'totalPaidAmount': 0.0,
          'totalRemainingAmount': totalRemainingAmount,
          'totalDebts': pendingDebts.length,
          'pendingDebts': pendingDebts.length,
          'paidDebts': 0,
          'partiallyPaidDebts': 0,
          'isGrouped': true,
        });
      }
      
      // PHASE 2: PARTIALLY PAID PHASE - Customer has made partial payments
      // Show ONE grouped card for all partially paid debts (combines all active debts)
      if (partiallyPaidDebts.isNotEmpty || (_selectedStatus == 'Partially Paid' && hasPartiallyPaidDebts)) {
        // If we're on "Partially Paid" filter, use all customer debts
        // Otherwise, combine partially paid debts and any new pending debts
        final allActiveDebts = _selectedStatus == 'Partially Paid' 
            ? allCustomerDebts.where((d) => d.isPartiallyPaid || (!d.isFullyPaid && d.paidAmount == 0)).toList()
            : [...partiallyPaidDebts, ...pendingDebts];
        
        // Calculate totals for the grouped card
        final totalAmount = allActiveDebts.fold(0.0, (sum, debt) => sum + debt.amount);
        final totalPaidAmount = allActiveDebts.fold(0.0, (sum, debt) => sum + debt.paidAmount);
        final totalRemainingAmount = allActiveDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        
        _groupedDebts.add({
          'customerId': allActiveDebts.first.customerId,
          'customerName': allActiveDebts.first.customerName,
          'debts': allActiveDebts,
          'totalAmount': totalAmount,
          'totalPaidAmount': totalPaidAmount,
          'totalRemainingAmount': totalRemainingAmount,
          'totalDebts': allActiveDebts.length,
          'pendingDebts': allActiveDebts.where((d) => d.paidAmount == 0).length,
          'paidDebts': 0,
          'partiallyPaidDebts': allActiveDebts.where((d) => d.paidAmount > 0 && !d.isFullyPaid).length,
          'isGrouped': true,
        });
      }
      
      // PHASE 3: FULLY PAID PHASE - Show ONE grouped card for all fully paid debts
      // ONLY if customer has NO remaining debts
      if (fullyPaidDebts.isNotEmpty) {
        // Check if customer has any remaining debts (pending or partially paid)
        final hasRemainingDebts = allCustomerDebts.any((d) => !d.isFullyPaid);
        
        // Only show fully paid card if customer has NO remaining debts
        if (!hasRemainingDebts) {
          // Calculate totals for the grouped fully paid card
          final totalAmount = fullyPaidDebts.fold(0.0, (sum, debt) => sum + debt.amount);
          final totalPaidAmount = fullyPaidDebts.fold(0.0, (sum, debt) => sum + debt.paidAmount);
          final totalRemainingAmount = fullyPaidDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
          
          _groupedDebts.add({
            'customerId': fullyPaidDebts.first.customerId,
            'customerName': fullyPaidDebts.first.customerName,
            'debts': fullyPaidDebts,
            'totalAmount': totalAmount,
            'totalPaidAmount': totalPaidAmount,
            'totalRemainingAmount': totalRemainingAmount,
            'totalDebts': fullyPaidDebts.length,
            'pendingDebts': 0,
            'paidDebts': fullyPaidDebts.length,
            'partiallyPaidDebts': 0,
            'isGrouped': true,
          });
        }
      }
    }
    
    // Sort grouped debts
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
    
    // Allow deletion of any debt (including those with partial payments)
    // This gives users full control over their debt management
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        String warningMessage = '';
        if (debt.paidAmount > 0) {
          warningMessage = '\n\n⚠️ WARNING: This debt has partial payments (${CurrencyFormatter.formatAmount(context, debt.paidAmount, storedCurrency: debt.storedCurrency)}). Deleting it will remove all payment history for this debt.';
        }
        
        // Format the amount properly using stored currency
        final formattedAmount = CurrencyFormatter.formatAmount(
          context, 
          debt.amount, 
          storedCurrency: debt.storedCurrency
        );
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Delete Debt'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this debt?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debt Details:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Customer: ${debt.customerName}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Amount: $formattedAmount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (warningMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withAlpha(77)),
                  ),
                  child: Text(
                    warningMessage.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                '⚠️ This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            return Column(
              children: [
                // Search and Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or ID',
                          hintStyle: TextStyle(color: AppColors.dynamicTextSecondary(context)),
                          prefixIcon: Icon(Icons.search, color: AppColors.dynamicTextSecondary(context)),
                          filled: true,
                          fillColor: AppColors.dynamicSurface(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.dynamicBorder(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.dynamicBorder(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.dynamicPrimary(context), width: 2),
                          ),
                        ),
                        style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
                      ),
                      const SizedBox(height: 12),
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Pending', 'Partially Paid', 'Fully Paid'].map((status) {
                            final isSelected = _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  status,
                                  style: TextStyle(
                                    color: isSelected 
                                        ? (status == 'Pending' 
                                            ? Colors.white 
                                            : status == 'Partially Paid' 
                                                ? Colors.white 
                                                : status == 'Fully Paid' 
                                                    ? Colors.white 
                                                    : Colors.white)
                                        : AppColors.dynamicTextPrimary(context),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = status;
                                  });
                                  _filterDebts();
                                },
                                backgroundColor: isSelected 
                                    ? (status == 'Pending' 
                                        ? Colors.red[700] 
                                        : status == 'Partially Paid' 
                                            ? Colors.orange[700] 
                                            : status == 'Fully Paid' 
                                                ? Colors.green[700] 
                                                : AppColors.dynamicPrimary(context))
                                    : AppColors.dynamicSurface(context),
                                selectedColor: isSelected 
                                    ? (status == 'Pending' 
                                        ? Colors.red[700] 
                                        : status == 'Partially Paid' 
                                            ? Colors.orange[700] 
                                            : status == 'Fully Paid' 
                                                ? Colors.green[700] 
                                                : AppColors.dynamicPrimary(context))
                                    : AppColors.dynamicSurface(context),
                                checkmarkColor: isSelected 
                                    ? (status == 'Pending' 
                                        ? Colors.white 
                                        : status == 'Partially Paid' 
                                            ? Colors.white 
                                            : status == 'Fully Paid' 
                                                ? Colors.white 
                                                : Colors.white)
                                    : AppColors.dynamicPrimary(context),
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
                              Icon(
                                Icons.account_balance_wallet_outlined, 
                                size: 64, 
                                color: AppColors.dynamicTextSecondary(context)
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getEmptyStateMessage(),
                                style: TextStyle(
                                  color: AppColors.dynamicTextPrimary(context), 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w600
                                )
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getEmptyStateSubMessage(),
                                style: TextStyle(color: AppColors.dynamicTextSecondary(context))
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
                              onRefresh: _filterDebts,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'debts_fab_hero',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDebtFromProductScreen(),
            ),
          );
        },
        backgroundColor: AppColors.dynamicPrimary(context),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  // Simple direct function for web testing
  void _openReceiptDirectly(String customerId, Debt specificDebt) async {
    try {
      print('=== _openReceiptDirectly called ===');
      print('Customer ID: $customerId');
      print('Debt ID: ${specificDebt.id}');
      
      // First, just try to show a simple message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attempting to open receipt for customer: $customerId'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Wait a moment
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Now try to get the app state
      print('Getting app state...');
      final appState = Provider.of<AppState>(context, listen: false);
      print('App state obtained successfully');
      
      // Try to find customer
      print('Looking for customer...');
      final customer = appState.customers.firstWhere((c) => c.id == customerId);
      print('Customer found: ${customer.name}');
      
      // Get basic data
      final allCustomerDebts = appState.debts.where((d) => d.customerId == customerId).toList();
      final customerPartialPayments = appState.partialPayments.where((p) => p.debtId == specificDebt.id).toList();
      
      print('Customer debts count: ${allCustomerDebts.length}');
      print('Partial payments count: ${customerPartialPayments.length}');
      print('Activities count: ${appState.activities.length}');
      
      // Show success message for data retrieval
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data retrieved successfully! Now attempting navigation...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Wait a moment
      await Future.delayed(Duration(milliseconds: 1000));
      
      print('Attempting to navigate to receipt screen...');
      
      // Try to open the receipt screen with minimal navigation
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CustomerDebtReceiptScreen(
            customer: customer,
            customerDebts: allCustomerDebts,
            partialPayments: customerPartialPayments,
            activities: appState.activities,
            specificDebtId: specificDebt.id,
          ),
        ),
      );
      
      print('Navigation successful! Result: $result');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt opened successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
      
    } catch (e) {
      print('=== ERROR in _openReceiptDirectly ===');
      print('Error details: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      
      // Show detailed error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open receipt: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 10),
        ),
      );
    }
  }

  void _viewCustomerDetails(String customerId, Debt specificDebt) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final customer = appState.customers.firstWhere((c) => c.id == customerId);
      
      // Get all debts for this customer to show in receipt
      final allCustomerDebts = appState.debts.where((d) => d.customerId == customerId).toList();
      
      // Include ALL partial payments for this customer, not just those linked to existing debts
      // This ensures partial payments are shown even if debts were cleared or there are ID mismatches
      final customerPartialPayments = appState.partialPayments.where((p) {
        // First try to find the debt this payment was made for
        final linkedDebt = appState.debts.firstWhere(
          (d) => d.id == p.debtId,
          orElse: () {
            return Debt(
              id: p.debtId,
              customerId: customerId,
              customerName: customer.name,
              amount: 0,
              description: 'Unknown Product',
              type: DebtType.credit,
              status: DebtStatus.pending,
              createdAt: p.paidAt,
              subcategoryId: null,
              subcategoryName: null,
              originalSellingPrice: null,
              originalCostPrice: null,
              categoryName: null,
              storedCurrency: 'USD',
            );
          },
        );
        
        // Include the payment if it's for this customer
        return linkedDebt.customerId == customerId;
      }).toList();
      
      // Test with a simple dialog first to see if navigation works
      if (kIsWeb) {
        // For web, show a simple dialog first to test navigation
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Test Navigation'),
              content: Text('Navigation is working. Now trying to open receipt...'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        
        // Wait a bit then try to open the receipt
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      // Try to open the receipt screen
      try {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CustomerDebtReceiptScreen(
              customer: customer,
              customerDebts: allCustomerDebts,
              partialPayments: customerPartialPayments,
              activities: appState.activities,
              specificDebtId: specificDebt.id,
            ),
            fullscreenDialog: false,
          ),
        );
        
        if (kIsWeb) {
          // Show success message for web
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Receipt opened successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Show detailed error for debugging
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Navigation Error',
          body: 'Failed to open receipt: $e\n\nCustomer: ${customer.name}\nDebt ID: ${specificDebt.id}',
        );
        
        // Also show in console for debugging
        print('Navigation error: $e');
        print('Customer: ${customer.name}');
        print('Debt ID: ${specificDebt.id}');
        print('Customer debts count: ${allCustomerDebts.length}');
        print('Partial payments count: ${customerPartialPayments.length}');
        print('Activities count: ${appState.activities.length}');
      }
      
      // Force refresh of debt history when returning from receipt
      if (mounted) {
        _filterDebts();
      }
    } catch (e) {
      // Show error notification if navigation fails
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'Navigation Error',
        body: 'Failed to open receipt: $e',
      );
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
  final VoidCallback onRefresh;

  const _GroupedDebtCard({
    required this.group,
    required this.onMarkAsPaid,
    required this.onDelete,
    required this.onViewCustomer,
    required this.selectedStatus,
    required this.onRefresh,
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
      return ''; // Remove "remaining" status text
    } else {
      return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.dynamicSurface(context),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group['customerName'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: AppColors.dynamicTextPrimary(context),
                                        ),
                                        overflow: TextOverflow.clip,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Amount on the same line as customer name
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
                Icon(Icons.calendar_today, size: 16, color: AppColors.dynamicTextSecondary(context)),
                const SizedBox(width: 8),
                Text(
                  'Latest: ${_formatDate(_getLatestActivityDate())}',
                  style: TextStyle(
                    color: AppColors.dynamicTextSecondary(context),
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
                        backgroundColor: AppColors.dynamicPrimary(context),
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
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Super simple test - just show a basic dialog
                      print('=== View Receipt button clicked! ===');
                      print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
                      
                      // Show a simple test dialog first
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Test Dialog'),
                            content: Text('Button click is working! Platform: ${kIsWeb ? "Web" : "Mobile"}'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Close'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: const Text('View Receipt'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dynamicPrimary(context),
                      side: BorderSide(color: AppColors.dynamicPrimary(context)),
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
    final isGrouped = group['isGrouped'] as bool? ?? false;
    
    if (debts.isEmpty) return '';
    
    if (isGrouped && debts.length > 1) {
      // For grouped debts, check if all are fully paid
      final allFullyPaid = debts.every((debt) => debt.isFullyPaid);
      
      if (allFullyPaid) {
        // For fully paid grouped debts, show total amount paid
        final totalAmount = debts.fold(0.0, (sum, debt) => sum + debt.amount);
        return '${CurrencyFormatter.formatAmount(context, totalAmount)} paid';
      } else {
        // For partially paid grouped debts, show remaining amount
        final totalRemainingAmount = debts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        return 'Remaining: ${CurrencyFormatter.formatAmount(context, totalRemainingAmount)}';
      }
    } else {
      // Show individual debt amount
      final debt = debts.first;
      if (debt.isFullyPaid) {
        return '${CurrencyFormatter.formatAmount(context, debt.amount, storedCurrency: debt.storedCurrency)} paid';
      } else if (debt.paidAmount > 0) {
        return 'Remaining: ${CurrencyFormatter.formatAmount(context, debt.remainingAmount, storedCurrency: debt.storedCurrency)}';
      } else {
        // For new debts with no payments, show just the amount
        return '${CurrencyFormatter.formatAmount(context, debt.amount, storedCurrency: debt.storedCurrency)}';
      }
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
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                final amount = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0;
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
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Use the new method that creates a single payment activity
    final debtIds = unpaidDebts.map((debt) => debt.id).toList();
    await appState.applyPaymentAcrossDebts(debtIds, paymentAmount);
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
                    _clearCompletedDebts(context, completedDebts, group['customerName'] as String, onRefresh);
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

  void _clearCompletedDebts(BuildContext context, List<Debt> completedDebts, String customerName, VoidCallback onRefresh) async {
    final appState = Provider.of<AppState>(context, listen: false);
    for (final debt in completedDebts) {
      await appState.deleteDebt(debt.id);
    }
    
    // Refresh the filtered data after deletion
    onRefresh();
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