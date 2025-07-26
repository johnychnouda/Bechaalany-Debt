import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';
import '../utils/logo_utils.dart';
import '../widgets/recent_debts_list.dart';
import '../widgets/todays_summary_widget.dart';
import '../widgets/weekly_activity_widget.dart';
import '../widgets/top_debtors_widget.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/profit_loss_widget.dart';
import '../widgets/customer_payment_history_widget.dart';
import '../widgets/customizable_dashboard_widget.dart';
import '../utils/currency_formatter.dart';
import 'settings_screen.dart';
import 'debt_history_screen.dart';

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

  Widget _buildHeader(AppState appState) {
    final padding = _getResponsivePadding(context);
    final spacing = _getResponsiveSpacing(context);
    
    return Container(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LogoUtils.buildLogo(
              context: context,
              width: 24,
              height: 24,
              placeholder: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: AppTheme.getDynamicTitle3(context).copyWith(
                    color: AppColors.dynamicTextPrimary(context),
                  ),
                ),
                Text(
                  'Welcome back',
                  style: AppTheme.getDynamicFootnote(context).copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          if (appState.isSyncing)
            Container(
              padding: EdgeInsets.all(spacing * 0.5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AppState appState) {
    final totalCustomers = appState.customers.length;
    final totalDebts = appState.debts.length;
    final pendingDebts = appState.debts.where((d) => d.status == DebtStatus.pending).length;
    final totalAmount = appState.debts
        .where((d) => d.status == DebtStatus.pending)
        .fold(0.0, (sum, debt) => sum + debt.amount);

    final padding = _getResponsivePadding(context);
    final spacing = _getResponsiveSpacing(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: AppTheme.getDynamicTitle2(context).copyWith(
              color: AppColors.dynamicTextPrimary(context),
            ),
          ),
          SizedBox(height: spacing),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = MediaQuery.of(context).size.height < 700;
              final crossAxisCount = isSmallScreen ? 2 : 2;
              final childAspectRatio = isSmallScreen ? 1.1 : 1.2;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildStatCard(
                    'Customers',
                    totalCustomers.toString(),
                    Icons.people_outlined,
                    AppColors.primary,
                  ),
                  _buildStatCard(
                    'Total Debts',
                    totalDebts.toString(),
                    Icons.account_balance_wallet_outlined,
                    AppColors.secondary,
                  ),
                  _buildStatCard(
                    'Pending',
                    pendingDebts.toString(),
                    Icons.pending_outlined,
                    AppColors.warning,
                  ),
                  _buildStatCard(
                    'Total Amount',
                    CurrencyFormatter.formatAmount(context, totalAmount),
                    Icons.attach_money,
                    AppColors.success,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final padding = _getResponsivePadding(context);
    final spacing = _getResponsiveSpacing(context);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(spacing * 0.5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: _getResponsiveFontSize(context, 20)),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTheme.title1.copyWith(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: _getResponsiveFontSize(context, 24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.footnote.copyWith(
              color: AppColors.dynamicTextSecondary(context),
              fontSize: _getResponsiveFontSize(context, 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    final padding = _getResponsivePadding(context);
    final spacing = _getResponsiveSpacing(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.title2.copyWith(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: _getResponsiveFontSize(context, 22),
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: spacing,
                  vertical: spacing * 0.5,
                ),
              ),
              child: Text(
                'View All',
                style: AppTheme.footnote.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: _getResponsiveFontSize(context, 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentCard(Widget child) {
    final padding = _getResponsivePadding(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
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