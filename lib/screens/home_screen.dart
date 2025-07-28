import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
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
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isLoading) {
        appState.refresh();
        // Debug: Print current data state
        appState.debugPrintDataState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Dashboard Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final appState = Provider.of<AppState>(context, listen: false);
                  await appState.refresh();
                },
                child: const CustomizableDashboardWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Dashboard',
              style: AppTheme.title1.copyWith(
                color: AppColors.dynamicTextPrimary(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.settings),
            color: AppColors.dynamicTextSecondary(context),
          ),
        ],
      ),
    );
  }
}