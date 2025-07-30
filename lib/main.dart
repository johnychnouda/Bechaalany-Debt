import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/customer.dart';
import 'models/debt.dart';
import 'models/category.dart';
import 'models/product_purchase.dart';
import 'models/currency_settings.dart';
import 'models/activity.dart';
import 'models/partial_payment.dart';
import 'constants/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure status bar for iOS 18+ (default)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      // iOS 18+ specific settings
      systemStatusBarContrastEnforced: true,
    ),
  );
  
  try {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register all adapters with error handling
    try {
      Hive.registerAdapter(CustomerAdapter());
      Hive.registerAdapter(DebtAdapter());
      Hive.registerAdapter(DebtStatusAdapter());
      Hive.registerAdapter(DebtTypeAdapter());
      Hive.registerAdapter(ProductCategoryAdapter());
      Hive.registerAdapter(SubcategoryAdapter());
      Hive.registerAdapter(PriceHistoryAdapter());
      Hive.registerAdapter(ProductPurchaseAdapter());
      Hive.registerAdapter(CurrencySettingsAdapter());
      Hive.registerAdapter(ActivityAdapter());
      Hive.registerAdapter(ActivityTypeAdapter());
      Hive.registerAdapter(PartialPaymentAdapter());
    } catch (e) {
      // Continue anyway, some adapters might already be registered
    }
    
    // Open Hive boxes with better error handling
    
    // Open each box individually with proper error handling
    try {
      if (!Hive.isBoxOpen('customers')) {
        await Hive.openBox<Customer>('customers');
      }
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk('customers');
        await Hive.openBox<Customer>('customers');
      } catch (recreateError) {
        // Handle recreation error silently
      }
    }

    try {
      if (!Hive.isBoxOpen('debts')) {
        await Hive.openBox<Debt>('debts');
      }
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk('debts');
        await Hive.openBox<Debt>('debts');
      } catch (recreateError) {
        // Handle recreation error silently
      }
    }

    try {
      if (!Hive.isBoxOpen('categories')) {
        await Hive.openBox<ProductCategory>('categories');
      }
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk('categories');
        await Hive.openBox<ProductCategory>('categories');
      } catch (recreateError) {
        // Handle recreation error silently
      }
    }

    try {
      if (!Hive.isBoxOpen('product_purchases')) {
        await Hive.openBox<ProductPurchase>('product_purchases');
      }
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk('product_purchases');
        await Hive.openBox<ProductPurchase>('product_purchases');
      } catch (recreateError) {
        // Handle recreation error silently
      }
    }

    try {
      if (!Hive.isBoxOpen('currency_settings')) {
        await Hive.openBox<CurrencySettings>('currency_settings');
      }
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk('currency_settings');
        await Hive.openBox<CurrencySettings>('currency_settings');
      } catch (recreateError) {
        // Handle recreation error silently
      }
    }

    try {
      if (!Hive.isBoxOpen('activities')) {
        await Hive.openBox<Activity>('activities');
      }
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk('activities');
        await Hive.openBox<Activity>('activities');
      } catch (recreateError) {
        // Handle recreation error silently
      }
    }

    try {
      if (!Hive.isBoxOpen('partial_payments')) {
        await Hive.openBox<PartialPayment>('partial_payments');
      }
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk('partial_payments');
        await Hive.openBox<PartialPayment>('partial_payments');
      } catch (recreateError) {
        // Handle recreation error silently
      }
    }
  } catch (e) {
    // Handle initialization error silently
  }
  
  runApp(const BechaalanyDebtApp());
}

class BechaalanyDebtApp extends StatelessWidget {
  const BechaalanyDebtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Bechaalany Debt',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              // Apply custom theme based on app state
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0), // Use our custom text scaling
                ),
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: appState.isDarkMode 
                    ? const SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.light,
                        statusBarBrightness: Brightness.dark,
                        systemNavigationBarColor: Colors.black,
                        systemNavigationBarIconBrightness: Brightness.light,
                      )
                    : const SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.dark,
                        statusBarBrightness: Brightness.light,
                        systemNavigationBarColor: Colors.white,
                        systemNavigationBarIconBrightness: Brightness.dark,
                      ),
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
