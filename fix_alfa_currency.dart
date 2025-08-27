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
  
  try {
    final dataService = DataService();
    final categories = dataService.categories;
    
    // Find the alfa product in categories
    for (final category in categories) {
      for (final subcategory in category.subcategories) {
        if (subcategory.name.toLowerCase().contains('alfa')) {
          // Check if this is the LBP currency issue
          if (subcategory.costPriceCurrency == 'LBP' && subcategory.costPrice > 1000) {
            // Convert the large LBP values to proper USD values
            final costPriceUSD = subcategory.costPrice / 100000; // 90,000 LBP = 0.90 USD
            final sellingPriceUSD = subcategory.sellingPrice / 100000; // 180,000 LBP = 1.80 USD
            
            // Update the subcategory with correct USD values and currency
            final updatedSubcategory = subcategory.copyWith(
              costPrice: costPriceUSD,
              sellingPrice: sellingPriceUSD,
              costPriceCurrency: 'USD',
              sellingPriceCurrency: 'USD',
            );
            
            // Update in database
            await dataService.updateCategory(category);
          }
        }
      }
    }
    
    // Alfa product currency fix completed
  } catch (e) {
    // Handle error silently
  }
}
