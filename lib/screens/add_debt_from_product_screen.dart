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
import '../widgets/searchable_customer_field.dart';

class AddDebtFromProductScreen extends StatefulWidget {
  final Customer? customer; // Optional customer parameter
  
  const AddDebtFromProductScreen({
    super.key,
    this.customer,
  });

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
  void initState() {
    super.initState();
    // If a customer was passed, pre-select it
    if (widget.customer != null) {
      _selectedCustomer = widget.customer;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      appBar: AppBar(
        title: Text('Add Debt from Product', style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
        backgroundColor: AppColors.dynamicSurface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.dynamicPrimary(context)),
        titleTextStyle: TextStyle(
          color: AppColors.dynamicTextPrimary(context),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Selection
                if (widget.customer != null) ...[
                  // Show pre-selected customer (read-only)
                  Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPreSelectedCustomer(widget.customer!),
                ] else ...[
                  // Show customer search field
                  SearchableCustomerField(
                    selectedCustomer: _selectedCustomer,
                    customers: appState.customers,
                    onCustomerSelected: (customer) {
                      setState(() {
                        _selectedCustomer = customer;
                      });
                    },
                    label: 'Customer',
                    placeholder: 'Search by name or ID',
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Category Selection
                _buildExpandableCategorySelection(appState),
                
                const SizedBox(height: 24),
                
                // Product Selection
                _buildExpandableSubcategorySelection(appState),
                
                const SizedBox(height: 24),
                
                // Product Details
                _buildProductDetails(),
                
                const SizedBox(height: 32),
                
                // Add Debt Button
                _buildAddDebtButton(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreSelectedCustomer(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context).withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dynamicBorder(context).withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: AppColors.dynamicPrimary(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              customer.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.dynamicTextPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCategorySelection(AppState appState) {
    final categories = appState.categories.whereType<ProductCategory>().toList();
    
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withAlpha(77)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No categories available',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'You need to add categories and products first. Go to the Products tab to create categories and products.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
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
    final subcategories = _selectedCategory?.subcategories ?? [];
    
    if (_selectedCategory != null && subcategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withAlpha(77)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No products in ${_selectedCategory!.name}',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Add products to this category in the Products tab.',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ExpandableChipDropdown<Subcategory>(
      label: 'Product',
      value: _selectedSubcategory,
      items: subcategories,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.dynamicBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedSubcategory != null) ...[
                // Product Name with larger, more prominent display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicPrimary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dynamicPrimary(context).withAlpha(51)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 24,
                        color: AppColors.dynamicPrimary(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedSubcategory!.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Category and Price in a clean layout
                Row(
                  children: [
                    // Category Info
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dynamicSurface(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.dynamicBorder(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 16,
                                  color: AppColors.dynamicTextSecondary(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dynamicTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedCategory?.name ?? 'Not selected',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dynamicTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Unit Price
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dynamicSuccess(context).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.dynamicSuccess(context).withAlpha(51)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 16,
                                  color: AppColors.dynamicSuccess(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Unit Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dynamicSuccess(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatProductPrice(context, _selectedSubcategory!.sellingPrice, storedCurrency: _selectedSubcategory!.sellingPriceCurrency),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dynamicSuccess(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // No Product Selected State - More helpful
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicWarning(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dynamicWarning(context).withAlpha(51)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.dynamicWarning(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No Product Selected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please select a category and product above to see product details and pricing information.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.dynamicTextSecondary(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter quantity',
            hintStyle: TextStyle(color: AppColors.dynamicTextSecondary(context)),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildTotalAmount() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final unitPrice = _selectedSubcategory?.sellingPrice ?? 0.0;
    final totalAmount = quantity * unitPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicPrimary(context).withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.dynamicTextPrimary(context),
            ),
          ),
          Text(
            CurrencyFormatter.formatProductPrice(context, totalAmount, storedCurrency: _selectedSubcategory?.sellingPriceCurrency),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDebtButton() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final unitPrice = _selectedSubcategory?.sellingPrice ?? 0.0;
    final totalAmount = quantity * unitPrice;
    final isValid = _selectedCustomer != null && _selectedSubcategory != null && totalAmount > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !_isLoading ? _addDebt : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? AppColors.dynamicPrimary(context) : AppColors.dynamicTextSecondary(context),
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
      final quantity = double.tryParse(_quantityController.text.replaceAll(',', '')) ?? 1.0;
      
      // Convert LBP amount to USD for debt storage
      final settings = appState.currencySettings;
      double totalAmount;
      
      if (_selectedSubcategory!.sellingPriceCurrency == 'LBP' && settings != null && settings.exchangeRate != null) {
        // Convert LBP to USD using current exchange rate
        totalAmount = (_selectedSubcategory!.sellingPrice * quantity) / settings.exchangeRate!;
      } else {
        // Already in USD or no exchange rate available
        totalAmount = _selectedSubcategory!.sellingPrice * quantity;
      }
      
      // Create description with quantity if > 1
      String description = _selectedSubcategory!.name;
      if (quantity > 1) {
        // Format quantity to show decimals only if needed
        final quantityText = quantity == quantity.toInt() 
            ? quantity.toInt().toString() 
            : quantity.toStringAsFixed(2);
        description = '${_selectedSubcategory!.name} (Qty: $quantityText)';
      }
      
      final debt = Debt(
        id: appState.generateDebtId(),
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        amount: totalAmount,
        description: description,
        type: DebtType.credit,
        status: DebtStatus.pending,
        createdAt: DateTime.now(),
        subcategoryId: _selectedSubcategory!.id,
        subcategoryName: _selectedSubcategory!.name,
        originalSellingPrice: _selectedSubcategory!.sellingPrice,
        originalCostPrice: _selectedSubcategory!.costPrice, // CRITICAL: Store original cost for revenue calculation
        categoryName: _selectedCategory!.name,
        storedCurrency: _selectedSubcategory!.sellingPriceCurrency, // Store the original currency
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