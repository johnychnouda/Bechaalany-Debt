import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart' show ProductCategory, Subcategory;
import '../utils/currency_formatter.dart';
import '../widgets/expandable_chip_dropdown.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';
  List<dynamic> _filteredProducts = [];
  String _selectedCategory = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _filterProducts();
  }

  void _filterProducts() {
    final appState = Provider.of<AppState>(context, listen: false);
    List<Subcategory> allSubcategories = [];
    
    // Debug: Print categories info
    print('Categories count: ${appState.categories.length}');
    for (final category in appState.categories) {
      print('Category type: ${category.runtimeType}');
      if (category is ProductCategory) {
        print('Category: ${category.name}, Subcategories: ${category.subcategories.length}');
        allSubcategories.addAll(category.subcategories);
      }
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      allSubcategories = allSubcategories.where((subcategory) {
        return subcategory.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (subcategory.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      allSubcategories = allSubcategories.where((subcategory) {
        for (final cat in appState.categories) {
          if (cat is ProductCategory && cat.subcategories.contains(subcategory)) {
            return cat.name == _selectedCategory;
          }
        }
        return false;
      }).toList();
    }

    // Sort subcategories
    _sortProducts(allSubcategories);

    setState(() {
      _filteredProducts = allSubcategories;
    });
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
            if (cat is ProductCategory) {
              if (cat.subcategories.contains(a)) {
                categoryNameA = cat.name;
              }
              if (cat.subcategories.contains(b)) {
                categoryNameB = cat.name;
              }
            }
          }
          
          comparison = categoryNameA.compareTo(categoryNameB);
          break;
        case 'Profit':
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
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Products',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterProducts();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              
              // Category Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      ...appState.categories.where((cat) => cat is ProductCategory).map((cat) => (cat as ProductCategory).name).where((name) => name.isNotEmpty),
                    ].map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onLongPress: () {
                            if (category != 'All') {
                              _showAddSubcategoryDialog(context, category);
                            }
                          },
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                              _filterProducts();
                            },
                            backgroundColor: Colors.transparent,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getEmptyStateMessage(),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getEmptyStateSubMessage(),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '💡 Tap + to add categories, long press category chips to add subcategories',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final subcategory = _filteredProducts[index] as Subcategory;
                          
                          // Find the category name when in "All" view
                          String? categoryName;
                          if (_selectedCategory == 'All') {
                            for (final category in appState.categories) {
                              if (category is ProductCategory && category.subcategories.contains(subcategory)) {
                                categoryName = category.name;
                                break;
                              }
                            }
                          }
                          
                          return _ProductCard(
                            subcategory: subcategory,
                            onEdit: () => _editProduct(subcategory),
                            onDelete: () => _deleteProduct(subcategory),
                            categoryName: categoryName,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _showAddCategoryDialog(context);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getEmptyStateMessage() {
    if (_selectedCategory == 'All') {
      return 'No categories or subcategories found';
    }
    return 'No subcategories in $_selectedCategory';
  }

  String _getEmptyStateSubMessage() {
    if (_selectedCategory == 'All') {
      return 'Add categories and subcategories to get started';
    }
    return 'Add subcategories to $_selectedCategory to get started';
  }

  void _editProduct(Subcategory subcategory) {
    // Find the category that contains this subcategory
    final appState = Provider.of<AppState>(context, listen: false);
    for (final category in appState.categories) {
      if (category is ProductCategory) {
        if (category.subcategories.contains(subcategory)) {
          _showEditSubcategoryDialog(context, subcategory, category.name);
          break;
        }
      }
    }
  }

  void _deleteProduct(Subcategory subcategory) {
    // Find the category that contains this subcategory
    final appState = Provider.of<AppState>(context, listen: false);
    for (final category in appState.categories) {
      if (category is ProductCategory) {
        if (category.subcategories.contains(subcategory)) {
          _showDeleteSubcategoryDialog(context, subcategory, category.name);
          break;
        }
      }
    }
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
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final appState = Provider.of<AppState>(context, listen: false);
                  final category = ProductCategory(
                    id: appState.generateCategoryId(),
                    name: nameController.text.trim(),
                    description: null,
                    createdAt: DateTime.now(),
                  );
                  
                  appState.addCategory(category);
                  Navigator.of(context).pop();
                  
                  // Refresh the products list
                  _filterProducts();
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
    final costPriceController = TextEditingController(text: subcategory.costPrice.toString());
    final sellingPriceController = TextEditingController(text: subcategory.sellingPrice.toString());
    String selectedCurrency = subcategory.costPriceCurrency; // Use same currency for both

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ExpandableChipDropdown<String>(
                  label: 'Currency',
                  value: selectedCurrency,
                  items: ['USD', 'LBP'],
                  itemToString: (currency) => currency,
                  onChanged: (value) {
                    selectedCurrency = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Cost Price',
                    hintText: 'e.g., 800.00',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sellingPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Selling Price',
                    hintText: 'e.g., 1000.00',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty &&
                        costPriceController.text.isNotEmpty &&
                        sellingPriceController.text.isNotEmpty) {
                      
                      final appState = Provider.of<AppState>(context, listen: false);
                      final category = appState.categories.firstWhere(
                        (cat) => cat is ProductCategory && cat.name == categoryName,
                        orElse: () => ProductCategory(id: '', name: '', createdAt: DateTime.now()),
                      );
                      
                      if (category is ProductCategory) {
                        // Convert prices to USD if they're in LBP
                        double costPriceUSD = double.parse(costPriceController.text);
                        double sellingPriceUSD = double.parse(sellingPriceController.text);
                        
                        if (selectedCurrency == 'LBP') {
                          costPriceUSD = costPriceUSD / 89500; // Convert LBP to USD (1 USD = 89,500 LBP)
                          sellingPriceUSD = sellingPriceUSD / 89500; // Convert LBP to USD (1 USD = 89,500 LBP)
                        }
                        
                        // Update the subcategory
                        subcategory.name = nameController.text.trim();
                        subcategory.costPrice = costPriceUSD;
                        subcategory.sellingPrice = sellingPriceUSD;
                        subcategory.costPriceCurrency = selectedCurrency;
                        subcategory.sellingPriceCurrency = selectedCurrency;
                        
                        appState.updateCategory(category);
                        
                        Navigator.of(context).pop();
                        
                        // Refresh the products list
                        _filterProducts();
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSubcategoryDialog(BuildContext context, Subcategory subcategory, String categoryName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Subcategory'),
          content: Text('Are you sure you want to delete "${subcategory.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                final category = appState.categories.firstWhere(
                  (cat) => cat is ProductCategory && cat.name == categoryName,
                  orElse: () => ProductCategory(id: '', name: '', createdAt: DateTime.now()),
                );
                
                if (category is ProductCategory) {
                  category.subcategories.removeWhere((sub) => sub.id == subcategory.id);
                  appState.updateCategory(category);
                  
                  Navigator.of(context).pop();
                  
                  // Refresh the products list
                  _filterProducts();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddSubcategoryDialog(BuildContext context, String categoryName) {
    final nameController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    String selectedCurrency = 'USD';

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ExpandableChipDropdown<String>(
                  label: 'Currency',
                  value: selectedCurrency,
                  items: ['USD', 'LBP'],
                  itemToString: (currency) => currency,
                  onChanged: (value) {
                    selectedCurrency = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Cost Price',
                    hintText: 'e.g., 800.00',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sellingPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Selling Price',
                    hintText: 'e.g., 1000.00',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty &&
                        costPriceController.text.isNotEmpty &&
                        sellingPriceController.text.isNotEmpty) {
                      
                      final appState = Provider.of<AppState>(context, listen: false);
                      final category = appState.categories.firstWhere(
                        (cat) => cat is ProductCategory && cat.name == categoryName,
                        orElse: () => ProductCategory(id: '', name: '', createdAt: DateTime.now()),
                      );
                      
                      if (category is ProductCategory) {
                        // Convert prices to USD if they're in LBP
                        double costPriceUSD = double.parse(costPriceController.text);
                        double sellingPriceUSD = double.parse(sellingPriceController.text);
                        
                        if (selectedCurrency == 'LBP') {
                          costPriceUSD = costPriceUSD / 89500; // Convert LBP to USD (1 USD = 89,500 LBP)
                          sellingPriceUSD = sellingPriceUSD / 89500; // Convert LBP to USD (1 USD = 89,500 LBP)
                        }
                        
                        final subcategory = Subcategory(
                          id: appState.generateProductPurchaseId(), // Using this as subcategory ID generator
                          name: nameController.text.trim(),
                          description: null, // No description field
                          costPrice: costPriceUSD,
                          sellingPrice: sellingPriceUSD,
                          createdAt: DateTime.now(),
                          costPriceCurrency: selectedCurrency,
                          sellingPriceCurrency: selectedCurrency,
                        );
                        
                        // Add subcategory to the category
                        category.subcategories.add(subcategory);
                        appState.updateCategory(category);
                        
                        Navigator.of(context).pop();
                        
                        // Refresh the products list
                        _filterProducts();
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
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
                      Text(
                        subcategory.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (categoryName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          categoryName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    context,
                    'Cost',
                    CurrencyFormatter.formatAmount(context, subcategory.costPrice),
                    Icons.shopping_cart,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    context,
                    'Price',
                    CurrencyFormatter.formatAmount(context, subcategory.sellingPrice),
                    Icons.attach_money,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    context,
                    'Profit',
                    CurrencyFormatter.formatAmount(context, subcategory.profit),
                    Icons.trending_up,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
            ),
          ),
        ],
      ),
    );
  }
} 