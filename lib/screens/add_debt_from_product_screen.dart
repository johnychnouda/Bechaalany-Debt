import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
// Notification service import removed
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
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: const Text(
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
            const SizedBox(height: 8),
            const Text(
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dynamicBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedSubcategory != null) ...[
                // Product Name
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: AppColors.dynamicTextSecondary(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedSubcategory!.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dynamicTextPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Category and Price - simplified design
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.dynamicTextSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCategory?.name ?? 'Not selected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Unit Price',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.dynamicTextSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatProductPrice(context, _selectedSubcategory!.sellingPrice, storedCurrency: _selectedSubcategory!.sellingPriceCurrency),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dynamicSuccess(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                Divider(
                  color: AppColors.dynamicBorder(context),
                  height: 1,
                ),
                const SizedBox(height: 16),
                
                // Quantity and Total Amount in a clean row
                Builder(
                  builder: (context) {
                    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '')) ?? 1.0;
                    final unitPrice = _selectedSubcategory!.sellingPrice;
                    final totalAmount = quantity * unitPrice;
                    final currency = _selectedSubcategory!.sellingPriceCurrency;
                    
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.dynamicTextSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dynamicTextPrimary(context),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '1',
                                    hintStyle: TextStyle(
                                      color: AppColors.dynamicTextSecondary(context),
                                      fontSize: 16,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.dynamicBackground(context),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppColors.dynamicBorder(context)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppColors.dynamicBorder(context)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppColors.dynamicPrimary(context), width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.dynamicTextSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.formatProductPrice(context, totalAmount, storedCurrency: currency),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dynamicSuccess(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                // No Product Selected State
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.dynamicTextSecondary(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a product above to view details',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                      ),
                    ),
                  ],
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
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.dynamicBorder(context),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Decrement Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final currentValue = double.tryParse(_quantityController.text.replaceAll(',', '')) ?? 1.0;
                    final newValue = (currentValue - 1).clamp(0.1, double.infinity);
                    _quantityController.text = newValue.truncateToDouble() == newValue 
                        ? newValue.toInt().toString() 
                        : newValue.toStringAsFixed(2);
                    setState(() {});
                  },
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.dynamicPrimary(context).withAlpha(51),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      color: AppColors.dynamicPrimary(context),
                      size: 28,
                    ),
                  ),
                ),
              ),
              
              // Vertical Divider
              Container(
                width: 1,
                height: 40,
                color: AppColors.dynamicBorder(context).withAlpha(128),
              ),
              
              // Quantity Input Field
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dynamicTextPrimary(context),
                    letterSpacing: 0.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              
              // Vertical Divider
              Container(
                width: 1,
                height: 40,
                color: AppColors.dynamicBorder(context).withAlpha(128),
              ),
              
              // Increment Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final currentValue = double.tryParse(_quantityController.text.replaceAll(',', '')) ?? 1.0;
                    final newValue = currentValue + 1;
                    _quantityController.text = newValue.truncateToDouble() == newValue 
                        ? newValue.toInt().toString() 
                        : newValue.toStringAsFixed(2);
                    setState(() {});
                  },
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.dynamicPrimary(context).withAlpha(51),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.dynamicPrimary(context),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.dynamicTextSecondary(context),
              ),
              const SizedBox(width: 4),
              Text(
                'Use buttons to adjust or type directly',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAmount() {
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '')) ?? 1.0;
    final unitPrice = _selectedSubcategory?.sellingPrice ?? 0.0;
    final totalAmount = quantity * unitPrice;
    final currency = _selectedSubcategory?.sellingPriceCurrency ?? 'USD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicSuccess(context).withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicSuccess(context).withAlpha(77),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calculate,
                    color: AppColors.dynamicSuccess(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatProductPrice(context, totalAmount, storedCurrency: currency),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicSuccess(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} × ${CurrencyFormatter.formatProductPrice(context, unitPrice, storedCurrency: currency)}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDebtButton() {
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '')) ?? 1.0;
    final unitPrice = _selectedSubcategory?.sellingPrice ?? 0.0;
    final totalAmount = quantity * unitPrice;
    final isValid = _selectedCustomer != null && 
                    _selectedSubcategory != null && 
                    quantity > 0 && 
                    totalAmount > 0;

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
      
      // Validate quantity
      if (quantity <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid quantity greater than 0'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // DYNAMIC EXCHANGE RATE IMPLEMENTATION
      // For LBP products: Use current exchange rate to calculate USD equivalent
      // For USD products: Use stored USD values directly
      double totalAmount;
      double actualSellingPrice;
      double actualCostPrice;
      String storedCurrency;
      

      
      if (_selectedSubcategory!.sellingPriceCurrency == 'LBP') {
        // LBP PRODUCT: Use current exchange rate for dynamic USD pricing
        final currencySettings = appState.currencySettings;
        if (currencySettings != null && currencySettings.exchangeRate != null) {
          // Convert LBP to current USD using live exchange rate
          actualSellingPrice = _selectedSubcategory!.sellingPrice / currencySettings.exchangeRate!;
          actualCostPrice = _selectedSubcategory!.costPrice / currencySettings.exchangeRate!;
          storedCurrency = 'USD'; // Store as USD since we're converting to USD amounts
        } else {
          // No exchange rate set, fallback to stored values
          actualSellingPrice = _selectedSubcategory!.sellingPrice;
          actualCostPrice = _selectedSubcategory!.costPrice;
          storedCurrency = 'LBP';
        }
      } else {
        // USD PRODUCT: Use stored USD values directly
        actualSellingPrice = _selectedSubcategory!.sellingPrice;
        actualCostPrice = _selectedSubcategory!.costPrice;
        storedCurrency = 'USD';
      }
      
      // Calculate total amount based on quantity
      final totalSellingPrice = actualSellingPrice * quantity;
      final totalCostPrice = actualCostPrice * quantity;
      
      // Create description with quantity information
      String description = _selectedSubcategory!.name;
      if (quantity != 1.0) {
        final quantityText = quantity.truncateToDouble() == quantity 
            ? quantity.toInt().toString() 
            : quantity.toStringAsFixed(2);
        description = '${_selectedSubcategory!.name} (Qty: $quantityText)';
      }
      
      // Create a single debt entry with the total amount
      final debt = Debt(
        id: appState.generateDebtId(),
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        amount: totalSellingPrice, // Total amount = unit price × quantity
        description: description,
        type: DebtType.credit,
        status: DebtStatus.pending,
        createdAt: DateTime.now(),
        subcategoryId: _selectedSubcategory!.id,
        subcategoryName: _selectedSubcategory!.name,
        originalSellingPrice: actualSellingPrice, // Store unit price for reference
        originalCostPrice: actualCostPrice, // Store unit cost for reference
        categoryName: _selectedCategory!.name,
        storedCurrency: storedCurrency, // Store the original currency (LBP or USD)
      );
      
      await appState.addDebt(debt);
        
        if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Error adding debt
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