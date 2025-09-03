import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../constants/app_colors.dart';

import '../models/category.dart' show ProductCategory, Subcategory;
import '../models/currency_settings.dart';
import '../utils/currency_formatter.dart';
import '../widgets/expandable_chip_dropdown.dart';
import '../services/notification_service.dart';
import 'currency_settings_screen.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Format with thousands separators
    String formatted = NumberFormat('#,###').format(int.parse(digitsOnly));
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length      ),
    );
  }


}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';
  List<Subcategory> _filteredProducts = [];
  String _selectedCategory = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Delay the initial filter to ensure AppState is fully loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterProducts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Automatically refresh when dependencies change (AppState updates)
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.categories.isNotEmpty && _filteredProducts.isEmpty) {
      _filterProducts();
    }
  }

  void _filterProducts() {
    final appState = Provider.of<AppState>(context, listen: false);
    List<Subcategory> allSubcategories = [];
    
    // If no categories are loaded yet, wait for them to load
    if (appState.categories.isEmpty) {
      return;
    }
    
    // Get subcategories based on selected category
    if (_selectedCategory == 'All') {
      // Get all subcategories from all categories
      for (final category in appState.categories) {
        allSubcategories.addAll(category.subcategories);
      }
    } else {
      // Get subcategories only from the selected category
      final selectedCategory = appState.categories.firstWhere(
        (cat) => cat.name == _selectedCategory,
        orElse: () => ProductCategory(id: '', name: '', createdAt: DateTime.now()),
      );
      if (selectedCategory.id.isNotEmpty) {
        allSubcategories.addAll(selectedCategory.subcategories);
      }
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      allSubcategories = allSubcategories.where((subcategory) {
        return subcategory.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (subcategory.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Sort subcategories
    _sortProducts(allSubcategories);

    setState(() {
      _filteredProducts = allSubcategories;
    });
  }

  Widget _buildGroupedProductsList(AppState appState) {
    if (_selectedCategory == 'All') {
      // Show all categories with their subcategories grouped
      List<ProductCategory> categoriesToShow = [];
      
      // Filter categories based on search query and ensure they have subcategories
      for (final category in appState.categories) {
        List<Subcategory> filteredSubcategories = category.subcategories;
        
        // Apply search filter if there's a search query
        if (_searchQuery.isNotEmpty) {
          filteredSubcategories = category.subcategories.where((subcategory) {
            return subcategory.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   (subcategory.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          }).toList();
        }
        
        // Only show categories that have subcategories after filtering
        if (filteredSubcategories.isNotEmpty) {
          categoriesToShow.add(category);
        }
      }
      
      if (categoriesToShow.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.dynamicTextSecondary(context),
              ),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(
                  color: AppColors.dynamicTextPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms',
                style: TextStyle(
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoriesToShow.length,
        itemBuilder: (context, index) {
          final category = categoriesToShow[index];
          
          // Get filtered subcategories for this category
          List<Subcategory> filteredSubcategories = category.subcategories;
          if (_searchQuery.isNotEmpty) {
            filteredSubcategories = category.subcategories.where((subcategory) {
              return subcategory.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     (subcategory.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            }).toList();
          }
          
          return _CategorySection(
            category: category,
            subcategories: filteredSubcategories,
            onEditProduct: _editProduct,
            onDeleteProduct: _deleteProduct,
          );
        },
      );
    } else {
      // Show only the selected category's subcategories
      final selectedCategory = appState.categories.firstWhere(
        (cat) => cat.name == _selectedCategory,
        orElse: () => ProductCategory(id: '', name: '', createdAt: DateTime.now()),
      );
      
      if (selectedCategory.id.isEmpty) {
        return const Center(
          child: Text('Category not found'),
        );
      }
      
      if (_filteredProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.dynamicTextSecondary(context),
              ),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(
                  color: AppColors.dynamicTextPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty 
                    ? 'Try adjusting your search terms'
                    : 'Add products to this category to get started',
                style: TextStyle(
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final subcategory = _filteredProducts[index];
          return _ProductCard(
            subcategory: subcategory,
            onEdit: () => _editProduct(subcategory),
            onDelete: () => _deleteProduct(subcategory),
            categoryName: null, // Don't show category name since we're already in that category
          );
        },
      );
    }
  }

  void _sortProducts(List<Subcategory> subcategories) {
    subcategories.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'Name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'Price':
          comparison = a.sellingPrice.compareTo(b.sellingPrice);
          break;
        case 'Category':
          final appState = Provider.of<AppState>(context, listen: false);
          String categoryNameA = '';
          String categoryNameB = '';
          
          for (final cat in appState.categories) {
            if (cat.subcategories.contains(a)) {
              categoryNameA = cat.name;
            }
            if (cat.subcategories.contains(b)) {
              categoryNameB = cat.name;
            }
          }
          
          comparison = categoryNameA.compareTo(categoryNameB);
          break;
        case 'Revenue':
          comparison = a.profit.compareTo(b.profit);
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            return Column(
              children: [
                // Search and Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          _filterProducts();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: AppColors.dynamicTextSecondary(context)),
                          prefixIcon: Icon(Icons.search, color: AppColors.dynamicTextSecondary(context)),
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
                        ),
                        style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
                      ),
                      const SizedBox(height: 12),
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // All filter
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  'All',
                                  style: TextStyle(
                                    color: _selectedCategory == 'All' 
                                        ? Colors.white 
                                        : AppColors.dynamicTextPrimary(context),
                                    fontWeight: _selectedCategory == 'All' ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                selected: _selectedCategory == 'All',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = 'All';
                                  });
                                  _filterProducts();
                                },
                                backgroundColor: _selectedCategory == 'All' 
                                    ? AppColors.dynamicPrimary(context)
                                    : AppColors.dynamicSurface(context),
                                selectedColor: AppColors.dynamicPrimary(context),
                                checkmarkColor: Colors.white,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            // Category filters
                            ...appState.categories.map((category) {
                              final isSelected = _selectedCategory == category.name;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(
                                    category.name,
                                    style: TextStyle(
                                      color: isSelected 
                                          ? Colors.white 
                                          : AppColors.dynamicTextPrimary(context),
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category.name;
                                    });
                                    _filterProducts();
                                  },
                                  backgroundColor: isSelected 
                                      ? AppColors.dynamicPrimary(context)
                                      : AppColors.dynamicSurface(context),
                                  selectedColor: AppColors.dynamicPrimary(context),
                                  checkmarkColor: Colors.white,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Products List
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: AppColors.dynamicTextSecondary(context),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getEmptyStateMessage(),
                                style: TextStyle(
                                  color: AppColors.dynamicTextPrimary(context),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getEmptyStateSubMessage(),
                                style: TextStyle(
                                  color: AppColors.dynamicTextSecondary(context),
                                ),
                              ),
                              // Add refresh button for automatic refresh
                              if (appState.categories.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _filterProducts();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.dynamicPrimary(context),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : _buildGroupedProductsList(appState),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'products_fab_hero',
        onPressed: () async {
          _showAddChoiceDialog(context);
        },
        backgroundColor: AppColors.dynamicPrimary(context),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getEmptyStateMessage() {
    if (_selectedCategory == 'All') {
      return 'No categories found';
    }
    return 'No products in $_selectedCategory';
  }

  String _getEmptyStateSubMessage() {
    if (_selectedCategory == 'All') {
      return 'Add categories to get started';
    }
    return 'Add products to $_selectedCategory to get started';
  }

  void _editProduct(Subcategory subcategory) {
    // Find the category that contains this subcategory
    final appState = Provider.of<AppState>(context, listen: false);
    for (final category in appState.categories) {
      if (category.subcategories.contains(subcategory)) {
        _showEditSubcategoryDialog(context, subcategory, category.name);
        break;
      }
    }
  }

  void _deleteProduct(Subcategory subcategory) {
    // Find the category that contains this subcategory
    final appState = Provider.of<AppState>(context, listen: false);
    for (final category in appState.categories) {
      if (category.subcategories.contains(subcategory)) {
        _showDeleteSubcategoryDialog(context, subcategory, category.name);
        break;
      }
    }
  }

  void _showAddChoiceDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final hasCategories = appState.categories.isNotEmpty;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Quick Actions'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddCategoryDialog(context);
            },
            child: const Text('Add Category'),
          ),
          if (hasCategories)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _showCategorySelectionDialog(context);
              },
              child: const Text('Add Product'),
            ),
          if (hasCategories)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteCategorySelectionDialog(context);
              },
              child: const Text('Delete Category'),
            ),
          if (hasCategories)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteSubcategorySelectionDialog(context);
              },
              child: const Text('Delete Product'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCategorySelectionDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final categories = appState.categories.toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a category to add a subcategory to:'),
              const SizedBox(height: 16),
              ...categories.map((category) => ListTile(
                title: Text(category.name),
                subtitle: Text('${category.subcategories.length} subcategories'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddSubcategoryDialog(context, category.name);
                },
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Electronics',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  final appState = Provider.of<AppState>(context, listen: false);
                  final notificationService = NotificationService();
                  final category = ProductCategory(
                    id: appState.generateCategoryId(),
                    name: nameController.text.trim(),
                    description: null,
                    createdAt: DateTime.now(),
                  );
                  
                  try {
                    await appState.addCategory(category);
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                    
                    // Refresh the products list
                    _filterProducts();
                  } catch (e) {
                    // Show error notification
                    await notificationService.showErrorNotification(
                      title: 'Error',
                      body: 'Failed to add category: $e',
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSubcategoryDialog(BuildContext context, Subcategory subcategory, String categoryName) {
    final nameController = TextEditingController(text: subcategory.name);
    String selectedCurrency = subcategory.costPriceCurrency;
    
    // Get the stored amounts in their original currency
    final double storedCostPrice = subcategory.costPrice;
    final double storedSellingPrice = subcategory.sellingPrice;
    final String storedCurrency = subcategory.costPriceCurrency;
    
    // Initialize controllers based on currency
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    
    // Get current exchange rate from app state
    final appState = Provider.of<AppState>(context, listen: false);
    final currentExchangeRate = appState.currencySettings?.exchangeRate;
    
    // Check if exchange rate is set (only required for LBP products)
    if (selectedCurrency == 'LBP' && (currentExchangeRate == null || currentExchangeRate <= 0)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Exchange Rate Required'),
          content: const Text('Please set an exchange rate in Currency Settings before adding products with LBP pricing.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('Go to Settings'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const CurrencySettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );
      return;
    }
    
    // Set initial values based on currency
    if (selectedCurrency == 'LBP') {
      // If we want to display in LBP, show the stored LBP amounts
      if (storedCurrency == 'LBP') {
        // Already stored in LBP, show as is
        costPriceController.text = NumberFormat('#,###').format(storedCostPrice.toInt());
        sellingPriceController.text = NumberFormat('#,###').format(storedSellingPrice.toInt());
      } else {
        // Stored in USD, convert to LBP for display
        if (currentExchangeRate != null) {
          final costPriceLBP = storedCostPrice * currentExchangeRate;
          final sellingPriceLBP = storedSellingPrice * currentExchangeRate;
          costPriceController.text = NumberFormat('#,###').format(costPriceLBP.toInt());
          sellingPriceController.text = NumberFormat('#,###').format(sellingPriceLBP.toInt());
        } else {
          // Fallback to USD if no exchange rate
          costPriceController.text = storedCostPrice.toStringAsFixed(2);
          sellingPriceController.text = storedSellingPrice.toStringAsFixed(2);
        }
      }
    } else {
      // If we want to display in USD, show the stored USD amounts
      if (storedCurrency == 'USD') {
        // Already stored in USD, show as is
        costPriceController.text = storedCostPrice.toStringAsFixed(2);
        sellingPriceController.text = storedSellingPrice.toStringAsFixed(2);
      } else {
        // Stored in LBP, convert to USD for display
        if (currentExchangeRate != null) {
          final costPriceUSD = storedCostPrice / currentExchangeRate;
          final sellingPriceUSD = storedSellingPrice / currentExchangeRate;
          costPriceController.text = costPriceUSD.toStringAsFixed(2);
          sellingPriceController.text = sellingPriceUSD.toStringAsFixed(2);
        } else {
          // Fallback to LBP if no exchange rate
          costPriceController.text = NumberFormat('#,###').format(storedCostPrice.toInt());
          sellingPriceController.text = NumberFormat('#,###').format(storedSellingPrice.toInt());
        }
      }
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Add listeners to trigger rebuild when text changes
            nameController.addListener(() => setState(() {}));
            costPriceController.addListener(() => setState(() {}));
            sellingPriceController.addListener(() => setState(() {}));
            
            return AlertDialog(
              title: const Text('Edit Subcategory'),
              contentPadding: const EdgeInsets.all(16),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Subcategory Name',
                        hintText: 'e.g., iPhone',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Currency',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ExpandableChipDropdown<String>(
                      label: 'Currency',
                      value: selectedCurrency,
                      items: ['USD', 'LBP'],
                      itemToString: (currency) => currency,
                      onChanged: (value) {
                        setState(() {
                          selectedCurrency = value!;
                          if (selectedCurrency == 'LBP') {
                            // Convert to LBP for display
                            if (storedCurrency == 'USD') {
                              // Stored in USD, convert to LBP
                              if (currentExchangeRate != null) {
                                final costPriceLBP = storedCostPrice * currentExchangeRate;
                                final sellingPriceLBP = storedSellingPrice * currentExchangeRate;
                                costPriceController.text = NumberFormat('#,###').format(costPriceLBP.toInt());
                                sellingPriceController.text = NumberFormat('#,###').format(sellingPriceLBP.toInt());
                              } else {
                                // Fallback to USD if no exchange rate
                                costPriceController.text = storedCostPrice.toStringAsFixed(2);
                                sellingPriceController.text = storedSellingPrice.toStringAsFixed(2);
                              }
                            } else {
                              // Already stored in LBP, show as is
                              costPriceController.text = NumberFormat('#,###').format(storedCostPrice.toInt());
                              sellingPriceController.text = NumberFormat('#,###').format(storedSellingPrice.toInt());
                            }
                          } else {
                            // Convert to USD for display
                            if (storedCurrency == 'LBP') {
                              // Stored in LBP, convert to USD
                              if (currentExchangeRate != null) {
                                final costPriceUSD = storedCostPrice / currentExchangeRate;
                                final sellingPriceUSD = storedSellingPrice / currentExchangeRate;
                                costPriceController.text = costPriceUSD.toStringAsFixed(2);
                                sellingPriceController.text = sellingPriceUSD.toStringAsFixed(2);
                              } else {
                                // Fallback to LBP if no exchange rate
                                costPriceController.text = NumberFormat('#,###').format(storedCostPrice.toInt());
                                sellingPriceController.text = NumberFormat('#,###').format(storedSellingPrice.toInt());
                              }
                            } else {
                              // Already stored in USD, show as is
                              costPriceController.text = storedCostPrice.toStringAsFixed(2);
                              sellingPriceController.text = storedSellingPrice.toStringAsFixed(2);
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: costPriceController,
                      decoration: InputDecoration(
                        labelText: 'Cost Price',
                        hintText: 'Enter cost price',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: selectedCurrency == 'LBP' 
                          ? [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()]
                          : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: sellingPriceController,
                      decoration: InputDecoration(
                        labelText: 'Selling Price',
                        hintText: 'Enter selling price',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: selectedCurrency == 'LBP' 
                          ? [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()]
                          : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    ),
                    
                    // Calculate if there's a loss
                    Builder(
                      builder: (context) {
                        final costPriceText = costPriceController.text.replaceAll(',', '');
                        final sellingPriceText = sellingPriceController.text.replaceAll(',', '');
                        final costPrice = double.tryParse(costPriceText) ?? 0.0;
                        final sellingPrice = double.tryParse(sellingPriceText);
                        final sellingPriceEntered = sellingPriceController.text.isNotEmpty;
                        final isLoss = sellingPriceEntered && sellingPrice != null && sellingPrice < costPrice;
                        final loss = sellingPrice != null ? sellingPrice - costPrice : 0.0;
                        
                        return Column(
                          children: [
                            if (isLoss) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.warning, color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600),
                                        children: [
                                          const TextSpan(text: 'Warning: Selling price is less than cost. You\'ll lose '),
                                          TextSpan(
                                            text: selectedCurrency == 'USD' 
                                                ? '${loss.toStringAsFixed(2)}\$'
                                                : '${NumberFormat('#,###').format(loss.toInt())} LBP',
                                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                                          ),
                                          const TextSpan(text: ' on each sale.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final costPriceText = costPriceController.text.replaceAll(',', '');
                          final sellingPriceText = sellingPriceController.text.replaceAll(',', '');
                          final costPrice = double.tryParse(costPriceText) ?? 0.0;
                          final sellingPrice = double.tryParse(sellingPriceText);
                          final isLoss = sellingPrice != null && sellingPrice < costPrice;
                          
                          final isEnabled = nameController.text.trim().isNotEmpty && costPriceController.text.isNotEmpty && sellingPriceController.text.isNotEmpty;
                          
                          return ElevatedButton(
                            onPressed: isEnabled
                                ? () async {
                                    final appState = Provider.of<AppState>(context, listen: false);
                                    final notificationService = NotificationService();
                                    final category = appState.categories.firstWhere(
                                      (cat) => cat.name == categoryName,
                                      orElse: () => ProductCategory(id: '', name: '', createdAt: DateTime.now()),
                                    );
                                    try {
                                      String cleanCostPrice = costPriceController.text.replaceAll(',', '');
                                      String cleanSellingPrice = sellingPriceController.text.replaceAll(',', '');
                                      double costPrice = double.parse(cleanCostPrice);
                                      double sellingPrice = double.parse(cleanSellingPrice);
                                      
                                      subcategory.name = nameController.text.trim();
                                      subcategory.costPrice = costPrice;
                                      subcategory.sellingPrice = sellingPrice;
                                      subcategory.costPriceCurrency = selectedCurrency;
                                      subcategory.sellingPriceCurrency = selectedCurrency;
                                      
                                      // Validate prices before saving to prevent corruption
                                      if (!subcategory.hasValidPrices) {
                                        final validationMessage = subcategory.priceValidationMessage;
                                        await notificationService.showErrorNotification(
                                          title: 'Invalid Prices',
                                          body: validationMessage ?? 'Please check the product prices.',
                                        );
                                        return;
                                      }
                                      
                                      await appState.updateCategory(category);
                                      if (mounted) {
                                        Navigator.of(context).pop();
                                      }
                                      await notificationService.showProductUpdatedNotification(subcategory.name);
                                      _filterProducts();
                                    } catch (e) {
                                      await notificationService.showErrorNotification(
                                        title: 'Error',
                                        body: 'Failed to update product: $e',
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEnabled 
                                  ? (isLoss ? AppColors.error : AppColors.dynamicPrimary(context))
                                  : AppColors.dynamicTextSecondary(context),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(isLoss ? 'Confirm' : 'Update'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteSubcategoryDialog(BuildContext context, Subcategory subcategory, String categoryName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.dynamicBackground(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_forever,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Product Name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicPrimary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dynamicPrimary(context).withAlpha(77)),
                  ),
                  child: Text(
                    '"${subcategory.name}"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Warning Message
                Text(
                  'Are you sure you want to delete this product?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.dynamicTextPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.dynamicBorder(context)),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final appState = Provider.of<AppState>(context, listen: false);
                          final notificationService = NotificationService();
                          final category = appState.categories.firstWhere(
                            (cat) => cat.name == categoryName,
                            orElse: () => ProductCategory(id: '', name: '', createdAt: DateTime.now()),
                          );
                          try {
                            category.subcategories.removeWhere((sub) => sub.id == subcategory.id);
                            await appState.updateCategory(category);
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                            await notificationService.showProductDeletedNotification(subcategory.name);
                            _filterProducts();
                          } catch (e) {
                            await notificationService.showErrorNotification(
                              title: 'Error',
                              body: 'Failed to delete product: $e',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSubcategoryDialog(BuildContext context, String categoryName) {
    final nameController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    String selectedCurrency = 'USD';
    double defaultCostPriceUSD = 0.0;
    double defaultSellingPriceUSD = 0.0;
    
    // Get current exchange rate from app state
    final appState = Provider.of<AppState>(context, listen: false);
    final currentExchangeRate = appState.currencySettings?.exchangeRate;
    
    // Check if exchange rate is set (only required for LBP products)
    if (selectedCurrency == 'LBP' && (currentExchangeRate == null || currentExchangeRate <= 0)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Exchange Rate Required'),
          content: const Text('Please set an exchange rate in Currency Settings before adding products with LBP pricing.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('Go to Settings'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const CurrencySettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );
      return;
    }
    
    // Add listeners to trigger rebuild when text changes
    nameController.addListener(() {});
    costPriceController.addListener(() {});
    sellingPriceController.addListener(() {});

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Add listeners to trigger rebuild when text changes
            nameController.addListener(() => setState(() {}));
            costPriceController.addListener(() => setState(() {}));
            sellingPriceController.addListener(() => setState(() {}));
            
            return AlertDialog(
              title: Text('Add Subcategory to $categoryName'),
              contentPadding: const EdgeInsets.all(16),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Subcategory Name',
                        hintText: 'e.g., iPhone',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Currency',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ExpandableChipDropdown<String>(
                      label: 'Currency',
                      value: selectedCurrency,
                      items: ['USD', 'LBP'],
                      itemToString: (currency) => currency,
                      onChanged: (value) {
                        setState(() {
                          selectedCurrency = value!;
                          if (selectedCurrency == 'LBP') {
                            if (defaultCostPriceUSD > 0 && currentExchangeRate != null) {
                              costPriceController.text = NumberFormat('#,###').format((defaultCostPriceUSD * currentExchangeRate).toInt());
                            } else {
                              costPriceController.clear();
                            }
                            if (defaultSellingPriceUSD > 0 && currentExchangeRate != null) {
                              sellingPriceController.text = NumberFormat('#,###').format((defaultSellingPriceUSD * currentExchangeRate).toInt());
                            } else {
                              sellingPriceController.clear();
                            }
                          } else {
                            if (defaultCostPriceUSD > 0) {
                              costPriceController.text = defaultCostPriceUSD.toStringAsFixed(2);
                            } else {
                              costPriceController.clear();
                            }
                            if (defaultSellingPriceUSD > 0) {
                              sellingPriceController.text = defaultSellingPriceUSD.toStringAsFixed(2);
                            } else {
                              sellingPriceController.clear();
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: costPriceController,
                      decoration: InputDecoration(
                        labelText: 'Cost Price',
                        hintText: 'Enter cost price',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: selectedCurrency == 'LBP' 
                          ? [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()]
                          : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          try {
                            // Remove commas for parsing
                            String cleanValue = value.replaceAll(',', '');
                            double price = double.parse(cleanValue);
                            if (selectedCurrency == 'LBP' && currentExchangeRate != null) {
                              defaultCostPriceUSD = price / currentExchangeRate;
                            } else {
                              defaultCostPriceUSD = price;
                            }
                          } catch (e) {
                            // Handle invalid input
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: sellingPriceController,
                      decoration: InputDecoration(
                        labelText: 'Selling Price',
                        hintText: 'Enter selling price',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: selectedCurrency == 'LBP' 
                          ? [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()]
                          : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          try {
                            // Remove commas for parsing
                            String cleanValue = value.replaceAll(',', '');
                            double price = double.parse(cleanValue);
                            if (selectedCurrency == 'LBP' && currentExchangeRate != null) {
                              defaultSellingPriceUSD = price / currentExchangeRate;
                            } else {
                              defaultSellingPriceUSD = price;
                            }
                          } catch (e) {
                            // Handle invalid input
                          }
                        }
                      },
                    ),
                    
                    // Calculate if there's a loss
                    Builder(
                      builder: (context) {
                        final costPriceText = costPriceController.text.replaceAll(',', '');
                        final sellingPriceText = sellingPriceController.text.replaceAll(',', '');
                        final costPrice = double.tryParse(costPriceText) ?? 0.0;
                        final sellingPrice = double.tryParse(sellingPriceText);
                        final sellingPriceEntered = sellingPriceController.text.isNotEmpty;
                        final isLoss = sellingPriceEntered && sellingPrice != null && sellingPrice < costPrice;
                        final loss = sellingPrice != null ? sellingPrice - costPrice : 0.0;
                        
                        return Column(
                          children: [
                            if (isLoss) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.warning, color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600),
                                        children: [
                                          const TextSpan(text: 'Warning: Selling price is less than cost. You\'ll lose '),
                                          TextSpan(
                                            text: selectedCurrency == 'USD' 
                                                ? '${loss.toStringAsFixed(2)}\$'
                                                : '${NumberFormat('#,###').format(loss.toInt())} LBP',
                                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                                          ),
                                          const TextSpan(text: ' on each sale.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final costPriceText = costPriceController.text.replaceAll(',', '');
                          final sellingPriceText = sellingPriceController.text.replaceAll(',', '');
                          final costPrice = double.tryParse(costPriceText) ?? 0.0;
                          final sellingPrice = double.tryParse(sellingPriceText);
                          final isLoss = sellingPrice != null && sellingPrice < costPrice;
                          
                          final isEnabled = nameController.text.trim().isNotEmpty && costPriceController.text.isNotEmpty && sellingPriceController.text.isNotEmpty;
                          
                          return ElevatedButton(
                            onPressed: isEnabled
                                ? () async {
                                    final appState = Provider.of<AppState>(context, listen: false);
                                    final notificationService = NotificationService();
                                    final category = appState.categories.firstWhere(
                                      (cat) => cat.name == categoryName,
                                      orElse: () => ProductCategory(id: '', name: '', createdAt: DateTime.now()),
                                    );
                                    try {
                                      String cleanCostPrice = costPriceController.text.replaceAll(',', '');
                                      String cleanSellingPrice = sellingPriceController.text.replaceAll(',', '');
                                      double costPrice = double.parse(cleanCostPrice);
                                      double sellingPrice = double.parse(cleanSellingPrice);
                                      
                                      final subcategory = Subcategory(
                                        id: appState.generateProductPurchaseId(),
                                        name: nameController.text.trim(),
                                        description: null,
                                        costPrice: costPrice,
                                        sellingPrice: sellingPrice,
                                        createdAt: DateTime.now(),
                                        costPriceCurrency: selectedCurrency,
                                        sellingPriceCurrency: selectedCurrency,
                                      );
                                      
                                      // Validate prices before saving to prevent corruption
                                      if (!subcategory.hasValidPrices) {
                                        final validationMessage = subcategory.priceValidationMessage;
                                        await notificationService.showErrorNotification(
                                          title: 'Invalid Prices',
                                          body: validationMessage ?? 'Please check the product prices.',
                                        );
                                        return;
                                      }
                                      
                                      category.subcategories.add(subcategory);
                                      await appState.updateCategory(category);
                                      if (mounted) {
                                        Navigator.of(context).pop();
                                      }
                                      await notificationService.showProductUpdatedNotification(subcategory.name);
                                      _filterProducts();
                                    } catch (e) {
                                      await notificationService.showErrorNotification(
                                        title: 'Error',
                                        body: 'Failed to add product: $e',
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEnabled 
                                  ? (isLoss ? AppColors.error : AppColors.dynamicPrimary(context))
                                  : AppColors.dynamicTextSecondary(context),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(isLoss ? 'Confirm' : 'Add'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteCategorySelectionDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final categories = appState.categories.toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a category to delete:'),
              const SizedBox(height: 16),
              ...categories.map((category) => ListTile(
                title: Text(category.name),
                subtitle: Text('${category.subcategories.length} subcategories'),
                trailing: const Icon(Icons.delete, color: Colors.red),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteCategoryConfirmationDialog(context, category);
                },
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSubcategorySelectionDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final allSubcategories = <Subcategory>[];
    final categoryMap = <Subcategory, ProductCategory>{};

    // Collect all subcategories with their parent categories
    for (final category in appState.categories) {
      for (final subcategory in category.subcategories) {
        allSubcategories.add(subcategory);
        categoryMap[subcategory] = category;
      }
    }

    if (allSubcategories.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Subcategories'),
            content: const Text('There are no subcategories to delete.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Subcategory'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a subcategory to delete:'),
              const SizedBox(height: 16),
              ...allSubcategories.map((subcategory) {
                final category = categoryMap[subcategory]!;
                return ListTile(
                  title: Text(subcategory.name),
                  subtitle: Text('Category: ${category.name}'),
                  trailing: const Icon(Icons.delete, color: Colors.red),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteSubcategoryConfirmationDialog(context, subcategory, category);
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCategoryConfirmationDialog(BuildContext context, ProductCategory category) {
    final subcategoryCount = category.subcategories.length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.dynamicBackground(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.folder_delete,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Category Name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicPrimary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dynamicPrimary(context).withAlpha(77)),
                  ),
                  child: Text(
                    '"${category.name}"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Warning Message
                Text(
                  'Are you sure you want to delete this category?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.dynamicTextPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Products Warning
                if (subcategoryCount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicWarning(context).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.dynamicWarning(context).withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: AppColors.dynamicWarning(context),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This category contains $subcategoryCount product${subcategoryCount == 1 ? '' : 's'} that will also be deleted.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.dynamicWarning(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.dynamicBorder(context)),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final appState = Provider.of<AppState>(context, listen: false);
                          final notificationService = NotificationService();
                          
                          try {
                            await appState.deleteCategory(category.id);
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                            
                            // Reset to 'All' if the deleted category was selected
                            if (_selectedCategory == category.name) {
                              setState(() {
                                _selectedCategory = 'All';
                              });
                            }
                            
                            // Refresh the products list
                            _filterProducts();
                          } catch (e) {
                            // Show error notification
                            await notificationService.showErrorNotification(
                              title: 'Error',
                              body: 'Failed to delete category: $e',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteSubcategoryConfirmationDialog(BuildContext context, Subcategory subcategory, ProductCategory category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.dynamicBackground(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_forever,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Product Name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicPrimary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dynamicPrimary(context).withAlpha(77)),
                  ),
                  child: Text(
                    '"${subcategory.name}"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Category Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicTextSecondary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dynamicTextSecondary(context).withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        color: AppColors.dynamicTextSecondary(context),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'From category: "${category.name}"',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.dynamicTextSecondary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Warning Message
                Text(
                  'Are you sure you want to delete this product?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.dynamicTextPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.dynamicBorder(context)),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final appState = Provider.of<AppState>(context, listen: false);
                          final notificationService = NotificationService();
                          
                          try {
                            await appState.deleteSubcategory(category.id, subcategory.id);
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                            
                            // Show success notification
                            await notificationService.showProductDeletedNotification(subcategory.name);
                            
                            // Refresh the products list
                            _filterProducts();
                          } catch (e) {
                            // Show error notification
                            await notificationService.showErrorNotification(
                              title: 'Error',
                              body: 'Failed to delete product: $e',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Subcategory subcategory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? categoryName; // Optional category name to display

  const _ProductCard({
    required this.subcategory,
    required this.onEdit,
    required this.onDelete,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            subcategory.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Exchange Rate Display - Only show for LBP products
                          Consumer<AppState>(
                            builder: (context, appState, child) {
                              // Debug: Print subcategory currency info

                              
                              // Show exchange rate chip for LBP products when currency settings are available
                              if (appState.currencySettings?.exchangeRate != null && 
                                  (subcategory.costPriceCurrency == 'LBP' || subcategory.sellingPriceCurrency == 'LBP')) {

                                return _buildExchangeRateChip(context, appState.currencySettings!);
                              } else {

                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],
                      ),
                      if (categoryName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          categoryName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.dynamicTextSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showProductActionSheet(context),
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<AppState>(
              builder: (context, appState, child) {
                // Get actual ProductPurchase data for this subcategory
                final productPurchases = appState.productPurchases
                    .where((p) => p.subcategoryName == subcategory.name)
                    .toList();
                
                // Debug: Print ProductPurchase data

                if (productPurchases.isNotEmpty) {
                  for (final purchase in productPurchases) {

                  }
                }

                
                // Calculate actual costs, prices, and revenue from purchase data
                double totalCost = 0.0;
                double totalPrice = 0.0;
                double totalRevenue = 0.0;
                
                if (productPurchases.isNotEmpty) {
                  for (final purchase in productPurchases) {
                    totalCost += purchase.costPrice;
                    totalPrice += purchase.sellingPrice;
                    totalRevenue += (purchase.sellingPrice - purchase.costPrice);
                  }

                } else {
                  // Fallback to subcategory template data if no purchases exist
                  totalCost = subcategory.costPrice;
                  totalPrice = subcategory.sellingPrice;
                  totalRevenue = subcategory.profit;
                  
                  // Convert LBP values to USD if currency settings are available
                  if (appState.currencySettings?.exchangeRate != null && 
                      (subcategory.costPriceCurrency == 'LBP' || subcategory.sellingPriceCurrency == 'LBP')) {
                    final exchangeRate = appState.currencySettings!.exchangeRate!;
                    totalCost = totalCost / exchangeRate;
                    totalPrice = totalPrice / exchangeRate;
                    totalRevenue = totalRevenue / exchangeRate;

                  } else {

                  }
                }
                
                // Final debug: Show what values will be displayed

                
                return Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        'Cost',
                        // Pass original LBP values for LBP products, converted USD values for USD products
                        subcategory.costPriceCurrency == 'LBP' 
                            ? CurrencyFormatter.getFormattedUSDForProductDisplay(context, subcategory.costPrice, storedCurrency: 'LBP')
                            : '${totalCost.toStringAsFixed(2)}\$',
                        Icons.shopping_cart,
                        AppColors.dynamicWarning(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        'Price',
                        // Pass original LBP values for LBP products, converted USD values for USD products
                        subcategory.sellingPriceCurrency == 'LBP'
                            ? CurrencyFormatter.getFormattedUSDForProductDisplay(context, subcategory.sellingPrice, storedCurrency: 'LBP')
                            : '${totalPrice.toStringAsFixed(2)}\$',
                        Icons.attach_money,
                        AppColors.dynamicPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        totalRevenue >= 0 ? 'Revenue' : 'Loss',
                        // Pass original LBP values for LBP products, converted USD values for USD products
                        subcategory.sellingPriceCurrency == 'LBP'
                            ? CurrencyFormatter.getFormattedUSDForProductDisplay(context, subcategory.profit, storedCurrency: 'LBP')
                            : '${totalRevenue.toStringAsFixed(2)}\$',
                        Icons.trending_up,
                        totalRevenue >= 0 ? AppColors.dynamicSuccess(context) : AppColors.error,
                      ),
                    ),
                  ],
                );
              },
            ),

          ],
        ),
      ),
    );
  }

  void _showProductActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          subcategory.name,
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            child: const Text('Edit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              onDelete();
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

  Widget _buildExchangeRateChip(BuildContext context, CurrencySettings settings) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.transparent : AppColors.systemGray5,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? Colors.transparent : AppColors.systemGray3,
          width: isDarkMode ? 0 : 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.currency_exchange,
            size: 12,
            color: isDarkMode ? Colors.red : AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            settings.exchangeRate != null
                ? '1 ${settings.baseCurrency} = ${_addThousandsSeparators(settings.exchangeRate!.toInt().toString())} ${settings.targetCurrency}'
                : 'Rate not set',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.red : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 * 255
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(77)), // 0.3 * 255
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _addThousandsSeparators(String number) {
    final buffer = StringBuffer();
    final length = number.length;
    
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(number[i]);
    }
    
    return buffer.toString();
  }
}

class _CategorySection extends StatelessWidget {
  final ProductCategory category;
  final List<Subcategory> subcategories;
  final Function(Subcategory) onEditProduct;
  final Function(Subcategory) onDeleteProduct;

  const _CategorySection({
    required this.category,
    required this.subcategories,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.dynamicPrimary(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dynamicPrimary(context).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.category,
                color: AppColors.dynamicPrimary(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dynamicPrimary(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${subcategories.length} product${subcategories.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Subcategories List
        ...subcategories.map((subcategory) => _ProductCard(
          subcategory: subcategory,
          onEdit: () => onEditProduct(subcategory),
          onDelete: () => onDeleteProduct(subcategory),
          categoryName: null, // Don't show category name since it's already shown in header
        )),
      ],
    );
  }
} 