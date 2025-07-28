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
    
    // Register all adapters
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
    
    // Open Hive boxes with better error handling
    try {
      await Hive.openBox<Customer>('customers');
      await Hive.openBox<Debt>('debts');
      await Hive.openBox<ProductCategory>('categories');
      await Hive.openBox<ProductPurchase>('product_purchases');
      await Hive.openBox<CurrencySettings>('currency_settings');
      await Hive.openBox<Activity>('activities');
      await Hive.openBox<PartialPayment>('partial_payments');
      print('Hive boxes opened successfully');
      print('Partial payments box is open: ${Hive.isBoxOpen('partial_payments')}');
    } catch (e) {
      print('Error opening Hive boxes: $e');
      print('Attempting to fix problematic boxes...');
      
      try {
        // Only delete and recreate boxes that might be corrupted
        // Check which boxes are missing or corrupted
        final boxesToCheck = [
          'customers', 'debts', 'categories', 'product_purchases', 
          'currency_settings', 'activities', 'partial_payments'
        ];
        
        for (final boxName in boxesToCheck) {
          if (!Hive.isBoxOpen(boxName)) {
            try {
              // Try to delete and recreate only the problematic box
              await Hive.deleteBoxFromDisk(boxName);
              print('Recreated box: $boxName');
            } catch (deleteError) {
              print('Could not delete box $boxName: $deleteError');
            }
          }
        }
        
        // Re-register adapters
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
        
        // Open boxes again
        await Hive.openBox<Customer>('customers');
        await Hive.openBox<Debt>('debts');
        await Hive.openBox<ProductCategory>('categories');
        await Hive.openBox<ProductPurchase>('product_purchases');
        await Hive.openBox<CurrencySettings>('currency_settings');
        await Hive.openBox<Activity>('activities');
        await Hive.openBox<PartialPayment>('partial_payments');
        
        print('Hive boxes fixed successfully');
        print('Partial payments box is open: ${Hive.isBoxOpen('partial_payments')}');
      } catch (recreateError) {
        print('Failed to fix Hive boxes: $recreateError');
      }
    }
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
