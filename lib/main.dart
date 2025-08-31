import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';

// Global service instances
NotificationService? _globalNotificationService;

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
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    

    

    

      } catch (e) {
      // Handle initialization error silently
    }
    
    // Initialize Firebase service
    try {
      await FirebaseService.instance.initialize();
    } catch (e) {
      // Handle Firebase initialization error silently
    }
    
    // Initialize notification service first
    try {
      _globalNotificationService = NotificationService();
      await _globalNotificationService!.initialize();
    } catch (e) {
      // Handle notification service initialization error silently
    }
    
    // Initialize automatic daily backup service

    
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
        // App came to foreground, reinitialize services
        if (_globalNotificationService != null) {
          // Re-request notification permissions if needed
          _globalNotificationService!.reRequestPermissions();
        }
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
