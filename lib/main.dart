import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/customer.dart';
import 'models/debt.dart';
import 'constants/app_theme.dart';
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
    
    // Open Hive boxes with error handling
    try {
      await Hive.openBox<Customer>('customers');
      await Hive.openBox<Debt>('debts');
      print('Hive boxes opened successfully');
    } catch (e) {
      print('Error opening Hive boxes: $e');
      // Try to delete and recreate boxes if they're corrupted
      await Hive.deleteBoxFromDisk('customers');
      await Hive.deleteBoxFromDisk('debts');
      await Hive.openBox<Customer>('customers');
      await Hive.openBox<Debt>('debts');
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
    return MaterialApp(
      title: 'Bechaalany Debt',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
