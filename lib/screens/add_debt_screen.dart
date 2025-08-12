import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../providers/app_state.dart';
import '../services/notification_service.dart';

class AddDebtScreen extends StatefulWidget {
  final Customer? customer;

  const AddDebtScreen({super.key, this.customer});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  Customer? _selectedCustomer;
  bool _isLoading = false;
  
  // Product selection
  ProductCategory? _selectedCategory;
  Subcategory? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
    
    // Add listener to description controller for real-time validation
    _descriptionController.addListener(() {
      setState(() {}); // Rebuild to show/hide warning icon
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  
  void _onProductSelected(Subcategory product) {
    setState(() {
      _selectedProduct = product;
      _selectedCategory = null;
      // Find the category for this product
      final appState = Provider.of<AppState>(context, listen: false);
      for (final category in appState.categories) {
        if (category.subcategories.any((s) => s.id == product.id)) {
          _selectedCategory = category;
          break;
        }
      }
      // Auto-fill amount and description
      _amountController.text = product.sellingPrice.toString();
      _descriptionController.text = '${product.name} - ${product.description ?? ''}'.trim();
    });
  }





  Future<void> _saveDebt() async {
    if (_formKey.currentState?.validate() == true && _selectedCustomer != null && _selectedProduct != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final appState = Provider.of<AppState>(context, listen: false);
        final amount = double.parse(_amountController.text.replaceAll(',', ''));
        
        final debt = Debt(
          id: appState.generateDebtId(),
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          description: _descriptionController.text.trim(),
          amount: amount,
          type: DebtType.credit,
          status: DebtStatus.pending,
          createdAt: DateTime.now(),
        );

        await appState.addDebt(debt);

        setState(() {
          _isLoading = false;
        });
        
        // Navigate back with result
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error notification
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Error',
          body: 'Failed to add debt: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Debt for ${_selectedCustomer?.name ?? "Customer"}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Selection
            Consumer<AppState>(
              builder: (context, appState, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Product *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          _selectedProduct?.name ?? 'Choose a product',
                          style: TextStyle(
                            color: _selectedProduct != null 
                                ? AppColors.textPrimary 
                                : AppColors.textLight,
                          ),
                        ),
                        subtitle: _selectedProduct != null 
                            ? Text('${_selectedProduct!.sellingPrice} ${_selectedProduct!.sellingPriceCurrency}')
                            : null,
                        children: [
                          // Category selection
                          if (appState.categories.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory?.id,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Categories'),
                                  ),
                                  ...appState.categories.map((category) => DropdownMenuItem(
                                    value: category.id,
                                    child: Text(category.name),
                                  )),
                                ],
                                onChanged: (categoryId) {
                                  setState(() {
                                    _selectedCategory = categoryId != null 
                                        ? appState.categories.firstWhere((c) => c.id == categoryId)
                                        : null;
                                    _selectedProduct = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Product selection
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonFormField<String>(
                              value: _selectedProduct?.id,
                              decoration: const InputDecoration(
                                labelText: 'Product *',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Select a product'),
                                ),
                                ...(_selectedCategory != null 
                                    ? _selectedCategory!.subcategories
                                    : appState.categories.expand((c) => c.subcategories)
                                ).map((product) => DropdownMenuItem(
                                  value: product.id,
                                  child: Text('${product.name} - ${product.sellingPrice} ${product.sellingPriceCurrency}'),
                                )),
                              ],
                              onChanged: (productId) {
                                if (productId != null) {
                                  final product = (_selectedCategory != null 
                                      ? _selectedCategory!.subcategories
                                      : appState.categories.expand((c) => c.subcategories)
                                  ).firstWhere((p) => p.id == productId);
                                  _onProductSelected(product);
                                }
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a product';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Description field (auto-filled from product, but editable)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                helperText: 'Auto-filled from product selection (can be edited)',
              ),
              validator: (value) {
                // Description is now optional since it's auto-filled
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Amount field
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final cleanValue = value.replaceAll(',', '');
                if (double.tryParse(cleanValue) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(cleanValue) <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDebt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add Debt',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 