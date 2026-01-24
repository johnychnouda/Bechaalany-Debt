import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../providers/app_state.dart';

import '../utils/currency_formatter.dart';
import '../utils/subscription_checker.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with WidgetsBindingObserver {
  List<Customer> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_filterCustomers);
    
    // Listen to AppState changes to refresh customers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addListener(_onAppStateChanged);
      
      // CRITICAL FIX: Initialize filtered customers immediately after adding listener
      if (appState.customers.isNotEmpty) {
        _filterCustomers();
      }
    });
  }
  
  void _onAppStateChanged() {
    if (!mounted) return;
    
    // Ensure filtered customers are always in sync with app state
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Always refresh filtered customers when app state changes
    // This ensures we have the latest data from Firebase streams
    if (appState.customers.isNotEmpty) {
      _filteredCustomers = List.from(appState.customers);
    } else if (appState.customers.isEmpty) {
      _filteredCustomers = [];
    }
    
    _filterCustomers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    
    // Remove AppState listener
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.removeListener(_onAppStateChanged);
    } catch (e) {
      // Context might be disposed already
    }
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _filterCustomers();
    }
  }

  void _filterCustomers() {
    final appState = Provider.of<AppState>(context, listen: false);
    final customers = appState.customers;
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (customers.isEmpty) {
        _filteredCustomers = [];
        return;
      }
      
      if (query.isEmpty) {
        _filteredCustomers = List.from(customers); // Create a new list to avoid reference issues
      } else {
        _filteredCustomers = customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
                 customer.id.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Map<String, List<Customer>> _groupCustomersByFirstLetter() {
    try {
      final grouped = <String, List<Customer>>{};
      
      // Safety check: return empty map if no customers
      if (_filteredCustomers.isEmpty) {
        return grouped;
      }
      
      for (final customer in _filteredCustomers) {
        try {
          final firstLetter = customer.name.isNotEmpty 
              ? customer.name[0].toUpperCase() 
              : '#';
          
          if (!grouped.containsKey(firstLetter)) {
            grouped[firstLetter] = [];
          }
          grouped[firstLetter]!.add(customer);
        } catch (e) {
          // Skip invalid customers
          continue;
        }
      }
      
      // Sort the groups alphabetically
      final sortedKeys = grouped.keys.toList()..sort();
      final sortedMap = <String, List<Customer>>{};
      
      for (final key in sortedKeys) {
        try {
          final customers = grouped[key];
          if (customers != null && customers.isNotEmpty) {
            sortedMap[key] = List.from(customers)..sort((a, b) => a.name.compareTo(b.name));
          }
        } catch (e) {
          // Skip invalid groups
          continue;
        }
      }
      
      return sortedMap;
    } catch (e) {
      // Return empty map if any error occurs
      return <String, List<Customer>>{};
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final debts = appState.debts.where((d) => d.customerId == customer.id).toList();
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Customer', style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
          content: debts.isNotEmpty
              ? Text('This customer has ${debts.length} debt(s). Deleting the customer will also delete all associated debts. Are you sure?', style: TextStyle(color: AppColors.dynamicTextSecondary(context)))
              : Text('Are you sure you want to delete this customer?', style: TextStyle(color: AppColors.dynamicTextSecondary(context))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.dynamicPrimary(context))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await appState.deleteCustomer(customer.id);
                _filterCustomers();
              },
              child: Text('Delete', style: TextStyle(color: AppColors.error)),
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
            // Show loading state while data is being loaded
            if (appState.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            final groupedCustomers = _groupCustomersByFirstLetter();
            final totalCustomers = appState.customers.length;

            
            return Column(
              children: [
                // iOS 18.6 Style Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Customers',
                            style: TextStyle(
                              color: AppColors.dynamicTextPrimary(context),
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCustomers customer${totalCustomers == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // iOS 18.6 Style Search Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.dynamicSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.dynamicBorder(context).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or ID',
                        hintStyle: TextStyle(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.dynamicTextSecondary(context),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(
                        color: AppColors.dynamicTextPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                
                // Customers List
                Expanded(
                  child: _filteredCustomers.isEmpty || groupedCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.dynamicSurface(context),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.dynamicBorder(context).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.people_outline_rounded,
                                  size: 36,
                                  color: AppColors.dynamicTextSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                appState.customers.isEmpty ? 'No customers yet' : 'No customers found',
                                style: TextStyle(
                                  color: AppColors.dynamicTextPrimary(context),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                appState.customers.isEmpty 
                                    ? 'Start by adding your first customer'
                                    : 'Try adjusting your search criteria',
                                style: TextStyle(
                                  color: AppColors.dynamicTextSecondary(context),
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),

                            ],
                          ),
                        )
                      : groupedCustomers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.dynamicSurface(context),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.dynamicBorder(context).withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.people_outline_rounded,
                                      size: 36,
                                      color: AppColors.dynamicTextSecondary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No customers found',
                                    style: TextStyle(
                                      color: AppColors.dynamicTextPrimary(context),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search criteria',
                                    style: TextStyle(
                                      color: AppColors.dynamicTextSecondary(context),
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: groupedCustomers.length,
                              itemBuilder: (context, index) {
                                try {
                                  // Additional safety checks to prevent RangeError
                                  if (groupedCustomers.isEmpty || 
                                      index < 0 || 
                                      index >= groupedCustomers.length) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final keys = groupedCustomers.keys.toList();
                                  if (index >= keys.length) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final letter = keys[index];
                                  final customers = groupedCustomers[letter];
                                  
                                  if (customers == null || customers.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                            
                                  return Column(
                                    children: [
                                      // iOS 18.6 Style Section Header
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                        child: Text(
                                          letter,
                                          style: TextStyle(
                                            color: AppColors.dynamicPrimary(context),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      // Customers in this section
                                      ...customers.map((customer) => _CustomerListTile(
                                        customer: customer,
                                        onDelete: () => _deleteCustomer(customer),
                                        onView: () => _viewCustomerDetails(customer),
                                      )),
                                    ],
                                  );
                                } catch (e) {
                                  // If any error occurs, return empty widget
                                  return const SizedBox.shrink();
                                }
                              },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      // iOS 18.6 Style Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.dynamicPrimary(context).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'customers_fab_hero',
          onPressed: () async {
            final hasAccess = await SubscriptionChecker.checkAccess(context);
            if (hasAccess && mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddCustomerScreen(),
                ),
              );
            }
          },
          backgroundColor: AppColors.dynamicPrimary(context),
          elevation: 0,
          child: const Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _viewCustomerDetails(Customer customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(
          customer: customer,
          showDebtsSection: true,
        ),
      ),
    );
  }
}

class _CustomerListTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _CustomerListTile({
    required this.customer,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Simple calculation: Sum up remaining amounts from debt records
        final customerDebts = appState.debts.where((d) => d.customerId == customer.id).toList();
        final totalRemainingDebt = customerDebts.where((d) => !d.isFullyPaid).fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        // Fix floating-point precision issues by rounding to 2 decimal places
        final roundedTotalRemainingDebt = ((totalRemainingDebt * 100).round() / 100);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dynamicBorder(context).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showCustomerActionSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 8, right: 16, top: 0, bottom: 0),
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary(context).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    () {
                      final initials = customer.name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).join('');
                      // Ensure we always show at least 2 characters, pad with first letter if needed
                      if (initials.isEmpty) return '?';
                      if (initials.length == 1) return initials + initials;
                      return initials.length > 2 ? initials.substring(0, 2) : initials;
                    }(),
                    style: TextStyle(
                      color: AppColors.dynamicPrimary(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 8,
                              color: AppColors.dynamicTextSecondary(context),
                            ),
                            const SizedBox(width: 1),
                            Text(
                              customer.phone,
                              style: TextStyle(
                                color: AppColors.dynamicTextSecondary(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 8,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                          const SizedBox(width: 1),
                          Text(
                            'ID: ${customer.id}',
                            style: TextStyle(
                              color: AppColors.dynamicTextSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (roundedTotalRemainingDebt > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              size: 8,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              CurrencyFormatter.formatAmount(context, roundedTotalRemainingDebt),
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showCustomerActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          customer.name,
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onView();
            },
            child: const Text('View Details'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final confirmed = await _showDeleteConfirmation(context);
              if (confirmed) {
                onDelete();
              }
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }
}