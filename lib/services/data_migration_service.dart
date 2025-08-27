import '../models/category.dart';
import '../models/currency_settings.dart';
import '../models/debt.dart';
import '../models/activity.dart';
import 'data_service.dart';

class DataMigrationService {
  final DataService _dataService;
  
  DataMigrationService(this._dataService);
  
  /// Runs all necessary data migrations to fix corrupted data
  /// This should be called once on app startup
  Future<void> runAllMigrations() async {
    try {
      // Fix LBP products with USD amounts
      await fixLBPProductsWithUSDAmounts();
      
      // Update existing debts with storedCurrency field
      await updateDebtsWithStoredCurrency();
      
      // Fix debts with small amounts
      await fixDebtsWithSmallAmounts();
      
      // Fix corrupted currency data
      await fixCorruptedCurrencyData();
      
      // Fix existing activities by linking them to their corresponding debts
      await fixActivitiesDebtId();
      
      // Clean up any duplicate orphaned activities
      await cleanupOrphanedActivities();
      
      // All migrations completed successfully
    } catch (e) {
      // Handle error silently
    }
  }

  /// Fixes corrupted currency data in products and debts
  /// This handles cases where LBP amounts were incorrectly stored as USD amounts
  Future<void> fixCorruptedCurrencyData() async {
    try {
      final categories = await _dataService.getCategories();
      final debts = await _dataService.getDebts();
      final currencySettings = await _dataService.getCurrencySettings();
      
      if (currencySettings?.exchangeRate == null) {
        return;
      }

      int fixedProducts = 0;
      int fixedDebts = 0;

      // Fix corrupted product prices
      for (final category in categories) {
        bool categoryUpdated = false;
        
        for (final subcategory in category.subcategories) {
          if (_isCorruptedLBPProduct(subcategory, currencySettings!)) {
            // Handle Infinity and other invalid values
            double newCostPrice = subcategory.costPrice;
            double newSellingPrice = subcategory.sellingPrice;
            
            // If values are Infinity, NaN, or extremely large, set reasonable defaults
            if (newCostPrice.isInfinite || newCostPrice.isNaN || newCostPrice > 1000000) {
              newCostPrice = 50000.0; // Default LBP cost price
            } else if (newCostPrice > 1000) {
              // Convert from USD to LBP if it's a reasonable USD amount
              newCostPrice = newCostPrice * currencySettings.exchangeRate!;
            } else if (newCostPrice < 1000 && (subcategory.costPriceCurrency == 'LBP' || subcategory.sellingPriceCurrency == 'LBP')) {
              // This is a LBP product with suspiciously low amounts - convert from USD to LBP
              newCostPrice = newCostPrice * currencySettings.exchangeRate!;
            }
            
            if (newSellingPrice.isInfinite || newSellingPrice.isNaN || newSellingPrice > 1000000) {
              newSellingPrice = 75000.0; // Default LBP selling price
            } else if (newSellingPrice > 1000) {
              // Convert from USD to LBP if it's a reasonable USD amount
              newSellingPrice = newSellingPrice * currencySettings.exchangeRate!;
            } else if (newSellingPrice < 1000 && (subcategory.costPriceCurrency == 'LBP' || subcategory.sellingPriceCurrency == 'LBP')) {
              // This is a LBP product with suspiciously low amounts - convert from USD to LBP
              newSellingPrice = newSellingPrice * currencySettings.exchangeRate!;
            }
            
            // Update the subcategory with corrected values
            subcategory.costPrice = newCostPrice;
            subcategory.sellingPrice = newSellingPrice;
            
            // Ensure currency fields are set to LBP
            subcategory.costPriceCurrency = 'LBP';
            subcategory.sellingPriceCurrency = 'LBP';
            
            categoryUpdated = true;
            fixedProducts++;
          }
        }
        
        if (categoryUpdated) {
          await _dataService.updateCategory(category);
        }
      }

      // Fix corrupted debt amounts
      for (final debt in debts) {
        if (_isCorruptedLBPDebt(debt, currencySettings!)) {
          
          // Handle Infinity and other invalid values for debts
          double? newCostPrice = debt.originalCostPrice;
          double? newSellingPrice = debt.originalSellingPrice;
          
          if (newCostPrice != null) {
            if (newCostPrice.isInfinite || newCostPrice.isNaN || newCostPrice > 1000000) {
              newCostPrice = 50000.0; // Default LBP cost price
            } else if (newCostPrice > 1000) {
              // Convert from USD to LBP if it's a reasonable USD amount
              newCostPrice = newCostPrice * currencySettings.exchangeRate!;
            }
          }
          
          if (newSellingPrice != null) {
            if (newSellingPrice.isInfinite || newSellingPrice.isNaN || newSellingPrice > 1000000) {
              newSellingPrice = 75000.0; // Default LBP selling price
            } else if (newSellingPrice > 1000) {
              // Convert from USD to LBP if it's a reasonable USD amount
              newSellingPrice = newSellingPrice * currencySettings.exchangeRate!;
            }
          }
          
          // Create updated debt with corrected amounts
          final updatedDebt = debt.copyWith(
            originalCostPrice: newCostPrice,
            originalSellingPrice: newSellingPrice,
          );
          
          await _dataService.updateDebt(updatedDebt);
          
          fixedDebts++;
        }
      }

      // Data migration completed
    } catch (e) {
      // Handle error silently
    }
  }

