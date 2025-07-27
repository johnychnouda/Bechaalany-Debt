import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../services/notification_service.dart';
import '../widgets/expandable_chip_dropdown.dart';

class AddDebtFromProductScreen extends StatefulWidget {
  const AddDebtFromProductScreen({super.key});

  @override
  State<AddDebtFromProductScreen> createState() => _AddDebtFromProductScreenState();
}

class _AddDebtFromProductScreenState extends State<AddDebtFromProductScreen> {
  Customer? _selectedCustomer;
  ProductCategory? _selectedCategory;
  Subcategory? _selectedSubcategory;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Debt from Product'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Selection
                const Text(
                  'Customer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildExpandableCustomerSelection(appState),
                
                const SizedBox(height: 16),
                
                // Category Selection
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildExpandableCategorySelection(appState),
                
                const SizedBox(height: 16),
                
                // Product Selection
                const Text(
                  'Product',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildExpandableSubcategorySelection(appState),
                
                const SizedBox(height: 16),
                
                // Product Details
                const Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildProductDetails(),
                
                const SizedBox(height: 16),
                
                // Add Debt Button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selectedCustomer != null && _selectedSubcategory != null && !_isLoading) ? _addDebt : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_selectedCustomer != null && _selectedSubcategory != null) ? AppColors.primary : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Add Debt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16), // Bottom padding for the button
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandableCustomerSelection(AppState appState) {
    if (appState.customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(26), // 0.1 * 255
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withAlpha(77)), // 0.3 * 255
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No customers available. Please add customers first.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return ExpandableChipDropdown<Customer>(
      label: 'Customer',
      value: _selectedCustomer,
      items: appState.customers,
      itemToString: (customer) => customer.name,
      onChanged: (customer) {
        setState(() {
          _selectedCustomer = customer;
        });
      },
      placeholder: 'Select Customer',
    );
  }

  Widget _buildExpandableCategorySelection(AppState appState) {
    final categories = appState.categories.whereType<ProductCategory>().toList();
    
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(26), // 0.1 * 255
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withAlpha(77)), // 0.3 * 255
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No categories available. Please add categories first.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return ExpandableChipDropdown<ProductCategory>(
      label: 'Category',
      value: _selectedCategory,
      items: categories,
      itemToString: (category) => category.name,
      onChanged: (category) {
        setState(() {
          _selectedCategory = category;
          _selectedSubcategory = null;
        });
      },
      placeholder: 'Select Category',
    );
  }

  Widget _buildExpandableSubcategorySelection(AppState appState) {
    return ExpandableChipDropdown<Subcategory>(
      label: 'Product',
      value: _selectedSubcategory,
      items: _selectedCategory?.subcategories ?? [],
      itemToString: (subcategory) => subcategory.name,
      onChanged: (subcategory) {
        setState(() {
          _selectedSubcategory = subcategory;
        });
      },
      placeholder: 'Select Product',
      enabled: _selectedCategory != null,
    );
  }



  Widget _buildProductDetails() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final totalAmount = _selectedSubcategory?.sellingPrice ?? 0;
    final calculatedTotal = totalAmount * quantity;

    return Column(
      children: [
        // Product Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSubcategory?.name ?? 'No product selected',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${_selectedCategory?.name ?? "Not selected"}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        'Unit Price',
                        _selectedSubcategory != null 
                            ? CurrencyFormatter.formatAmount(context, _selectedSubcategory!.sellingPrice)
                            : '0.00 USD',
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quantity Input
        TextField(
          controller: _quantityController,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
            hintText: '1',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              // Trigger rebuild to update total
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Total Amount Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26), // 0.1 * 255
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(77)), // 0.3 * 255
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _selectedSubcategory != null 
                    ? CurrencyFormatter.formatAmount(context, calculatedTotal)
                    : '0.00 USD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedSubcategory != null ? AppColors.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 * 255
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)), // 0.3 * 255
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addDebt() async {
    if (_selectedCustomer == null || _selectedSubcategory == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final totalAmount = _selectedSubcategory!.sellingPrice * quantity;
      
      final debt = Debt(
        id: appState.generateDebtId(),
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        amount: totalAmount,
        description: '${_selectedSubcategory!.name} (${_selectedCategory!.name})',
        type: DebtType.credit,
        status: DebtStatus.pending,
        createdAt: DateTime.now(),
      );

      await appState.addDebt(debt);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Show error notification
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Error',
          body: 'Failed to add debt: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 