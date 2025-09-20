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

class AddDebtScreen extends StatefulWidget {
  final Customer? customer;

  const AddDebtScreen({super.key, this.customer});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  Customer? _selectedCustomer;
  ProductCategory? _selectedCategory;
  Subcategory? _selectedSubcategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
  }





  Future<void> _saveDebt() async {
    if (_selectedCustomer != null && _selectedSubcategory != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final appState = Provider.of<AppState>(context, listen: false);
        
        // Fix floating-point precision issues by rounding to 2 decimal places
        final roundedAmount = ((_selectedSubcategory!.sellingPrice * 100).round() / 100);
        
        final debt = Debt(
          id: appState.generateDebtId(),
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          description: _selectedSubcategory!.name,
          amount: roundedAmount, // Use selling price (what customer owes)
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
        
        // Error adding debt
      }
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      appBar: AppBar(
        title: Text('Add Debt for ${_selectedCustomer?.name ?? "Customer"}', 
          style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
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
                              CurrencyFormatter.formatAmount(context, _selectedSubcategory!.sellingPrice, storedCurrency: _selectedSubcategory!.sellingPriceCurrency),
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

  Widget _buildAddDebtButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading || _selectedSubcategory == null ? null : _saveDebt,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dynamicPrimary(context),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
            : Text(
                'Add Debt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
} 