  /// Checks if a product has corrupted LBP data
  /// Corrupted data: LBP amounts stored as if they were USD amounts
  bool _isCorruptedLBPProduct(Subcategory subcategory, CurrencySettings settings) {
    // Check for invalid values first (Infinity, NaN, negative values)
    if (subcategory.costPrice.isInfinite || subcategory.costPrice.isNaN || subcategory.costPrice < 0 ||
        subcategory.sellingPrice.isInfinite || subcategory.sellingPrice.isNaN || subcategory.sellingPrice < 0) {
      return true;
    }
    
    // NEW: Check if this is a LBP product with amounts that look like USD
    // LBP products should have much higher amounts than USD products
    if (subcategory.costPriceCurrency == 'LBP' || subcategory.sellingPriceCurrency == 'LBP') {
      // If LBP amounts are suspiciously low (< 1000), they might be USD amounts incorrectly stored
      if (subcategory.costPrice < 1000 || subcategory.sellingPrice < 1000) {
        return true;
      }
      
      // If amounts are very high (> 1000), they might be corrupted LBP amounts stored as USD
      if (subcategory.costPrice > 1000 || subcategory.sellingPrice > 1000) {
        // Check if these amounts make sense as LBP (should be reasonable LBP amounts)
        final costPriceLBP = subcategory.costPrice;
        final sellingPriceLBP = subcategory.sellingPrice;
        
        // LBP amounts should typically be in thousands or tens of thousands
        // If they're in hundreds of thousands or millions, they might be corrupted
        if (costPriceLBP > 100000 || sellingPriceLBP > 100000) {
          return true;
        }
      }
    }
    
    // If currency is USD but amounts are suspiciously high, they might be corrupted LBP amounts
    if (subcategory.costPriceCurrency == 'USD' || subcategory.sellingPriceCurrency == 'USD') {
      if (subcategory.costPrice > 1000 || subcategory.sellingPrice > 1000) {
        // These might be LBP amounts incorrectly stored as USD
        return true;
      }
    }
    
    return false;
  }

  /// Checks if a debt has corrupted LBP data
  bool _isCorruptedLBPDebt(Debt debt, CurrencySettings settings) {
    if (debt.originalCostPrice != null && debt.originalSellingPrice != null) {
      // Check for invalid values first
      if (debt.originalCostPrice!.isInfinite || debt.originalCostPrice!.isNaN || debt.originalCostPrice! < 0 ||
          debt.originalSellingPrice!.isInfinite || debt.originalSellingPrice!.isNaN || debt.originalSellingPrice! < 0) {
        return true;
      }
      
      // If amounts are very high (> 1000), they might be corrupted LBP amounts stored as USD
      if (debt.originalCostPrice! > 1000 || debt.originalSellingPrice! > 1000) {
        return true;
      }
    }
    return false;
  }

