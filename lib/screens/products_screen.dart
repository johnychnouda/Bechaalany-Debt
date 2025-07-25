import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart' show ProductCategory, Subcategory;
import '../utils/currency_formatter.dart';

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
                          return _ProductCard(
                            subcategory: subcategory,
                            onEdit: () => _editProduct(subcategory),
                            onDelete: () => _deleteProduct(subcategory),
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
    // TODO: Navigate to edit subcategory screen
  }

  void _deleteProduct(Subcategory subcategory) {
    // TODO: Show confirmation dialog and delete subcategory
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

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
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Electronic devices and gadgets',
                ),
                maxLines: 2,
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
                    description: descriptionController.text.trim().isEmpty 
                        ? null 
                        : descriptionController.text.trim(),
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

  void _showAddSubcategoryDialog(BuildContext context, String categoryName) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Subcategory to $categoryName'),
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
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'e.g., Apple smartphones',
                  ),
                  maxLines: 2,
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
                    final subcategory = Subcategory(
                      id: appState.generateProductPurchaseId(), // Using this as subcategory ID generator
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty 
                          ? null 
                          : descriptionController.text.trim(),
                      costPrice: double.parse(costPriceController.text),
                      sellingPrice: double.parse(sellingPriceController.text),
                      createdAt: DateTime.now(),
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
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Subcategory subcategory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.subcategory,
    required this.onEdit,
    required this.onDelete,
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
                      const SizedBox(height: 4),
                      Text(
                        subcategory.description ?? 'No description',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                _buildInfoChip(
                  context,
                  'Cost',
                  CurrencyFormatter.formatAmount(context, subcategory.costPrice),
                  Icons.shopping_cart,
                  AppColors.warning,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  context,
                  'Price',
                  CurrencyFormatter.formatAmount(context, subcategory.sellingPrice),
                  Icons.attach_money,
                  AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  context,
                  'Profit',
                  CurrencyFormatter.formatAmount(context, subcategory.profit),
                  Icons.trending_up,
                  AppColors.success,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 