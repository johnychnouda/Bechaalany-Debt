import '../models/debt.dart';
import '../models/category.dart';
import '../services/data_service.dart';

/// Professional Data Migration Service
/// Handles data integrity and migration for existing data
/// Ensures all debts have proper cost price information for revenue calculation
class DataMigrationService {
  static final DataMigrationService _instance = DataMigrationService._internal();
  factory DataMigrationService() => _instance;
  DataMigrationService._internal();

  final DataService _dataService = DataService();

  /// Migrate existing debts to include missing cost prices
  /// This is critical for revenue calculation accuracy
  Future<void> migrateDebtCostPrices() async {
    try {
      // Ensure data is loaded before migration
      await _dataService.ensureBoxesOpen();
      
      // Get all debts and categories using getter methods
      final debts = _dataService.debts;
      final categories = _dataService.categories;
      
      int updatedCount = 0;
      int skippedCount = 0;
      
      for (final debt in debts) {
        // Skip if debt already has cost price
        if (debt.originalCostPrice != null) {
          skippedCount++;
          continue;
        }
        
        // Try to find cost price from subcategory
        if (debt.subcategoryId != null) {
          final subcategory = categories
              .expand((category) => category.subcategories)
              .firstWhere(
                (sub) => sub.id == debt.subcategoryId,
                orElse: () => Subcategory(
                  id: '',
                  name: '',
                  costPrice: 0.0,
                  sellingPrice: 0.0,
                  createdAt: DateTime.now(),
                  costPriceCurrency: 'USD',
                  sellingPriceCurrency: 'USD',
                ),
              );
          
          if (subcategory.id.isNotEmpty) {
            // Update debt with cost price
            final updatedDebt = debt.copyWith(
              originalCostPrice: subcategory.costPrice,
              originalSellingPrice: debt.originalSellingPrice ?? debt.amount,
              subcategoryId: debt.subcategoryId ?? subcategory.id,
              subcategoryName: debt.subcategoryName ?? subcategory.name,
              categoryName: debt.categoryName ?? _findCategoryName(categories, subcategory.id),
            );
            
            await _dataService.updateDebt(updatedDebt);
            updatedCount++;
          }
        } else {
  
          
          // Try to find by subcategory name match as fallback
          final matchingSubcategory = categories
              .expand((category) => category.subcategories)
              .firstWhere(
                (sub) => sub.name.toLowerCase() == debt.description.toLowerCase(),
                orElse: () => Subcategory(
                  id: '',
                  name: '',
                  costPrice: 0.0,
                  sellingPrice: 0.0,
                  createdAt: DateTime.now(),
                  costPriceCurrency: 'USD',
                  sellingPriceCurrency: 'USD',
                ),
              );
          
          if (matchingSubcategory.id.isNotEmpty) {
                      
          // Update debt with cost price and subcategory info
          final updatedDebt = debt.copyWith(
            originalCostPrice: matchingSubcategory.costPrice,
            originalSellingPrice: debt.originalSellingPrice ?? debt.amount,
            subcategoryId: matchingSubcategory.id,
            subcategoryName: matchingSubcategory.name,
            categoryName: _findCategoryName(categories, matchingSubcategory.id),
          );
          
          await _dataService.updateDebt(updatedDebt);
          updatedCount++;
          
          } else {

          }
        }
      }
      
    } catch (e) {
      rethrow;
    }
  }

  /// Find category name for a subcategory
  String _findCategoryName(List<ProductCategory> categories, String subcategoryId) {
    for (final category in categories) {
      final subcategory = category.subcategories.firstWhere(
        (sub) => sub.id == subcategoryId,
        orElse: () => Subcategory(
          id: '',
          name: '',
          costPrice: 0.0,
          sellingPrice: 0.0,
          createdAt: DateTime.now(),
          costPriceCurrency: 'USD',
          sellingPriceCurrency: 'USD',
        ),
      );
      
      if (subcategory.id.isNotEmpty) {
        return category.name;
      }
    }
    return 'Unknown';
  }

  /// Validate data integrity after migration
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    try {
      // Ensure data is loaded before validation
      await _dataService.ensureBoxesOpen();
      
      final debts = _dataService.debts;
      final categories = _dataService.categories;
      
      int totalDebts = debts.length;
      int debtsWithCostPrice = 0;
      int debtsWithSellingPrice = 0;
      int debtsWithRevenue = 0;
      int debtsWithSubcategory = 0;
      
      double totalRevenue = 0.0;
      double totalPotentialRevenue = 0.0;
      
      for (final debt in debts) {
        if (debt.originalCostPrice != null) debtsWithCostPrice++;
        if (debt.originalSellingPrice != null) debtsWithSellingPrice++;
        if (debt.subcategoryId != null) debtsWithSubcategory++;
        
        if (debt.originalCostPrice != null && debt.originalSellingPrice != null) {
          final revenue = debt.originalRevenue;
          if (revenue > 0) {
            debtsWithRevenue++;
            totalRevenue += debt.earnedRevenue;
            totalPotentialRevenue += debt.remainingRevenue;
          }
        }
      }
      
      return {
        'totalDebts': totalDebts,
        'debtsWithCostPrice': debtsWithCostPrice,
        'debtsWithSellingPrice': debtsWithSellingPrice,
        'debtsWithRevenue': debtsWithRevenue,
        'debtsWithSubcategory': debtsWithSubcategory,
        'totalCategories': categories.length,
        'totalRevenue': totalRevenue,
        'totalPotentialRevenue': totalPotentialRevenue,
        'dataIntegrityPercentage': totalDebts > 0 ? (debtsWithCostPrice / totalDebts) * 100 : 0.0,
        'migrationRequired': debtsWithCostPrice < totalDebts,
        'migrationPossible': debtsWithSubcategory > 0,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'migrationRequired': true,
        'migrationPossible': false,
      };
    }
  }

  /// Get migration recommendations
  List<String> getMigrationRecommendations(Map<String, dynamic> integrityReport) {
    final recommendations = <String>[];
    
    if (integrityReport['migrationRequired'] == true) {
      if (integrityReport['migrationPossible'] == true) {
        recommendations.add('✅ Run debt cost price migration to ensure revenue calculation accuracy');
      } else {
        recommendations.add('⚠️ Debts need subcategory information before migration is possible');
        recommendations.add('   Create debts from products to enable automatic cost price migration');
      }
    }
    
    if (integrityReport['dataIntegrityPercentage'] != null && 
        integrityReport['dataIntegrityPercentage'] < 100) {
      final percentage = (100 - integrityReport['dataIntegrityPercentage']).toStringAsFixed(1);
      recommendations.add('📊 ${percentage}% of debts need cost price information');
    }
    
    if (integrityReport['totalRevenue'] != null && integrityReport['totalRevenue'] == 0) {
      if (integrityReport['debtsWithCostPrice'] != null && integrityReport['debtsWithCostPrice'] == 0) {
        recommendations.add('💰 Revenue calculation requires cost price data - run migration first');
      } else if (integrityReport['totalDebts'] != null && integrityReport['totalDebts'] > 0) {
        recommendations.add('💰 No revenue calculated - check if debts have payments or cost prices');
      }
    }
    
    if (integrityReport['totalDebts'] != null && integrityReport['totalDebts'] == 0) {
      recommendations.add('📝 No debts found - create some debts from products to test revenue calculation');
    }
    
    return recommendations;
  }
}