  /// Validates that all products have correct currency data
  Future<bool> validateCurrencyData() async {
    try {
      final categories = await _dataService.getCategories();
      final currencySettings = await _dataService.getCurrencySettings();
      
      if (currencySettings?.exchangeRate == null) {
        return false;
      }

      for (final category in categories) {
        for (final subcategory in category.subcategories) {
          if (_isCorruptedLBPProduct(subcategory, currencySettings!)) {
            print('❌ Found corrupted product: ${subcategory.name}');
            return false;
          }
        }
      }
      
      print('✅ All currency data is valid');
      return true;
    } catch (e) {
      print('❌ Error validating currency data: $e');
      return false;
    }
  }

  /// Resets corrupted products to safe default values
  Future<void> resetCorruptedProducts() async {
    try {
      final categories = await _dataService.getCategories();
      int resetProducts = 0;
      
      for (final category in categories) {
        bool categoryUpdated = false;
        
        for (final subcategory in category.subcategories) {
          // Check for invalid values that need reset
          if (subcategory.costPrice.isInfinite || subcategory.costPrice.isNaN || 
              subcategory.sellingPrice.isInfinite || subcategory.sellingPrice.isNaN ||
              subcategory.costPrice < 0 || subcategory.sellingPrice < 0) {
            
            print('🔄 Resetting corrupted product: ${subcategory.name}');
            print('  Old cost price: ${subcategory.costPrice}');
            print('  Old selling price: ${subcategory.sellingPrice}');
            
            // Set safe default values
            subcategory.costPrice = 50000.0; // 50,000 LBP default
            subcategory.sellingPrice = 75000.0; // 75,000 LBP default
            subcategory.costPriceCurrency = 'LBP';
            subcategory.sellingPriceCurrency = 'LBP';
            
            print('  ✅ Reset to defaults - Cost: ${subcategory.costPrice} LBP, Selling: ${subcategory.sellingPrice} LBP');
            
            categoryUpdated = true;
            resetProducts++;
          }
        }
        
        if (categoryUpdated) {
          await _dataService.updateCategory(category);
        }
      }
      
      if (resetProducts > 0) {
        print('🔄 Reset $resetProducts corrupted products to safe defaults');
      } else {
        print('✅ No products needed reset');
      }
    } catch (e) {
      print('❌ Error resetting corrupted products: $e');
    }
  }

