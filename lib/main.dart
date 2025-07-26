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
import 'constants/app_theme.dart';
import 'providers/app_state.dart';
import 'services/localization_service.dart';
import 'services/theme_service.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(DebtAdapter());
    Hive.registerAdapter(DebtStatusAdapter());
    Hive.registerAdapter(DebtTypeAdapter());
    Hive.registerAdapter(ProductCategoryAdapter());
    Hive.registerAdapter(SubcategoryAdapter());
    Hive.registerAdapter(PriceHistoryAdapter());
    Hive.registerAdapter(ProductPurchaseAdapter());
    Hive.registerAdapter(CurrencySettingsAdapter());
    
    // Open Hive boxes with error handling
    try {
      await Hive.openBox<Customer>('customers');
      await Hive.openBox<Debt>('debts');
      await Hive.openBox<ProductCategory>('categories');
      await Hive.openBox<ProductPurchase>('product_purchases');
      await Hive.openBox<CurrencySettings>('currency_settings');
      print('Hive boxes opened successfully');
    } catch (e) {
      print('Error opening Hive boxes: $e');
      // Try to delete and recreate boxes if they're corrupted
      await Hive.deleteBoxFromDisk('customers');
      await Hive.deleteBoxFromDisk('debts');
      await Hive.deleteBoxFromDisk('categories');
      await Hive.deleteBoxFromDisk('product_purchases');
      await Hive.deleteBoxFromDisk('currency_settings');
      await Hive.openBox<Customer>('customers');
      await Hive.openBox<Debt>('debts');
      await Hive.openBox<ProductCategory>('categories');
      await Hive.openBox<ProductPurchase>('product_purchases');
      await Hive.openBox<CurrencySettings>('currency_settings');
      print('Hive boxes recreated successfully');
    }
  } catch (e) {
    print('Error during initialization: $e');
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
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
