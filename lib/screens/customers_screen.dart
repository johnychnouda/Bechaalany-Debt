import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../providers/app_state.dart';

import '../utils/currency_formatter.dart';
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
    
    // Initialize filtered customers with all customers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterCustomers();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
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
    final grouped = <String, List<Customer>>{};
    
    for (final customer in _filteredCustomers) {
      final firstLetter = customer.name.isNotEmpty 
          ? customer.name[0].toUpperCase() 
          : '#';
      
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(customer);
    }
    
    // Sort the groups alphabetically
    final sortedKeys = grouped.keys.toList()..sort();
    final sortedMap = <String, List<Customer>>{};
    
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!..sort((a, b) => a.name.compareTo(b.name));
    }
    
    return sortedMap;
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
            // Ensure filtered customers are always in sync with app state
            if (_filteredCustomers.isEmpty && appState.customers.isNotEmpty) {
              _filteredCustomers = List.from(appState.customers);
            }
            
            // Refresh filtered customers when app state changes (e.g., new customer added)
            if (_filteredCustomers.length != appState.customers.length && _searchController.text.isEmpty) {
              _filteredCustomers = List.from(appState.customers);
            }
            
            final groupedCustomers = _groupCustomersByFirstLetter();
            final totalCustomers = appState.customers.length;
            // final filteredCount = _filteredCustomers.length; // Removed unused variable
            
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
                  child: _filteredCustomers.isEmpty
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
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: groupedCustomers.length,
                          itemBuilder: (context, index) {
                            final letter = groupedCustomers.keys.elementAt(index);
                            final customers = groupedCustomers[letter]!;
                            
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
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddCustomerScreen(),
              ),
            );
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
          showDebtsSection: false,
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
        final customerDebts = appState.debts.where((d) => d.customerId == customer.id).toList();
        final totalRemainingDebt = customerDebts.where((d) => !d.isFullyPaid).fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            leading: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.dynamicPrimary(context).withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  customer.name.split(' ').map((e) => e[0]).join(''),
                  style: TextStyle(
                    color: AppColors.dynamicPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
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
                    if (totalRemainingDebt > 0) ...[
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
                            CurrencyFormatter.formatAmount(context, totalRemainingDebt),
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
            trailing: IconButton(
              onPressed: () => _showActionSheet(context),
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.dynamicTextSecondary(context),
                size: 16,
              ),
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
            ),
            onTap: onView,
          ),
        );
      },
    );
  }
  
  void _showActionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.dynamicSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              customer.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dynamicTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an action',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.visibility, color: AppColors.dynamicPrimary(context)),
              title: Text('View Details', style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                onView();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text('Delete', style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}