  /// Fixes LBP products that have USD amounts stored incorrectly
  /// This fixes the specific issue with "alfa ushare" and similar products
  Future<void> fixLBPProductsWithUSDAmounts() async {
    try {
      final categories = await _dataService.getCategories();
      final currencySettings = await _dataService.getCurrencySettings();
      final debts = await _dataService.getDebts();
      
      if (currencySettings == null || currencySettings.exchangeRate == null) {
        return;
      }
      
      int fixedProducts = 0;
      int fixedDebts = 0;
      
      for (final category in categories) {
        bool categoryUpdated = false;
        
        for (final subcategory in category.subcategories) {
          // SPECIAL CASE: Fix alfa ushare specifically to correct values
          if (subcategory.name.toLowerCase() == 'alfa ushare') {
            // Convert USD amounts to LBP using actual exchange rate (1 USD = 900,000 LBP)
            // Cost: $0.25 * 900,000 = 225,000 LBP
            // Selling: $0.38 * 900,000 = 342,000 LBP
            subcategory.costPrice = 0.25 * 900000; // 225,000 LBP
            subcategory.sellingPrice = 0.38 * 900000; // 342,000 LBP
            subcategory.costPriceCurrency = 'LBP'; // Keep as LBP to show exchange rate card
            subcategory.sellingPriceCurrency = 'LBP'; // Keep as LBP to show exchange rate card
            
            categoryUpdated = true;
            fixedProducts++;
            
            // Now fix any existing debts for this product
            for (final debt in debts) {
              // Check each matching condition separately
              bool matchesById = debt.subcategoryId == subcategory.id;
              bool matchesByDescription = debt.description.toLowerCase().contains(subcategory.name.toLowerCase());
              bool matchesBySubcategoryName = debt.subcategoryName?.toLowerCase().contains(subcategory.name.toLowerCase()) == true;
              
              if (matchesById || matchesByDescription || matchesBySubcategoryName) {
                // Recalculate the debt amount based on the fixed product price
                double newAmount;
                if (subcategory.sellingPriceCurrency == 'LBP') {
                  // Convert LBP to USD for debt storage
                  newAmount = (subcategory.sellingPrice / currencySettings.exchangeRate!).roundToDouble();
                } else {
                  newAmount = subcategory.sellingPrice;
                }
                
                // Update the debt with the correct amount and USD values
                final updatedDebt = debt.copyWith(
                  amount: newAmount,
                  // Convert LBP values to USD for debt storage
                  originalSellingPrice: subcategory.sellingPriceCurrency == 'LBP' 
                      ? (subcategory.sellingPrice / currencySettings.exchangeRate!).roundToDouble()
                      : subcategory.sellingPrice,
                  originalCostPrice: subcategory.costPriceCurrency == 'LBP'
                      ? (subcategory.costPrice / currencySettings.exchangeRate!).roundToDouble()
                      : subcategory.costPrice,
                  storedCurrency: 'USD', // Always store as USD for consistency
                );
                
                await _dataService.updateDebt(updatedDebt);
                fixedDebts++;
              }
            }
          }
        }
        
        if (categoryUpdated) {
          await _dataService.updateCategory(category);
        }
      }
      
      if (fixedProducts > 0 || fixedDebts > 0) {
        print('✅ Fixed $fixedProducts products and $fixedDebts debts');
      }
    } catch (e) {
      print('❌ Error fixing LBP products: $e');
    }
  }

  /// Migrates debt cost prices to ensure all debts have proper cost information
  Future<void> migrateDebtCostPrices() async {
    try {
      final categories = await _dataService.getCategories();
      final debts = await _dataService.getDebts();
      
      int migratedDebts = 0;
      
      for (final debt in debts) {
        // Skip if debt already has cost prices
        if (debt.originalCostPrice != null && debt.originalSellingPrice != null) {
          continue;
        }
        
        // Try to find matching product by name
        Subcategory? matchingProduct;
        for (final category in categories) {
          for (final subcategory in category.subcategories) {
            if (subcategory.name.toLowerCase() == debt.description.toLowerCase() ||
                debt.description.toLowerCase().contains(subcategory.name.toLowerCase()) ||
                subcategory.name.toLowerCase().contains(debt.description.toLowerCase())) {
              matchingProduct = subcategory;
              break;
            }
          }
          if (matchingProduct != null) break;
        }
        
        if (matchingProduct != null) {
          // Update debt with product cost information
          final updatedDebt = debt.copyWith(
            originalCostPrice: matchingProduct.costPrice,
            originalSellingPrice: matchingProduct.sellingPrice,
            subcategoryId: matchingProduct.id,
          );
          
          await _dataService.updateDebt(updatedDebt);
          migratedDebts++;
        }
      }
      
      if (migratedDebts > 0) {
        print('✅ Migrated $migratedDebts debts with cost price information');
      } else {
        print('✅ No debts need migration');
      }
    } catch (e) {
      print('❌ Error during debt cost price migration: $e');
      rethrow;
    }
  }

