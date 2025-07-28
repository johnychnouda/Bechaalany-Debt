import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'services/localization_service.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure status bar for light theme (default)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
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
      print('All adapters registered successfully');
    } catch (e) {
      print('Error registering adapters: $e');
      // Continue anyway, some adapters might already be registered
    }
    
    // Open Hive boxes with better error handling
    print('Starting Hive box initialization...');
    
    // Open each box individually with proper error handling
    try {
      if (!Hive.isBoxOpen('customers')) {
        print('Opening box: customers');
        await Hive.openBox<Customer>('customers');
        print('Successfully opened box: customers');
      } else {
        print('Box already open: customers');
      }
    } catch (e) {
      print('Error opening box customers: $e');
      try {
        await Hive.deleteBoxFromDisk('customers');
        await Hive.openBox<Customer>('customers');
        print('Successfully recreated box: customers');
      } catch (recreateError) {
        print('Failed to recreate box customers: $recreateError');
      }
    }

    try {
      if (!Hive.isBoxOpen('debts')) {
        print('Opening box: debts');
        await Hive.openBox<Debt>('debts');
        print('Successfully opened box: debts');
      } else {
        print('Box already open: debts');
      }
    } catch (e) {
      print('Error opening box debts: $e');
      try {
        await Hive.deleteBoxFromDisk('debts');
        await Hive.openBox<Debt>('debts');
        print('Successfully recreated box: debts');
      } catch (recreateError) {
        print('Failed to recreate box debts: $recreateError');
      }
    }

    try {
      if (!Hive.isBoxOpen('categories')) {
        print('Opening box: categories');
        await Hive.openBox<ProductCategory>('categories');
        print('Successfully opened box: categories');
      } else {
        print('Box already open: categories');
      }
    } catch (e) {
      print('Error opening box categories: $e');
      try {
        await Hive.deleteBoxFromDisk('categories');
        await Hive.openBox<ProductCategory>('categories');
        print('Successfully recreated box: categories');
      } catch (recreateError) {
        print('Failed to recreate box categories: $recreateError');
      }
    }

    try {
      if (!Hive.isBoxOpen('product_purchases')) {
        print('Opening box: product_purchases');
        await Hive.openBox<ProductPurchase>('product_purchases');
        print('Successfully opened box: product_purchases');
      } else {
        print('Box already open: product_purchases');
      }
    } catch (e) {
      print('Error opening box product_purchases: $e');
      try {
        await Hive.deleteBoxFromDisk('product_purchases');
        await Hive.openBox<ProductPurchase>('product_purchases');
        print('Successfully recreated box: product_purchases');
      } catch (recreateError) {
        print('Failed to recreate box product_purchases: $recreateError');
      }
    }

    try {
      if (!Hive.isBoxOpen('currency_settings')) {
        print('Opening box: currency_settings');
        await Hive.openBox<CurrencySettings>('currency_settings');
        print('Successfully opened box: currency_settings');
      } else {
        print('Box already open: currency_settings');
      }
    } catch (e) {
      print('Error opening box currency_settings: $e');
      try {
        await Hive.deleteBoxFromDisk('currency_settings');
        await Hive.openBox<CurrencySettings>('currency_settings');
        print('Successfully recreated box: currency_settings');
      } catch (recreateError) {
        print('Failed to recreate box currency_settings: $recreateError');
      }
    }

    try {
      if (!Hive.isBoxOpen('activities')) {
        print('Opening box: activities');
        await Hive.openBox<Activity>('activities');
        print('Successfully opened box: activities');
      } else {
        print('Box already open: activities');
      }
    } catch (e) {
      print('Error opening box activities: $e');
      try {
        await Hive.deleteBoxFromDisk('activities');
        await Hive.openBox<Activity>('activities');
        print('Successfully recreated box: activities');
      } catch (recreateError) {
        print('Failed to recreate box activities: $recreateError');
      }
    }

    try {
      if (!Hive.isBoxOpen('partial_payments')) {
        print('Opening box: partial_payments');
        await Hive.openBox<PartialPayment>('partial_payments');
        print('Successfully opened box: partial_payments');
      } else {
        print('Box already open: partial_payments');
      }
    } catch (e) {
      print('Error opening box partial_payments: $e');
      try {
        await Hive.deleteBoxFromDisk('partial_payments');
        await Hive.openBox<PartialPayment>('partial_payments');
        print('Successfully recreated box: partial_payments');
      } catch (recreateError) {
        print('Failed to recreate box partial_payments: $recreateError');
      }
    }
    
    // Verify all boxes are open
    print('Verifying all boxes are open...');
    print('Box customers is open: ${Hive.isBoxOpen('customers')}');
    print('Box debts is open: ${Hive.isBoxOpen('debts')}');
    print('Box categories is open: ${Hive.isBoxOpen('categories')}');
    print('Box product_purchases is open: ${Hive.isBoxOpen('product_purchases')}');
    print('Box currency_settings is open: ${Hive.isBoxOpen('currency_settings')}');
    print('Box activities is open: ${Hive.isBoxOpen('activities')}');
    print('Box partial_payments is open: ${Hive.isBoxOpen('partial_payments')}');
  } catch (e) {
    print('Error during Hive initialization: $e');
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
        ChangeNotifierProvider(create: (context) => LocalizationService()),
      ],
      child: Consumer2<AppState, LocalizationService>(
        builder: (context, appState, localizationService, child) {
          // Initialize services
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appState.setLocalizationService(localizationService);
            localizationService.initialize();
          });
          
          return MaterialApp(
            title: 'Bechaalany Debt',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: localizationService.currentLocale,
            supportedLocales: LocalizationService.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
