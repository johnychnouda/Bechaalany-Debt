import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'firebase_options.dart';
import 'constants/platform_theme.dart';
import 'providers/app_state.dart';
import 'widgets/auth_wrapper.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/backup_service.dart';
// Background services removed - no longer needed
import 'services/app_update_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable debug paint to remove yellow lines and other debug visuals
  debugPaintSizeEnabled = false;
  
  // Configure status bar for both iOS and Android
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
  
  // Suppress system warnings on Android
  if (Platform.isAndroid) {
    // Suppress verbose logging from Google Play Services
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  
  try {
    // Initialize Firebase - this must complete before app can use Firebase services
    // However, we optimize by deferring non-critical operations
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set Firebase Auth language asynchronously after initialization
    // This doesn't block the app from starting
    Future.microtask(() async {
      try {
        final auth = FirebaseAuth.instance;
        // Get system locale or default to 'en'
        final localeCode = Platform.localeName.split('_').first;
        await auth.setLanguageCode(localeCode.isNotEmpty ? localeCode : 'en');
      } catch (e) {
        // Fallback to English if locale setting fails
        try {
          await FirebaseAuth.instance.setLanguageCode('en');
        } catch (_) {
          // Ignore if setting language fails - warnings are acceptable
        }
      }
    });
    
  } catch (e) {
    // Handle initialization error silently - Google Play Services errors are expected on emulators
  }
    
    // Initialize services asynchronously to reduce frame skipping
    // Run non-critical initializations in parallel after app starts
    _initializeServicesAsync();
    
    // Start the app immediately to reduce startup time
    runApp(const BechaalanyDebtApp());
}

// Initialize services asynchronously to prevent blocking the main thread
void _initializeServicesAsync() async {
  // Initialize Firebase service
  try {
    await FirebaseService.instance.initialize();
    // Firebase service initialized - authentication handled by sign-in screens
  } catch (e) {
    // Handle Firebase initialization error silently
  }
  
  try {
    await AuthService().ensureInitialized();
  } catch (e) {
    // Handle Google Sign-In initialization error silently
    // Google Play Services errors are expected on emulators without full GMS
  }
  
  
  // Initialize automatic daily backup service
  try {
    final backupService = BackupService();
    await backupService.initializeDailyBackup();
  } catch (e) {
    // Handle backup service initialization error silently
  }
  
  // Background services disabled to prevent iOS notifications
  // Background backup service disabled
  // Background App Refresh service disabled
  
  // Check for app updates
  try {
    final appUpdateService = AppUpdateService();
    await appUpdateService.checkForUpdates();
  } catch (e) {
    // Handle app update check error silently
  }
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
      
      // Background App Refresh service disabled to prevent iOS notifications
    } catch (e) {
      // Handle backup service reinitialization error silently
    }
  }

  SystemUiOverlayStyle _getSystemUIOverlayStyle(bool isDarkMode) {
    // Cross-platform UI overlay settings for iOS and Android
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
