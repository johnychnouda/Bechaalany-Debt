import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';
import '../utils/logo_utils.dart';
import '../widgets/customizable_dashboard_widget.dart';
import '../utils/currency_formatter.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isLoading) {
        appState.refresh();
      }
    });
  }

  Future<void> _handleRefresh() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.refresh();
  }

  // Responsive sizing helpers
  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    // Adjust for smaller screens
    if (height < 700) return 12.0;
    if (width < 375) return 16.0;
    if (width < 414) return 20.0;
    return 24.0;
  }

  double _getResponsiveSpacing(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    
    // Reduce spacing for smaller screens
    if (height < 700) return 8.0;
    if (height < 800) return 12.0;
    return 16.0;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    // Scale down for smaller screens
    if (height < 700) return baseSize * 0.85;
    if (width < 375) return baseSize * 0.9;
    if (width < 414) return baseSize;
    return baseSize * 1.05;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: AppColors.dynamicBackground(context),
          body: SafeArea(
            child: appState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.primary,
                    child: const CustomizableDashboardWidget(),
                  ),
          ),
          floatingActionButton: null,
        );
      },
    );
  }
}