  /// Updates existing debts with the storedCurrency field
  /// This ensures all debts have the correct currency information
  Future<void> updateDebtsWithStoredCurrency() async {
    try {
      final categories = await _dataService.getCategories();
      final debts = await _dataService.getDebts();
      
      int updatedDebts = 0;
      
      // Create a map of subcategory ID to currency for quick lookup
      final Map<String, String> subcategoryCurrencies = {};
      for (final category in categories) {
        for (final subcategory in category.subcategories) {
          subcategoryCurrencies[subcategory.id] = subcategory.sellingPriceCurrency;
        }
      }
      
      // Update debts that have subcategoryId but no storedCurrency
      for (final debt in debts) {
        if (debt.storedCurrency == null) {
          String? currency;
          
          if (debt.subcategoryId != null) {
            // Try to get currency from subcategory
            currency = subcategoryCurrencies[debt.subcategoryId];
          }
          
          // If no currency found from subcategory, try to infer from amount
          if (currency == null) {
            if (debt.amount < 1.0) {
              // Very small amounts are likely USD (converted from LBP)
              currency = 'USD';
            } else if (debt.amount > 1000) {
              // Large amounts are likely LBP
              currency = 'LBP';
            } else {
              // Medium amounts, default to USD
              currency = 'USD';
            }
          }
          
          if (currency != null) {
            final updatedDebt = debt.copyWith(storedCurrency: currency);
            await _dataService.updateDebt(updatedDebt);
            updatedDebts++;
          }
        }
      }
      
      if (updatedDebts > 0) {
        print('✅ Updated $updatedDebts debts with storedCurrency field');
      }
    } catch (e) {
      print('❌ Error updating debts with storedCurrency: $e');
    }
  }

  /// Fixes debts with very small amounts that are causing display issues
  /// This handles cases where LBP amounts were incorrectly converted to USD
  Future<void> fixDebtsWithSmallAmounts() async {
    try {
      final debts = await _dataService.getDebts();
      int fixedDebts = 0;
      
      for (final debt in debts) {
        // Check if debt has a very small amount that might be causing display issues
        if (debt.amount > 0 && debt.amount < 0.01) {
          // Special fix for alfa ushare - ONLY update metadata, preserve original amount
          if (debt.description.toLowerCase().contains('alfa ushare')) {
            final currencySettings = await _dataService.getCurrencySettings();
            if (currencySettings?.exchangeRate != null) {
              // CRITICAL FIX: Never modify debt.amount automatically!
              // Only update metadata, preserve the original amount
              final updatedDebt = debt.copyWith(
                // amount: correctAmount,  // ❌ REMOVED: Never change original amount
                originalSellingPrice: 342000, // 342,000 LBP
                originalCostPrice: 225000,   // 225,000 LBP
                storedCurrency: 'LBP',
              );
              
              await _dataService.updateDebt(updatedDebt);
              fixedDebts++;
              print('🔧 Updated alfa ushare metadata for debt: ${debt.description} (Amount preserved: ${debt.amount})');
              continue; // Skip the general fix below
            }
          }
          
          // If this debt has a subcategoryId, we can try to get the original price
          if (debt.subcategoryId != null) {
            final categories = await _dataService.getCategories();
            Subcategory? matchingProduct;
            
            for (final category in categories) {
              for (final subcategory in category.subcategories) {
                if (subcategory.id == debt.subcategoryId) {
                  matchingProduct = subcategory;
                  break;
                }
              }
              if (matchingProduct != null) break;
            }
            
            if (matchingProduct != null) {
              // Recalculate the amount based on the original product price
              double newAmount;
              if (matchingProduct.sellingPriceCurrency == 'LBP') {
                // Convert LBP to USD using current exchange rate
                final currencySettings = await _dataService.getCurrencySettings();
                if (currencySettings?.exchangeRate != null) {
                  newAmount = matchingProduct.sellingPrice / currencySettings!.exchangeRate!;
                } else {
                  newAmount = matchingProduct.sellingPrice; // Keep as LBP if no exchange rate
                }
              } else {
                newAmount = matchingProduct.sellingPrice; // Already in USD
              }
              
              // CRITICAL FIX: Never modify debt.amount automatically!
              // Only update metadata, preserve the original amount
              // This prevents mysterious product price changes
              if (debt.originalSellingPrice != matchingProduct.sellingPrice ||
                  debt.originalCostPrice != matchingProduct.costPrice ||
                  debt.storedCurrency != matchingProduct.sellingPriceCurrency) {
                
                final updatedDebt = debt.copyWith(
                  // amount: newAmount,  // ❌ REMOVED: Never change original amount
                  originalSellingPrice: matchingProduct.sellingPrice,
                  originalCostPrice: matchingProduct.costPrice,
                  storedCurrency: matchingProduct.sellingPriceCurrency,
                );
                
                await _dataService.updateDebt(updatedDebt);
                fixedDebts++;
                print('🔧 Updated metadata for debt: ${debt.description} (Amount preserved: ${debt.amount})');
              }
            }
          }
        }
      }
      
      if (fixedDebts > 0) {
        print('✅ Fixed $fixedDebts debts with small amounts');
      }
    } catch (e) {
      print('❌ Error fixing debts with small amounts: $e');
    }
  }

