import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'firebase_options.dart';
import 'constants/app_theme.dart';
import 'constants/platform_theme.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/backup_service.dart';
import 'services/background_backup_service.dart';
import 'services/background_app_refresh_service.dart';
import 'services/app_update_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure status bar based on platform
  if (Platform.isIOS) {
    // iOS 18+ specific settings
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: true,
      ),
    );
  } else {
    // Android 16 specific settings
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFEF7FF),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Color(0xFFE7E0EC),
      ),
    );
  }
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Firebase initialized - authentication will be handled by sign-in screens
    
    
  } catch (e) {
    // Handle initialization error silently
  }
    
    // Initialize Firebase service
    try {
      await FirebaseService.instance.initialize();
      // Firebase service initialized - authentication handled by sign-in screens
    } catch (e) {
      // Handle Firebase initialization error silently
    }
    
    // Initialize Google Sign-In
    try {
      await AuthService().initialize();
    } catch (e) {
      // Handle Google Sign-In initialization error silently
    }
    
    
    // Initialize automatic daily backup service
    try {
      final backupService = BackupService();
      await backupService.initializeDailyBackup();
    } catch (e) {
      // Handle backup service initialization error silently
    }
    
    // Initialize background services
    // Initialize background backup service
    try {
      final backgroundBackupService = BackgroundBackupService();
      await backgroundBackupService.initialize();
      await backgroundBackupService.start();
    } catch (e) {
      // Handle background backup service initialization error silently
    }
    
    // Initialize Background App Refresh service (more reliable)
    try {
      final backgroundAppRefreshService = BackgroundAppRefreshService();
      await backgroundAppRefreshService.initialize();
      await backgroundAppRefreshService.start();
    } catch (e) {
      // Handle Background App Refresh service initialization error silently
    }
    
    // Check for app updates
    try {
      final appUpdateService = AppUpdateService();
      await appUpdateService.checkForUpdates();
    } catch (e) {
      // Handle app update check error silently
    }
    
    runApp(const BechaalanyDebtApp());
}

class BechaalanyDebtApp extends StatefulWidget {
  const BechaalanyDebtApp({super.key});

  @override
  State<BechaalanyDebtApp> createState() => _BechaalanyDebtAppState();
}

class _BechaalanyDebtAppState extends State<BechaalanyDebtApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        
        // Reinitialize backup service
        _handleBackupServiceReinitialization();
        
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App went to background or was terminated
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., incoming call)
        break;
      case AppLifecycleState.hidden:
        // App is hidden (iOS specific)
        break;
    }
  }


  void _handleBackupServiceReinitialization() async {
    try {
      final backupService = BackupService();
      await backupService.handleAppLifecycleChange();
      
      // Also reinitialize Background App Refresh
      final backgroundAppRefreshService = BackgroundAppRefreshService();
      await backgroundAppRefreshService.initialize();
    } catch (e) {
      // Handle backup service reinitialization error silently
    }
  }

  SystemUiOverlayStyle _getSystemUIOverlayStyle(bool isDarkMode) {
    if (Platform.isIOS) {
      // iOS 18+ specific settings
      return isDarkMode 
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
            systemStatusBarContrastEnforced: true,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemStatusBarContrastEnforced: true,
          );
    } else {
      // Android 16 specific settings
      return isDarkMode 
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color(0xFF141218),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Color(0xFF49454F),
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFFFEF7FF),
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: Color(0xFFE7E0EC),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Bechaalany Connect',
            theme: PlatformTheme.getLightTheme(context),
            darkTheme: PlatformTheme.getDarkTheme(context),
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              // Apply custom theme based on app state
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0), // Use our custom text scaling
                ),
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: _getSystemUIOverlayStyle(appState.isDarkMode),
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
