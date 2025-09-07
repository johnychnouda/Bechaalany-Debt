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
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Automatically fetch data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isLoading && !_hasInitialized) {
        _hasInitialized = true;
        // Remove phantom activities first
        await appState.removePhantomActivities();
        await appState.refresh();
        
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // FIXED: Prevent duplicate refresh calls that cause phantom activities
    // Only refresh if we haven't initialized yet and truly have no data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isLoading && !_hasInitialized && appState.customers.isEmpty) {
        _hasInitialized = true;
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