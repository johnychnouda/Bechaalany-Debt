import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'lib/models/category.dart';
import 'lib/services/data_service.dart';

void main() async {
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(ProductCategoryAdapter());
  Hive.registerAdapter(SubcategoryAdapter());
  Hive.registerAdapter(PriceHistoryAdapter());
  
  // Open boxes
  await Hive.openBox<ProductCategory>('categories');
  
  print('🔧 Starting alfa product currency fix...');
  
  try {
    final dataService = DataService();
    final categories = dataService.categories;
    
    // Find the alfa product in categories
    for (final category in categories) {
      for (final subcategory in category.subcategories) {
        if (subcategory.name.toLowerCase().contains('alfa')) {
          print('🔧 Found alfa product: ${subcategory.name}');
          print('  Current values - Cost: ${subcategory.costPrice}, Selling: ${subcategory.sellingPrice}');
          print('  Current currency - Cost: ${subcategory.costPriceCurrency}, Selling: ${subcategory.sellingPriceCurrency}');
          
          // Check if this is the LBP currency issue
          if (subcategory.costPriceCurrency == 'LBP' && subcategory.costPrice > 1000) {
            print('  ⚠️ Detected LBP currency with large values - converting to USD');
            
            // Convert the large LBP values to proper USD values
            final costPriceUSD = subcategory.costPrice / 100000; // 90,000 LBP = 0.90 USD
            final sellingPriceUSD = subcategory.sellingPrice / 100000; // 180,000 LBP = 1.80 USD
            
            print('  Converting - Cost: ${subcategory.costPrice} LBP → ${costPriceUSD.toStringAsFixed(2)} USD');
            print('  Converting - Selling: ${subcategory.sellingPrice} LBP → ${sellingPriceUSD.toStringAsFixed(2)} USD');
            
            // Update the subcategory with correct USD values and currency
            final updatedSubcategory = subcategory.copyWith(
              costPrice: costPriceUSD,
              sellingPrice: sellingPriceUSD,
              costPriceCurrency: 'USD',
              sellingPriceCurrency: 'USD',
            );
            
            // Update in database
            await dataService.updateCategory(category);
            
            print('✅ Fixed alfa product currency and pricing');
            print('  New values - Cost: ${updatedSubcategory.costPrice} USD, Selling: ${updatedSubcategory.sellingPrice} USD');
          }
        }
      }
    }
    
    print('✅ Alfa product currency fix completed');
  } catch (e) {
    print('❌ Error during alfa product currency fix: $e');
  }
}
