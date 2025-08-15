import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';


class ProfitLossWidget extends StatefulWidget {
  const ProfitLossWidget({super.key});

  @override
  State<ProfitLossWidget> createState() => _ProfitLossWidgetState();
}

class _ProfitLossWidgetState extends State<ProfitLossWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Use professional revenue calculation based on product profit margins
        final totalRevenue = appState.totalHistoricalRevenue;
        
        // Get comprehensive revenue summary for dashboard
        final revenueSummary = appState.getDashboardRevenueSummary();
        
        // Calculate total debts: sum of all debt amounts minus total partial payments
        final totalDebtAmount = appState.debts.fold<double>(0.0, (sum, debt) => sum + debt.amount);
        final totalPartialPayments = appState.debts.fold<double>(0.0, (sum, debt) => sum + debt.paidAmount);
        final totalDebts = totalDebtAmount - totalPartialPayments;

        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(16), // Reduced from 20
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.dynamicSurface(context).withValues(alpha: 0.8),
                    AppColors.dynamicSurface(context).withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dynamicSurface(context).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Revenue',
                              style: AppTheme.title3.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '/',
                              style: AppTheme.title3.copyWith(
                                color: AppColors.dynamicTextPrimary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: 'Debts',
                              style: AppTheme.title3.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' Analysis',
                              style: AppTheme.title3.copyWith(
                                color: AppColors.dynamicTextPrimary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildProfitLossCard(
                    'Total Revenue',
                    totalRevenue,
                    Icons.arrow_upward,
                    AppColors.success,
                    subtitle: 'From product profit margins',
                  ),
                  const SizedBox(height: 12),
                  _buildProfitLossCard(
                    'Total Debts',
                    totalDebts,
                    Icons.arrow_downward,
                    AppColors.error,
                    subtitle: 'Outstanding amounts',
                  ),
                  const SizedBox(height: 12),
                  _buildProfitLossCard(
                    'Potential Revenue',
                    revenueSummary['totalPotentialRevenue'] ?? 0.0,
                    Icons.trending_up,
                    AppColors.warning,
                    subtitle: 'From unpaid amounts',
                  ),
                  const SizedBox(height: 12),
                  // Debug button for testing revenue calculation
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _testRevenueCalculation(context, appState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Test Revenue Calculation'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfitLossCard(String title, double amount, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context).withValues(alpha: 0.5), // 0.5 * 255
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.1), // 0.1 * 255
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.footnote.copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, amount),
                style: AppTheme.title3.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                                 subtitle,
                 style: AppTheme.caption1.copyWith(
                   color: AppColors.dynamicTextSecondary(context),
                 ),
              ),
            ),
        ],
      ),
    );
  }

  // Removed _calculateTotalExpenses method as we now use totalDebt from AppState

  /// Test revenue calculation and show debug information
  void _testRevenueCalculation(BuildContext context, AppState appState) async {
    try {
      // Run data migration first
      await appState.runDataMigration();
      
      // Get revenue summary
      final revenueSummary = appState.getDashboardRevenueSummary();
      
      // Show debug dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Revenue Calculation Test'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Debts: ${appState.debts.length}'),
                Text('Total Revenue: \$${appState.totalHistoricalRevenue}'),
                Text('Revenue Summary:'),
                ...revenueSummary.entries.map((entry) => 
                  Text('  ${entry.key}: ${entry.value}')
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 