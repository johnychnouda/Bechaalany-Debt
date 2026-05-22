import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as fw;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';

import '../models/category.dart' show ProductCategory, Subcategory;
import '../models/currency_settings.dart';
import '../utils/barcode_lookup.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_layout.dart';
import '../widgets/expandable_chip_dropdown.dart';
// Notification service import removed
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
  bool _isReorderMode = false;

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
               (subcategory.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (subcategory.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Sort subcategories
    _sortProducts(allSubcategories);

    setState(() {
      _filteredProducts = allSubcategories;
    });
  }

  Widget _buildGroupedProductsList(AppState appState, {bool isDesktopWeb = false}) {
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
                   (subcategory.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                   (subcategory.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
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
                AppLocalizations.of(context)!.noProductsFound,
                style: TextStyle(
                  color: AppColors.dynamicTextPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.tryAdjustingSearchTerms,
                style: TextStyle(
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: EdgeInsets.only(bottom: isDesktopWeb ? 16 : 0),
        itemCount: categoriesToShow.length,
        itemBuilder: (context, index) {
          final category = categoriesToShow[index];
          
          List<Subcategory> filteredSubcategories = category.subcategories;
          if (_searchQuery.isNotEmpty) {
            filteredSubcategories = category.subcategories.where((subcategory) {
              return subcategory.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     (subcategory.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                     (subcategory.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            }).toList();
          }
          
          return _CategorySection(
            category: category,
            subcategories: filteredSubcategories,
            onEditProduct: _editProduct,
            onDeleteProduct: _deleteProduct,
            desktopTable: isDesktopWeb,
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
        return Center(
          child: Text(AppLocalizations.of(context)!.categoryNotFound),
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
                AppLocalizations.of(context)!.noProductsFound,
                style: TextStyle(
                  color: AppColors.dynamicTextPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? AppLocalizations.of(context)!.tryAdjustingSearchTerms
                    : AppLocalizations.of(context)!.addProductsToCategoryToGetStarted(_selectedCategory),
                style: TextStyle(
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ],
          ),
        );
      }
      
      if (isDesktopWeb) {
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: _filteredProducts.length + 1,
          separatorBuilder: (context, index) {
            if (index == 0) return const Divider(height: 1);
            return Divider(
              height: 1,
              color: AppColors.dynamicBorder(context).withValues(alpha: 0.15),
            );
          },
          itemBuilder: (context, index) {
            if (index == 0) return const _DesktopProductsTableHeader();
            final subcategory = _filteredProducts[index - 1];
            return _ProductCard(
              subcategory: subcategory,
              onEdit: () => _editProduct(subcategory),
              onDelete: () => _deleteProduct(subcategory),
              desktopRow: true,
            );
          },
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
            categoryName: null,
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

  Widget _buildReorderableFilterChips(BuildContext context, AppState appState) {
    // Get categories in saved order
    final orderedCategories = appState.getCategoriesInOrder();
    
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          // All filter (non-reorderable, always first)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                AppLocalizations.of(context)!.filterAll,
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
          // Reorderable category filters
          Expanded(
            child: _isReorderMode
                ? ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: orderedCategories.length,
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 6,
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: child,
                      );
                    },
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      
                      setState(() {
                        final category = orderedCategories.removeAt(oldIndex);
                        orderedCategories.insert(newIndex, category);
                      });
                      
                      // Save the new order
                      final appState = Provider.of<AppState>(context, listen: false);
                      final categoryIds = orderedCategories.map((c) => c.id).toList();
                      await appState.updateCategoryOrder(categoryIds);
                    },
                    itemBuilder: (context, index) {
                      final category = orderedCategories[index];
                      return Padding(
                        key: Key(category.id),
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.drag_handle,
                                size: 14,
                                color: AppColors.dynamicTextSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: AppColors.dynamicTextPrimary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          selected: false,
                          onSelected: null,
                          backgroundColor: AppColors.dynamicSurface(context),
                          selectedColor: AppColors.dynamicPrimary(context),
                          checkmarkColor: Colors.white,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    },
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: orderedCategories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final isSelected = _selectedCategory == category.name;
                        return Padding(
                          key: Key('${category.id}_$index'),
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onLongPress: () {
                              _showCategoryActionSheet(context, category);
                            },
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
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          // Done button when in reorder mode
          if (_isReorderMode)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isReorderMode = false;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.dynamicPrimary(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, {double? maxWidth}) {
    final field = TextField(
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _filterProducts();
      },
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchProducts,
        hintStyle: TextStyle(color: AppColors.dynamicTextSecondary(context)),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.dynamicTextSecondary(context)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: field,
      );
    }
    return field;
  }

  Widget _buildEmptyProductsState(BuildContext context, AppState appState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.dynamicTextSecondary(context),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateMessage(context),
            style: TextStyle(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubMessage(context),
            style: TextStyle(color: AppColors.dynamicTextSecondary(context)),
            textAlign: TextAlign.center,
          ),
          if (appState.categories.isEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _filterProducts,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(AppLocalizations.of(context)!.refresh),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopAddButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'products_fab_hero',
      onPressed: () => _showAddChoiceDialog(context),
      backgroundColor: AppColors.dynamicPrimary(context),
      elevation: 2,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildDesktopProducts(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildSearchField(context)),
              const SizedBox(width: 16),
              _buildDesktopAddButton(context),
            ],
          ),
          const SizedBox(height: 16),
          _buildReorderableFilterChips(context, appState),
          const SizedBox(height: 16),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.dynamicSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.dynamicBorder(context).withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _filteredProducts.isEmpty
                  ? _buildEmptyProductsState(context, appState)
                  : _buildGroupedProductsList(appState, isDesktopWeb: true),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = ResponsiveLayout.isDesktopWeb(context);

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (isDesktopWeb) {
            return _buildDesktopProducts(context, appState);
          }

          return SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSearchField(context),
                      const SizedBox(height: 12),
                      _buildReorderableFilterChips(context, appState),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? _buildEmptyProductsState(context, appState)
                      : _buildGroupedProductsList(appState),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: isDesktopWeb
          ? null
          : FloatingActionButton(
              heroTag: 'products_fab_hero',
              onPressed: () => _showAddChoiceDialog(context),
              backgroundColor: AppColors.dynamicPrimary(context),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  String _getEmptyStateMessage(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    // If there's a search query, always show "No products found"
    if (_searchQuery.isNotEmpty) {
      return l10n.noProductsFound;
    }
    
    if (_selectedCategory == 'All') {
      // Check if categories exist
      if (appState.categories.isEmpty) {
        return l10n.noCategoriesFound;
      } else {
        // Categories exist but no products
        return l10n.noProductsFound;
      }
    }
    return l10n.noProductsInCategory(_selectedCategory);
  }

  String _getEmptyStateSubMessage(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    
    // If there's a search query, suggest adjusting search terms
    if (_searchQuery.isNotEmpty) {
      return l10n.tryAdjustingSearchTerms;
    }
    
    if (_selectedCategory == 'All') {
      // Check if categories exist
      if (appState.categories.isEmpty) {
        return l10n.addCategoriesToGetStarted;
      } else {
        // Categories exist but no products
        return l10n.addProductsToGetStarted;
      }
    }
    return l10n.addProductsToCategoryToGetStarted(_selectedCategory);
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

  void _showWebQuickActionsDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final hasCategories = appState.categories.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.dynamicPrimary(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.dynamicSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.quickActions,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _QuickActionTile(
                    icon: Icons.create_new_folder_outlined,
                    label: l10n.addCategory,
                    color: primary,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _showAddCategoryDialog(context);
                    },
                  ),
                  if (hasCategories) ...[
                    const SizedBox(height: 6),
                    _QuickActionTile(
                      icon: Icons.inventory_2_outlined,
                      label: l10n.addProduct,
                      color: primary,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _showCategorySelectionDialog(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: AppColors.dynamicBorder(context).withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 6),
                    _QuickActionTile(
                      icon: Icons.delete_outline_rounded,
                      label: l10n.deleteCategory,
                      color: AppColors.error,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _showDeleteCategorySelectionDialog(context);
                      },
                    ),
                    const SizedBox(height: 6),
                    _QuickActionTile(
                      icon: Icons.delete_outline_rounded,
                      label: l10n.deleteProduct,
                      color: AppColors.error,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _showDeleteSubcategorySelectionDialog(context);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddChoiceDialog(BuildContext context) {
    if (ResponsiveLayout.isDesktopWeb(context)) {
      _showWebQuickActionsDialog(context);
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final hasCategories = appState.categories.isNotEmpty;

    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(l10n.quickActions),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddCategoryDialog(context);
            },
            child: Text(l10n.addCategory),
          ),
          if (hasCategories)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _showCategorySelectionDialog(context);
              },
              child: Text(l10n.addProduct),
            ),
          if (hasCategories)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteCategorySelectionDialog(context);
              },
              child: Text(l10n.deleteCategory),
            ),
          if (hasCategories)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteSubcategorySelectionDialog(context);
              },
              child: Text(l10n.deleteProduct),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
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
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.selectCategory),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              // Limit dialog height to avoid overflow on small screens
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.chooseCategoryToAddSubcategory),
                  const SizedBox(height: 16),
                  ...categories.map((category) => ListTile(
                        title: Text(category.name),
                        subtitle: Text(l10n.subcategoriesCount('${category.subcategories.length}')),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).pop();
                          _showAddSubcategoryDialog(context, category.name);
                        },
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
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
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.addCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.categoryName,
                  hintText: l10n.categoryNameHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  final appState = Provider.of<AppState>(context, listen: false);
                  // Notification service removed
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
                    // Error adding category
                  }
                }
              },
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );
  }

  void _showEditSubcategoryDialog(BuildContext context, Subcategory subcategory, String categoryName) {
    final nameController = TextEditingController(text: subcategory.name);
    final barcodeController = TextEditingController(text: subcategory.barcode ?? '');
    String selectedCurrency = subcategory.costPriceCurrency;
    
    // Get the stored amounts in their original currency
    final double storedCostPrice = subcategory.costPrice;
    final double storedSellingPrice = subcategory.sellingPrice;
    final String storedCurrency = subcategory.costPriceCurrency;
    
    // Initialize controllers based on currency
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    bool trackInventory = subcategory.trackInventory;
    bool useBarcode = subcategory.useBarcode;
    
    // Get current exchange rate from app state
    final appState = Provider.of<AppState>(context, listen: false);
    final currentExchangeRate = appState.currencySettings?.exchangeRate;
    final lowStockThresholdController = TextEditingController(
      text: subcategory.lowStockThreshold?.toString() ?? '',
    );

    // Note: We allow editing even without exchange rate - validation happens on save
    
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

    final initialName = subcategory.name;
    final initialUseBarcode = subcategory.useBarcode;
    final initialBarcode = subcategory.barcode ?? '';
    final initialCurrency = selectedCurrency;
    final initialTrackInventory = trackInventory;
    final initialThresholdText = lowStockThresholdController.text.trim();
    final initialCostPriceText = costPriceController.text;
    final initialSellingPriceText = sellingPriceController.text;
    final isDesktopWeb = ResponsiveLayout.isDesktopWeb(context);

    Widget buildEditor(BuildContext context, StateSetter setState) {
      // Add listeners to trigger rebuild when text changes
      nameController.addListener(() => setState(() {}));
      costPriceController.addListener(() => setState(() {}));
      sellingPriceController.addListener(() => setState(() {}));
      lowStockThresholdController.addListener(() => setState(() {}));
      barcodeController.addListener(() => setState(() {}));

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: AppColors.dynamicSurface(context),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: isDesktopWeb
                ? BorderRadius.circular(16)
                : const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * (isDesktopWeb ? 0.85 : 0.92),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, isDesktopWeb ? 16 : 12, 16, 0),
                    child: Column(
                      children: [
                        if (!isDesktopWeb) ...[
                          Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.dynamicTextSecondary(context)
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Edit Product',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dynamicTextPrimary(context),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.close,
                                    color: AppColors.dynamicTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(context)!.useBarcode),
                      value: useBarcode,
                      onChanged: (value) {
                        setState(() {
                          useBarcode = value;
                        });
                      },
                    ),
                    if (useBarcode) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          final appState = Provider.of<AppState>(context, listen: false);
                          final code = barcodeController.text.trim();
                          String? barcodeError;
                          if (code.isNotEmpty) {
                            final conflict = findProductByBarcode(
                              appState.categories,
                              code,
                              excludeSubcategoryId: subcategory.id,
                            );
                            if (conflict != null) {
                              barcodeError = l10n.duplicateBarcode(conflict.subcategory.name);
                            }
                          }
                          return TextField(
                            controller: barcodeController,
                            decoration: InputDecoration(
                              labelText: l10n.barcodeProductLabel,
                              hintText: l10n.barcodeRequiredHint,
                              errorText: barcodeError,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          );
                        },
                      ),
                    ],
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
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(context)!.trackInventory),
                      value: trackInventory,
                      onChanged: (value) {
                        setState(() {
                          trackInventory = value;
                        });
                      },
                    ),
                    if (trackInventory) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: lowStockThresholdController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.productLowStockThreshold,
                          hintText: AppLocalizations.of(context)!.productLowStockThresholdHint,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                    
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
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(AppLocalizations.of(context)!.cancel),
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
                                  final hasValidStock = true;
                                  final thresholdText = lowStockThresholdController.text.trim();
                                  final parsedThreshold = int.tryParse(thresholdText);
                                  final hasValidLowStockThreshold = !trackInventory ||
                                      (thresholdText.isNotEmpty &&
                                          parsedThreshold != null &&
                                          parsedThreshold >= 0);
                                  final hasValidBarcode =
                                      !useBarcode || barcodeController.text.trim().isNotEmpty;
                                  final appStateForBarcode =
                                      Provider.of<AppState>(context, listen: false);
                                  final barcodeCode = barcodeController.text.trim();
                                  final barcodeConflict = useBarcode && barcodeCode.isNotEmpty
                                      ? findProductByBarcode(
                                          appStateForBarcode.categories,
                                          barcodeCode,
                                          excludeSubcategoryId: subcategory.id,
                                        )
                                      : null;
                                  final hasUniqueBarcode = barcodeConflict == null;
                                  final hasChanges = nameController.text.trim() != initialName ||
                                      useBarcode != initialUseBarcode ||
                                      (useBarcode &&
                                          barcodeController.text.trim() != initialBarcode) ||
                                      selectedCurrency != initialCurrency ||
                                      trackInventory != initialTrackInventory ||
                                      (trackInventory &&
                                          lowStockThresholdController.text.trim() !=
                                              initialThresholdText) ||
                                      costPriceController.text != initialCostPriceText ||
                                      sellingPriceController.text != initialSellingPriceText;
                                  
                                  final isEnabled = hasChanges &&
                                      nameController.text.trim().isNotEmpty &&
                                      costPriceController.text.isNotEmpty &&
                                      sellingPriceController.text.isNotEmpty &&
                                      hasValidStock &&
                                      hasValidLowStockThreshold &&
                                      hasValidBarcode &&
                                      hasUniqueBarcode;
                                  
                                  return ElevatedButton(
                                    onPressed: isEnabled
                                        ? () async {
                                            if (selectedCurrency == 'LBP' && (currentExchangeRate == null || currentExchangeRate <= 0)) {
                                              showCupertinoDialog(
                                                context: context,
                                                builder: (context) => CupertinoAlertDialog(
                                                  title: const Text('Exchange Rate Required'),
                                                  content: const Text('Please set an exchange rate in Currency Settings before saving products with LBP.'),
                                                  actions: [
                                                    CupertinoDialogAction(
                                                      child: Text(AppLocalizations.of(context)!.cancel),
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
                                            
                                            final appState = Provider.of<AppState>(context, listen: false);
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
                                              subcategory.useBarcode = useBarcode;
                                              if (useBarcode) {
                                                final barcodeText = barcodeController.text.trim();
                                                if (barcodeText.isEmpty) {
                                                  return;
                                                }
                                                final conflict = findProductByBarcode(
                                                  appState.categories,
                                                  barcodeText,
                                                  excludeSubcategoryId: subcategory.id,
                                                );
                                                if (conflict != null) {
                                                  return;
                                                }
                                                subcategory.barcode = barcodeText;
                                              } else {
                                                subcategory.barcode = null;
                                              }
                                              subcategory.costPrice = costPrice;
                                              subcategory.sellingPrice = sellingPrice;
                                              subcategory.costPriceCurrency = selectedCurrency;
                                              subcategory.sellingPriceCurrency = selectedCurrency;
                                              subcategory.trackInventory = trackInventory;
                                              subcategory.stockQuantity = trackInventory
                                                  ? (subcategory.stockQuantity ?? 0)
                                                  : null;
                                              if (trackInventory) {
                                                final thresholdText =
                                                    lowStockThresholdController.text.trim();
                                                if (thresholdText.isEmpty) {
                                                  return;
                                                }
                                                final parsed = int.tryParse(thresholdText);
                                                if (parsed == null || parsed < 0) {
                                                  return;
                                                }
                                                subcategory.lowStockThreshold = parsed;
                                              } else {
                                                subcategory.lowStockThreshold = null;
                                              }
                                              
                                              if (!subcategory.hasValidPrices) {
                                                return;
                                              }
                                              
                                              await appState.updateCategory(category);
                                              if (mounted) {
                                                Navigator.of(context).pop();
                                              }
                                              _filterProducts();
                                            } catch (e) {
                                              // ignore
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
    }

    if (isDesktopWeb) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                backgroundColor: AppColors.dynamicSurface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 480,
                    maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
                  ),
                  child: buildEditor(context, setState),
                ),
              );
            },
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) => buildEditor(context, setState),
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
                          // Notification service removed
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
                            _filterProducts();
                          } catch (e) {
                            // Notification removed
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
    final barcodeController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    String selectedCurrency = 'USD';
    bool trackInventory = false;
    bool useBarcode = false;
    double defaultCostPriceUSD = 0.0;
    double defaultSellingPriceUSD = 0.0;
    
    // Get current exchange rate from app state
    final appState = Provider.of<AppState>(context, listen: false);
    final currentExchangeRate = appState.currencySettings?.exchangeRate;
    final lowStockThresholdController = TextEditingController();

    // Check if exchange rate is set (only required for LBP products)
    if (selectedCurrency == 'LBP' && (currentExchangeRate == null || currentExchangeRate <= 0)) {
      final l10n = AppLocalizations.of(context)!;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.exchangeRateRequired),
          content: Text(l10n.setExchangeRateInSettings),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: Text(l10n.goToSettings),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Add listeners to trigger rebuild when text changes
            nameController.addListener(() => setState(() {}));
            costPriceController.addListener(() => setState(() {}));
            sellingPriceController.addListener(() => setState(() {}));
            lowStockThresholdController.addListener(() => setState(() {}));
            barcodeController.addListener(() => setState(() {}));
            
            final l10n = AppLocalizations.of(context)!;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Material(
                color: AppColors.dynamicSurface(context),
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.92,
                  ),
                  child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.dynamicTextSecondary(context)
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.addSubcategoryTo(categoryName),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dynamicTextPrimary(context),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.close,
                                    color: AppColors.dynamicTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.subcategoryName,
                        hintText: l10n.subcategoryNameHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.useBarcode),
                      value: useBarcode,
                      onChanged: (value) {
                        setState(() {
                          useBarcode = value;
                        });
                      },
                    ),
                    if (useBarcode) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(context, listen: false);
                          final code = barcodeController.text.trim();
                          String? barcodeError;
                          if (code.isNotEmpty) {
                            final conflict = findProductByBarcode(
                              appState.categories,
                              code,
                            );
                            if (conflict != null) {
                              barcodeError = l10n.duplicateBarcode(conflict.subcategory.name);
                            }
                          }
                          return TextField(
                            controller: barcodeController,
                            decoration: InputDecoration(
                              labelText: l10n.barcodeProductLabel,
                              hintText: l10n.barcodeRequiredHint,
                              errorText: barcodeError,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      l10n.currencyLabel,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ExpandableChipDropdown<String>(
                      label: l10n.currencyLabel,
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
                        labelText: l10n.costPrice,
                        hintText: l10n.enterCostPrice,
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
                        labelText: l10n.sellingPrice,
                        hintText: l10n.enterSellingPrice,
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
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(context)!.trackInventory),
                      value: trackInventory,
                      onChanged: (value) {
                        setState(() {
                          trackInventory = value;
                        });
                      },
                    ),
                    if (trackInventory) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: lowStockThresholdController,
                        decoration: InputDecoration(
                          labelText: l10n.productLowStockThreshold,
                          hintText: l10n.productLowStockThresholdHint,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                    
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
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(l10n.cancel),
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
                                  final hasValidStock = true;
                                  final thresholdText = lowStockThresholdController.text.trim();
                                  final parsedThreshold = int.tryParse(thresholdText);
                                  final hasValidLowStockThreshold = !trackInventory ||
                                      (thresholdText.isNotEmpty &&
                                          parsedThreshold != null &&
                                          parsedThreshold >= 0);
                                  final hasValidBarcode =
                                      !useBarcode || barcodeController.text.trim().isNotEmpty;
                                  final appStateForBarcode =
                                      Provider.of<AppState>(context, listen: false);
                                  final barcodeCode = barcodeController.text.trim();
                                  final barcodeConflict = useBarcode && barcodeCode.isNotEmpty
                                      ? findProductByBarcode(
                                          appStateForBarcode.categories,
                                          barcodeCode,
                                        )
                                      : null;
                                  final hasUniqueBarcode = barcodeConflict == null;
                                  
                                  final isEnabled = nameController.text.trim().isNotEmpty &&
                                      costPriceController.text.isNotEmpty &&
                                      sellingPriceController.text.isNotEmpty &&
                                      hasValidStock &&
                                      hasValidLowStockThreshold &&
                                      hasValidBarcode &&
                                      hasUniqueBarcode;
                                  
                                  return ElevatedButton(
                                    onPressed: isEnabled
                                        ? () async {
                                            final appState = Provider.of<AppState>(context, listen: false);
                                            final category = appState.categories.firstWhere(
                                              (cat) => cat.name == categoryName,
                                              orElse: () => ProductCategory(id: '', name: '', createdAt: DateTime.now()),
                                            );
                                            try {
                                              String cleanCostPrice = costPriceController.text.replaceAll(',', '');
                                              String cleanSellingPrice = sellingPriceController.text.replaceAll(',', '');
                                              double costPrice = double.parse(cleanCostPrice);
                                              double sellingPrice = double.parse(cleanSellingPrice);
                                              
                                              String? productBarcode;
                                              if (useBarcode) {
                                                final barcodeText = barcodeController.text.trim();
                                                if (barcodeText.isEmpty) {
                                                  return;
                                                }
                                                final conflict = findProductByBarcode(
                                                  appState.categories,
                                                  barcodeText,
                                                );
                                                if (conflict != null) {
                                                  return;
                                                }
                                                productBarcode = barcodeText;
                                              }
                                              int? productLowStockThreshold;
                                              if (trackInventory) {
                                                final thresholdText =
                                                    lowStockThresholdController.text.trim();
                                                if (thresholdText.isEmpty) {
                                                  return;
                                                }
                                                final parsed = int.tryParse(thresholdText);
                                                if (parsed == null || parsed < 0) {
                                                  return;
                                                }
                                                productLowStockThreshold = parsed;
                                              }
                                              final subcategory = Subcategory(
                                                id: appState.generateProductPurchaseId(),
                                                name: nameController.text.trim(),
                                                description: null,
                                                costPrice: costPrice,
                                                sellingPrice: sellingPrice,
                                                createdAt: DateTime.now(),
                                                costPriceCurrency: selectedCurrency,
                                                sellingPriceCurrency: selectedCurrency,
                                                trackInventory: trackInventory,
                                                stockQuantity: trackInventory
                                                    ? 0
                                                    : null,
                                                useBarcode: useBarcode,
                                                barcode: productBarcode,
                                                lowStockThreshold: productLowStockThreshold,
                                              );
                                              
                                              if (!subcategory.hasValidPrices) {
                                                return;
                                              }
                                              if (category.id.isEmpty) {
                                                return;
                                              }
                                              category.subcategories.add(subcategory);
                                              await appState.updateCategory(category);
                                              if (context.mounted) {
                                                Navigator.of(context).pop();
                                              }
                                              if (mounted) _filterProducts();
                                            } catch (e) {
                                              // ignore
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
                                    child: Text(isLoss ? l10n.confirm : l10n.add),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSubcategorySelectionDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final categories = appState.categories.toList();

    // Check if any category has subcategories
    final hasSubcategories = categories.any((category) => category.subcategories.isNotEmpty);

    if (!hasSubcategories) {
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
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Choose a category first:'),
                  const SizedBox(height: 16),
                  ...categories.where((category) => category.subcategories.isNotEmpty).map((category) => ListTile(
                    title: Text(category.name),
                    subtitle: Text('${category.subcategories.length} subcategories'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showDeleteSubcategoryFromCategoryDialog(context, category);
                    },
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSubcategoryFromCategoryDialog(BuildContext context, ProductCategory category) {
    final subcategories = category.subcategories.toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete from ${category.name}'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Choose a subcategory to delete:'),
                  const SizedBox(height: 16),
                  ...subcategories.map((subcategory) => ListTile(
                    title: Text(subcategory.name),
                    trailing: const Icon(Icons.delete, color: Colors.red),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showDeleteSubcategoryConfirmationDialog(context, subcategory, category);
                    },
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showCategoryActionSheet(BuildContext context, ProductCategory category) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          category.name,
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditCategoryNameDialog(context, category);
            },
            child: const Text('Edit Name'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isReorderMode = true;
              });
            },
            child: const Text('Reorder Categories'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ),
    );
  }

  void _showEditCategoryNameDialog(BuildContext context, ProductCategory category) {
    final nameController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Category Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Electronics',
                ),
                autofocus: true,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _updateCategoryName(context, category, value.trim());
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  _updateCategoryName(context, category, nameController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dynamicPrimary(context),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCategoryName(BuildContext context, ProductCategory category, String newName) async {
    // Check if name already exists (excluding current category)
    final appState = Provider.of<AppState>(context, listen: false);
    final nameExists = appState.categories.any(
      (cat) => cat.name.toLowerCase() == newName.toLowerCase() && cat.id != category.id
    );

    if (nameExists) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Category Name Exists'),
          content: Text('A category with the name "$newName" already exists. Please choose a different name.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final updatedCategory = category.copyWith(name: newName);
      await appState.updateCategory(updatedCategory);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close edit dialog
        
        // Update selected category if it was the one being edited
        if (_selectedCategory == category.name) {
          setState(() {
            _selectedCategory = newName;
          });
        }
        
        _filterProducts();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to update category name. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
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
                          // Notification service removed
                          
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
                            // Notification removed
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
                          // Notification service removed
                          
                          try {
                            await appState.deleteSubcategory(category.id, subcategory.id);
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                            
                            // Show success notification
                            
                            // Refresh the products list
                            _filterProducts();
                          } catch (e) {
                            // Show error notification
                            // Notification removed
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

class _DesktopProductTableColumns {
  _DesktopProductTableColumns._();

  static const double horizontalPadding = 20;
  static const double costWidth = 100;
  static const double priceWidth = 100;
  static const double revenueWidth = 110;
  static const double stockWidth = 130;
}

class _DesktopProductsTableHeader extends StatelessWidget {
  const _DesktopProductsTableHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = TextStyle(
      color: AppColors.dynamicTextSecondary(context),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _DesktopProductTableColumns.horizontalPadding,
        vertical: 14,
      ),
      child: Row(
        children: [
          Expanded(child: Text(l10n.productLabel, style: labelStyle)),
          SizedBox(
            width: _DesktopProductTableColumns.costWidth,
            child: Text(l10n.productCost, style: labelStyle),
          ),
          SizedBox(
            width: _DesktopProductTableColumns.priceWidth,
            child: Text(l10n.productPrice, style: labelStyle),
          ),
          SizedBox(
            width: _DesktopProductTableColumns.revenueWidth,
            child: Text(l10n.productRevenue, style: labelStyle),
          ),
          SizedBox(
            width: _DesktopProductTableColumns.stockWidth,
            child: Text(
              l10n.quantity,
              style: labelStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Subcategory subcategory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? categoryName;
  final bool desktopRow;

  const _ProductCard({
    required this.subcategory,
    required this.onEdit,
    required this.onDelete,
    this.categoryName,
    this.desktopRow = false,
  });

  static const double _productChipHeight = 36;

  bool get _showsBarcode =>
      subcategory.useBarcode &&
      (subcategory.barcode?.trim().isNotEmpty ?? false);

  Widget _buildProductChip(
    BuildContext context, {
    required IconData icon,
    required Color color,
    String? label,
    required String value,
    Color? valueColor,
  }) {
    final displayValueColor = valueColor ?? AppColors.dynamicTextPrimary(context);
    final showLabel = label != null && label.isNotEmpty;

    return Container(
      height: _productChipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            fit: FlexFit.loose,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: showLabel
                  ? RichText(
                      maxLines: 1,
                      softWrap: false,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                        children: [
                          TextSpan(text: '$label: '),
                          TextSpan(
                            text: value,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: displayValueColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: displayValueColor,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildProductChip(
      context,
      icon: Icons.qr_code_2,
      color: AppColors.dynamicPrimary(context),
      label: l10n.barcodeLabel,
      value: subcategory.barcode!.trim(),
    );
  }

  Widget _buildStockStatusChip(
    BuildContext context, {
    required Color badgeColor,
    required IconData badgeIcon,
    required String value,
  }) {
    return _buildProductChip(
      context,
      icon: badgeIcon,
      color: badgeColor,
      value: value,
      valueColor: badgeColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (desktopRow) {
      return _buildDesktopRow(context);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductActionSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<AppState>(
                builder: (context, appState, child) {
                  final showExchange = appState.currencySettings?.exchangeRate != null &&
                      (subcategory.costPriceCurrency == 'LBP' ||
                          subcategory.sellingPriceCurrency == 'LBP');
                  final stock = subcategory.stockQuantity ?? 0.0;
                  final stockText = _formatStockQuantity(stock);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              subcategory.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dynamicTextPrimary(context),
                              ),
                            ),
                            if (showExchange) ...[
                              const SizedBox(height: 4),
                              _buildExchangeRateChip(
                                context,
                                appState.currencySettings!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (subcategory.trackInventory) ...[
                        const SizedBox(width: 8),
                        _buildStockStepper(
                          context,
                          stockText: stockText,
                          currentStock: stock,
                          onManualEdit: (manualStock) =>
                              _updateStockQuantity(context, appState, manualStock),
                          onDecrease: stock > 0
                              ? () => _updateStockQuantity(context, appState, stock - 1)
                              : null,
                          onIncrease: () =>
                              _updateStockQuantity(context, appState, stock + 1),
                        ),
                      ],
                    ],
                  );
                },
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
              const SizedBox(height: 8),
              _buildStatusChipRow(context),
              const SizedBox(height: 12),
            Consumer<AppState>(
              builder: (context, appState, child) {
                final l10n = AppLocalizations.of(context)!;
                // Get actual ProductPurchase data for this subcategory
                final productPurchases = appState.productPurchases
                    .where((p) => p.subcategoryName == subcategory.name)
                    .toList();
                

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
                

                
                final costValue = subcategory.costPriceCurrency == 'LBP'
                    ? CurrencyFormatter.getFormattedUSDForProductDisplay(
                        context, subcategory.costPrice, storedCurrency: 'LBP')
                    : '${totalCost.toStringAsFixed(2)}\$';
                final priceValue = subcategory.sellingPriceCurrency == 'LBP'
                    ? CurrencyFormatter.getFormattedUSDForProductDisplay(
                        context, subcategory.sellingPrice, storedCurrency: 'LBP')
                    : '${totalPrice.toStringAsFixed(2)}\$';
                final revenueValue = subcategory.sellingPriceCurrency == 'LBP'
                    ? CurrencyFormatter.getFormattedUSDForProductDisplay(
                        context, subcategory.profit, storedCurrency: 'LBP')
                    : '${totalRevenue.toStringAsFixed(2)}\$';

                return Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        l10n.productCost,
                        costValue,
                        Icons.shopping_cart,
                        AppColors.dynamicWarning(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        l10n.productPrice,
                        priceValue,
                        Icons.attach_money,
                        AppColors.dynamicPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        totalRevenue >= 0 ? l10n.productRevenue : l10n.productLoss,
                        revenueValue,
                        Icons.trending_up,
                        totalRevenue >= 0
                            ? AppColors.dynamicSuccess(context)
                            : AppColors.error,
                      ),
                    ),
                  ],
                );
              },
            ),

            ],
          ),
        ),
      ),
    );
  }

  ({
    Color color,
    IconData icon,
    String value,
  }) _stockStatusParts(BuildContext context) {
    final stock = subcategory.stockQuantity ?? 0.0;
    final threshold = subcategory.lowStockThreshold;
    final stockText = stock.toStringAsFixed(stock % 1 == 0 ? 0 : 2);
    final isLow = subcategory.trackInventory &&
        threshold != null &&
        stock > 0 &&
        stock <= threshold;
    final isOut = subcategory.trackInventory && stock <= 0;

    if (!subcategory.trackInventory) {
      return (
        color: AppColors.dynamicTextSecondary(context),
        icon: Icons.inventory_2_outlined,
        value: 'Not tracked',
      );
    }
    if (isOut) {
      return (
        color: AppColors.error,
        icon: Icons.error_outline,
        value: 'Out of stock',
      );
    }
    if (isLow) {
      return (
        color: AppColors.dynamicWarning(context),
        icon: Icons.warning_amber_rounded,
        value: 'Low · $stockText',
      );
    }
    return (
      color: AppColors.dynamicSuccess(context),
      icon: Icons.check_circle_outline,
      value: 'In stock · $stockText',
    );
  }

  Widget _buildStatusChipRow(BuildContext context) {
    final stock = _stockStatusParts(context);
    final isDesktopWeb = ResponsiveLayout.isDesktopWeb(context);

    if (isDesktopWeb) {
      return Row(
        children: [
          if (_showsBarcode) ...[
            Expanded(
              flex: 3,
              child: _buildBarcodeChip(context),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStockStatusChip(
                context,
                badgeColor: stock.color,
                badgeIcon: stock.icon,
                value: stock.value,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (_showsBarcode) ...[
          Expanded(
            flex: 2,
            child: _buildBarcodeChip(context),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 1,
          child: _buildStockStatusChip(
            context,
            badgeColor: stock.color,
            badgeIcon: stock.icon,
            value: stock.value,
          ),
        ),
      ],
    );
  }

  ({String cost, String price, String revenue, bool revenuePositive}) _financialValues(
    BuildContext context,
    AppState appState,
  ) {
    final productPurchases = appState.productPurchases
        .where((p) => p.subcategoryName == subcategory.name)
        .toList();

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
      totalCost = subcategory.costPrice;
      totalPrice = subcategory.sellingPrice;
      totalRevenue = subcategory.profit;

      if (appState.currencySettings?.exchangeRate != null &&
          (subcategory.costPriceCurrency == 'LBP' ||
              subcategory.sellingPriceCurrency == 'LBP')) {
        final exchangeRate = appState.currencySettings!.exchangeRate!;
        totalCost = totalCost / exchangeRate;
        totalPrice = totalPrice / exchangeRate;
        totalRevenue = totalRevenue / exchangeRate;
      }
    }

    final costValue = subcategory.costPriceCurrency == 'LBP'
        ? CurrencyFormatter.getFormattedUSDForProductDisplay(
            context, subcategory.costPrice, storedCurrency: 'LBP')
        : '${totalCost.toStringAsFixed(2)}\$';
    final priceValue = subcategory.sellingPriceCurrency == 'LBP'
        ? CurrencyFormatter.getFormattedUSDForProductDisplay(
            context, subcategory.sellingPrice, storedCurrency: 'LBP')
        : '${totalPrice.toStringAsFixed(2)}\$';
    final revenueValue = subcategory.sellingPriceCurrency == 'LBP'
        ? CurrencyFormatter.getFormattedUSDForProductDisplay(
            context, subcategory.profit, storedCurrency: 'LBP')
        : '${totalRevenue.toStringAsFixed(2)}\$';

    return (
      cost: costValue,
      price: priceValue,
      revenue: revenueValue,
      revenuePositive: totalRevenue >= 0,
    );
  }

  Widget _buildDesktopRow(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final values = _financialValues(context, appState);
        final revenueColor = values.revenuePositive
            ? AppColors.dynamicSuccess(context)
            : AppColors.error;
        final stock = subcategory.stockQuantity ?? 0.0;
        final stockText = _formatStockQuantity(stock);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showProductActionSheet(context),
            hoverColor: AppColors.dynamicPrimary(context).withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _DesktopProductTableColumns.horizontalPadding,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subcategory.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _buildStatusChipRow(context),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: _DesktopProductTableColumns.costWidth,
                    child: Text(
                      values.cost,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.dynamicWarning(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _DesktopProductTableColumns.priceWidth,
                    child: Text(
                      values.price,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.dynamicPrimary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _DesktopProductTableColumns.revenueWidth,
                    child: Text(
                      values.revenue,
                      style: TextStyle(
                        fontSize: 14,
                        color: revenueColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _DesktopProductTableColumns.stockWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: subcategory.trackInventory
                          ? _buildStockStepper(
                              context,
                              stockText: stockText,
                              currentStock: stock,
                              onManualEdit: (manualStock) => _updateStockQuantity(
                                context,
                                appState,
                                manualStock,
                              ),
                              onDecrease: stock > 0
                                  ? () => _updateStockQuantity(
                                        context,
                                        appState,
                                        stock - 1,
                                      )
                                  : null,
                              onIncrease: () => _updateStockQuantity(
                                context,
                                appState,
                                stock + 1,
                              ),
                            )
                          : Text(
                              '—',
                              style: TextStyle(
                                color: AppColors.dynamicTextSecondary(context),
                              ),
                              textAlign: TextAlign.end,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProductActionSheet(BuildContext context) {
    if (ResponsiveLayout.isDesktopWeb(context)) {
      _showProductWebActionDialog(context);
      return;
    }

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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ),
    );
  }

  void _showProductWebActionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.dynamicPrimary(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.dynamicSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subcategory.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _QuickActionTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: primary,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      onEdit();
                    },
                  ),
                  const SizedBox(height: 6),
                  _QuickActionTile(
                    icon: Icons.delete_outline_rounded,
                    label: l10n.delete,
                    color: AppColors.error,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      onDelete();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    return fw.Directionality(
      textDirection: fw.TextDirection.ltr,
      child: _buildProductChip(
        context,
        icon: icon,
        color: color,
        label: label,
        value: value,
        valueColor: color,
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

  String _formatStockQuantity(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  Widget _buildStockStepper(
    BuildContext context, {
    required String stockText,
    required double currentStock,
    required ValueChanged<double> onManualEdit,
    required VoidCallback? onDecrease,
    required VoidCallback onIncrease,
  }) {
    final primary = AppColors.dynamicPrimary(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStockStepperShapeButton(
          context,
          icon: Icons.remove_rounded,
          color: primary,
          enabled: onDecrease != null,
          onPressed: onDecrease,
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () async {
            final manualStock =
                await _showStockQuantityDialog(context, currentStock);
            if (manualStock == null) return;
            HapticFeedback.selectionClick();
            onManualEdit(manualStock);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.dynamicBorder(context).withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              stockText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.dynamicTextPrimary(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildStockStepperShapeButton(
          context,
          icon: Icons.add_rounded,
          color: primary,
          enabled: true,
          onPressed: onIncrease,
        ),
      ],
    );
  }

  Widget _buildStockStepperShapeButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    const double size = 34;
    final disabledColor = AppColors.dynamicTextSecondary(context).withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && onPressed != null
            ? () {
                HapticFeedback.selectionClick();
                onPressed();
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: enabled ? color.withValues(alpha: 0.12) : Colors.transparent,
            border: Border.all(
              color: enabled ? color.withValues(alpha: 0.45) : disabledColor,
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: enabled ? color : disabledColor,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStockQuantity(
    BuildContext context,
    AppState appState,
    double nextStock,
  ) async {
    final double safeStock = nextStock < 0 ? 0.0 : nextStock;

    try {
      final categoryIndex = appState.categories.indexWhere(
        (category) => category.subcategories.any((item) => item.id == subcategory.id),
      );
      if (categoryIndex == -1) return;

      final updatedCategory = appState.categories[categoryIndex];
      final subcategoryIndex = updatedCategory.subcategories.indexWhere((item) => item.id == subcategory.id);
      if (subcategoryIndex == -1) return;

      updatedCategory.subcategories[subcategoryIndex].stockQuantity = safeStock;
      await appState.updateCategory(updatedCategory);
    } catch (_) {
      // Ignore stock control update errors to keep the card responsive.
    }
  }

  Future<double?> _showStockQuantityDialog(
    BuildContext context,
    double currentStock,
  ) async {
    final controller = TextEditingController(text: _formatStockQuantity(currentStock));
    String? errorText;

    return showCupertinoDialog<double>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: const Text('Set stock quantity'),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      placeholder: 'Enter quantity',
                      autofocus: true,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    final parsed = double.tryParse(controller.text.trim());
                    if (parsed == null || parsed < 0) {
                      setState(() {
                        errorText = 'Please enter a valid number';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(parsed);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ProductCategory category;
  final List<Subcategory> subcategories;
  final Function(Subcategory) onEditProduct;
  final Function(Subcategory) onDeleteProduct;
  final bool desktopTable;

  const _CategorySection({
    required this.category,
    required this.subcategories,
    required this.onEditProduct,
    required this.onDeleteProduct,
    this.desktopTable = false,
  });

  @override
  Widget build(BuildContext context) {
    final header = Container(
      margin: EdgeInsets.only(
        top: desktopTable ? 12 : 16,
        bottom: desktopTable ? 8 : 12,
        left: 16,
        right: 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dynamicPrimary(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.dynamicPrimary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_rounded,
            color: AppColors.dynamicPrimary(context),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: desktopTable ? 15 : 18,
                fontWeight: FontWeight.w600,
                color: AppColors.dynamicPrimary(context),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.dynamicPrimary(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${subcategories.length} product${subcategories.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (desktopTable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const _DesktopProductsTableHeader(),
          const Divider(height: 1),
          ...subcategories.map(
            (subcategory) => Column(
              children: [
                _ProductCard(
                  subcategory: subcategory,
                  onEdit: () => onEditProduct(subcategory),
                  onDelete: () => onDeleteProduct(subcategory),
                  desktopRow: true,
                ),
                Divider(
                  height: 1,
                  color: AppColors.dynamicBorder(context).withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        ...subcategories.map(
          (subcategory) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProductCard(
              subcategory: subcategory,
              onEdit: () => onEditProduct(subcategory),
              onDelete: () => onDeleteProduct(subcategory),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: color.withValues(alpha: 0.14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}