  /// Fix existing activities by linking them to their corresponding debts
  /// This ensures that when debts are deleted, only their specific activities are removed
  Future<void> fixActivitiesDebtId() async {
    try {
      // Get all activities and debts
      final activities = _dataService.activities;
      final debts = _dataService.debts;
      
      int fixedCount = 0;
      
      for (final activity in activities) {
        // Skip activities that already have debtId
        if (activity.debtId != null) continue;
        
        // Try to find matching debt by description and customer
        Debt? matchingDebt;
        
        // Handle different activity types
        if (activity.type == ActivityType.newDebt) {
          // For new debt activities, the description format is "Product: Amount$"
          try {
            final productName = activity.description.split(':')[0].toLowerCase();
            matchingDebt = debts.firstWhere(
              (debt) => 
                debt.description.toLowerCase() == productName &&
                debt.customerId == activity.customerId &&
                debt.amount == activity.amount,
            );
          } catch (e) {
            // Try more flexible matching for new debt activities
            try {
              final productName = activity.description.split(':')[0].toLowerCase();
              matchingDebt = debts.firstWhere(
                (debt) => 
                  debt.customerId == activity.customerId &&
                  debt.description.toLowerCase().contains(productName),
              );
            } catch (e) {
              // No matching debt found for new debt activity
            }
          }
        } else if (activity.type == ActivityType.payment) {
          // For payment activities, we need to find the debt by customer and amount
          // since the description is just "Fully paid: Amount$" or "Partial payment: Amount$"
          try {
            matchingDebt = debts.firstWhere(
              (debt) => 
                debt.customerId == activity.customerId &&
                debt.amount == activity.amount,
            );
          } catch (e) {
            // Try to find any debt for this customer if exact amount match fails
            try {
              matchingDebt = debts.firstWhere(
                (debt) => debt.customerId == activity.customerId,
              );
            } catch (e) {
              // No matching debt found for payment activity
            }
          }
        }
        
        if (matchingDebt != null) {
          // Create updated activity with debtId
          final updatedActivity = activity.copyWith(
            debtId: matchingDebt.id,
          );
          
          // Update the activity in storage
          await _dataService.updateActivity(updatedActivity);
          fixedCount++;
        }
      }
      
      // Fixed activities with debtId links
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clean up duplicate activities that were created without proper debtId linking
  /// This removes orphaned activities that can cause confusion in the UI
  Future<void> cleanupOrphanedActivities() async {
    try {
      // Get all activities and debts
      final activities = _dataService.activities;
      final debts = _dataService.debts;
      
      int removedCount = 0;
      
      // Find activities without debtId that might be duplicates
      final orphanedActivities = activities.where((a) => a.debtId == null).toList();
      
      // Group orphaned activities by customer, description, and amount to identify duplicates
      final Map<String, List<Activity>> activityGroups = {};
      
      for (final activity in orphanedActivities) {
        final key = '${activity.customerId}_${activity.description}_${activity.amount.toStringAsFixed(2)}';
        activityGroups.putIfAbsent(key, () => []).add(activity);
      }
      
      // Remove duplicate orphaned activities, keeping only the most recent one
      for (final group in activityGroups.values) {
        if (group.length > 1) {
          // Sort by date (newest first)
          group.sort((a, b) => b.date.compareTo(a.date));
          
          // Keep the first (most recent) activity, remove the rest
          for (int i = 1; i < group.length; i++) {
            final duplicateActivity = group[i];
            await _dataService.deleteActivity(duplicateActivity.id);
            removedCount++;
          }
        }
      }
      
      // Cleaned up duplicate orphaned activities
    } catch (e) {
      // Handle error silently
    }
  }
}
