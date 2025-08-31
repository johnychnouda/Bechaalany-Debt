import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';

import '../providers/app_state.dart';
import '../widgets/customizable_dashboard_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically fetch data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isLoading) {
        await appState.refresh();
        // Wait a bit for data to load, then create activities
        await Future.delayed(const Duration(milliseconds: 500));
        // Activities are now created automatically in app state initialization
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (like when returning from other screens)
    // CRITICAL FIX: Only refresh if we don't already have customers to prevent clearing data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isLoading && appState.customers.isEmpty) {
        appState.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      body: SafeArea(
        child: const CustomizableDashboardWidget(),
      ),
    );
  }
}