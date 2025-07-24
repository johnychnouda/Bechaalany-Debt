import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../services/data_service.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final DataService _dataService = DataService();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
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
    _loadCustomers();
  }

  void _loadCustomers() {
    setState(() {
      _customers = _dataService.customers;
      _filteredCustomers = _customers;
    });
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
                 customer.phone.toLowerCase().contains(query) ||
                 (customer.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final debts = _dataService.getDebtsByCustomer(customer.id);
    
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
                  await _dataService.deleteCustomer(customer.id);
                  _loadCustomers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customer deleted successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete customer: $e'),
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
        title: const Text('Customers'),
        actions: [
          IconButton(
            onPressed: () {
              _loadCustomers();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadCustomers();
        },
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
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
            // Customers list
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textLight),
                          SizedBox(height: 16),
                          Text('No customers found', style: TextStyle(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text('Add a new customer to get started', style: TextStyle(color: AppColors.textLight)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return _CustomerCard(
                          customer: customer,
                          onDelete: () => _deleteCustomer(customer),
                          onEdit: () => _editCustomer(customer),
                          onView: () => _viewCustomerDetails(customer),
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
              builder: (context) => const AddCustomerScreen(),
            ),
          );
          // Refresh the list when returning from add customer screen
          if (result == true) {
            _loadCustomers();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),
      ),
    );
  }

  void _editCustomer(Customer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(customer: customer),
      ),
    );
    if (result == true) {
      _loadCustomers();
    }
  }

  void _viewCustomerDetails(Customer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customer: customer),
      ),
    );
    // Refresh when returning from customer details
    if (result == true) {
      _loadCustomers();
    }
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const _CustomerCard({
    required this.customer,
    required this.onDelete,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    final customerDebts = dataService.getDebtsByCustomer(customer.id);
    final totalDebt = customerDebts.where((d) => d.status == DebtStatus.pending).fold(0.0, (sum, debt) => sum + debt.amount);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            customer.name.split(' ').map((e) => e[0]).join(''),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              customer.phone,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (customer.email != null) ...[
              const SizedBox(height: 2),
              Text(
                customer.email!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Total Debt: \$${totalDebt.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                onView();
                break;
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
        ),
        onTap: onView,
      ),
    );
  }
} 