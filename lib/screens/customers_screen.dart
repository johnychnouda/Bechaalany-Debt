import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/customer.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';
import '../utils/currency_formatter.dart';
import '../services/notification_service.dart';
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
        _filteredCustomers = customers;
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
          title: const Text('Delete Customer'),
          content: debts.isNotEmpty
              ? Text('This customer has ${debts.length} debt(s). Deleting the customer will also delete all associated debts. Are you sure?')
              : const Text('Are you sure you want to delete this customer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await appState.deleteCustomer(customer.id);
                  _filterCustomers(); // Re-filter after deletion
                } catch (e) {
                  if (mounted) {
                    // Show error notification
                    final notificationService = NotificationService();
                    await notificationService.showErrorNotification(
                      title: 'Error',
                      body: 'Failed to delete customer: $e',
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
        // Update filtered customers when app state changes
        if (_filteredCustomers.isEmpty || _filteredCustomers.length != appState.customers.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _filterCustomers();
          });
        }

        final groupedCustomers = _groupCustomersByFirstLetter();
        // final l10n = AppLocalizations.of(context); // Unused variable removed
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).customers),
            backgroundColor: Colors.grey[50],
            elevation: 0,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by customer name or ID',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Customers list
                  Expanded(
                    child: _filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context).noCustomersFound,
                                  style: AppTheme.getDynamicTitle3(context).copyWith(
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context).addNewCustomerToGetStarted,
                                  style: AppTheme.getDynamicCallout(context).copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddCustomerScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Add Customer'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: groupedCustomers.length,
                            itemBuilder: (context, index) {
                              final letter = groupedCustomers.keys.elementAt(index);
                              final customers = groupedCustomers[letter]!;
                              
                              return Column(
                                children: [
                                  // Section header
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Colors.grey[50],
                                    child: Text(
                                      letter,
                                      style: AppTheme.getDynamicTitle2(context).copyWith(
                                        color: Colors.black,
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
              ),
              // Floating Action Button for adding customers
              if (_filteredCustomers.isNotEmpty)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCustomerScreen(),
                        ),
                      );
                    },
                    backgroundColor: Colors.blue[600],
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
    // final l10n = AppLocalizations.of(context); // Unused variable removed
    
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final customerDebts = appState.debts.where((d) => d.customerId == customer.id).toList();
        final totalRemainingDebt = customerDebts.where((d) => !d.isFullyPaid).fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[600]!.withAlpha(26), // 0.1 * 255
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                customer.name.split(' ').map((e) => e[0]).join(''),
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Text(
            customer.name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 17,
              color: Colors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ID: ${customer.id}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    customer.phone,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (customer.email != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.email!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (totalRemainingDebt > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 12,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      CurrencyFormatter.formatAmount(context, totalRemainingDebt),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: IconButton(
            onPressed: () => _showActionSheet(context),
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey[600],
            ),
          ),
          onTap: onView,
        );
      },
    );
  }
  
  void _showActionSheet(BuildContext context) {
    // final l10n = AppLocalizations.of(context); // Unused variable removed
    
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              customer.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).selectAction,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.visibility, color: Colors.blue[600]),
              title: Text(AppLocalizations.of(context).viewDetails),
              onTap: () {
                Navigator.pop(context);
                onView();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text(AppLocalizations.of(context).delete),
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
                child: Text(AppLocalizations.of(context).cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}