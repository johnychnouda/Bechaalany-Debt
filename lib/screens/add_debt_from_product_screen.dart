import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';

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
                _buildCustomerSelection(appState),
                
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
                _buildCategorySelection(appState),
                
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
                _buildSubcategorySelection(appState),
                
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



  Widget _buildCustomerSelection(AppState appState) {
    if (appState.customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<Customer?>(
        value: _selectedCustomer,
        decoration: const InputDecoration(
          labelText: 'Select Customer',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
        ),
        items: [
          const DropdownMenuItem<Customer?>(
            value: null,
            child: Text('None'),
          ),
          ...appState.customers.map((customer) {
            return DropdownMenuItem<Customer?>(
              value: customer,
              child: Text(customer.name),
            );
          }).toList(),
        ],
        onChanged: (Customer? customer) {
          setState(() {
            _selectedCustomer = customer;
          });
        },
      ),
    );
  }

  Widget _buildCategorySelection(AppState appState) {
    final categories = appState.categories.where((cat) => cat is ProductCategory).cast<ProductCategory>().toList();
    
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<ProductCategory?>(
        value: _selectedCategory,
        decoration: const InputDecoration(
          labelText: 'Select Category',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
        ),
        items: [
          const DropdownMenuItem<ProductCategory?>(
            value: null,
            child: Text('None'),
          ),
          ...categories.map((category) {
            return DropdownMenuItem<ProductCategory?>(
              value: category,
              child: Text(category.name),
            );
          }).toList(),
        ],
        onChanged: (ProductCategory? category) {
          setState(() {
            _selectedCategory = category;
            _selectedSubcategory = null; // Reset subcategory when category changes
          });
        },
      ),
    );
  }

  Widget _buildSubcategorySelection(AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<Subcategory?>(
        value: _selectedSubcategory,
        decoration: const InputDecoration(
          labelText: 'Select Product',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
        ),
        items: [
          const DropdownMenuItem<Subcategory?>(
            value: null,
            child: Text('None'),
          ),
          if (_selectedCategory != null) ...[
            ..._selectedCategory!.subcategories.map((subcategory) {
              return DropdownMenuItem<Subcategory?>(
                value: subcategory,
                child: Text(subcategory.name),
              );
            }).toList(),
          ],
        ],
        onChanged: (Subcategory? subcategory) {
          setState(() {
            _selectedSubcategory = subcategory;
          });
        },
      ),
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
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
                    _selectedSubcategory!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${_selectedCategory!.name}',
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
                          CurrencyFormatter.formatAmount(context, _selectedSubcategory!.sellingPrice),
                          AppColors.primary,
                        ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                                              child: _buildInfoChip(
                          'Profit',
                          CurrencyFormatter.formatAmount(context, _selectedSubcategory!.profit),
                          AppColors.success,
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
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
                CurrencyFormatter.formatAmount(context, totalAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
        description: '${_selectedSubcategory!.name} (${_selectedCategory!.name}) - Qty: $quantity',
        type: DebtType.credit,
        status: DebtStatus.pending,
        createdAt: DateTime.now(),
      );

      await appState.addDebt(debt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debt added successfully for ${_selectedCustomer!.name}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add debt: $e'),
            backgroundColor: AppColors.error,
          ),
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