import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../models/debt.dart';

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
        // Calculate revenue from product sales + customer payments
        final productRevenue = appState.productPurchases.fold<double>(0.0, (sum, purchase) => sum + purchase.totalAmount);
        final paymentRevenue = appState.debts.fold<double>(0.0, (sum, debt) => sum + debt.paidAmount);
        final totalRevenue = productRevenue + paymentRevenue;
        
        // Calculate total outstanding debts
        final totalDebts = appState.debts.where((debt) => debt.status == DebtStatus.pending).fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount);
        final netProfit = totalRevenue - totalDebts;
        final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;
        
        // Debug information
        print('=== Profit/Loss Analysis ===');
        print('Total Product Purchases: ${appState.productPurchases.length}');
        print('Product Revenue: $productRevenue');
        print('Payment Revenue: $paymentRevenue');
        print('Total Revenue: $totalRevenue');
        print('Total Outstanding Debts: $totalDebts');
        print('Net Profit: $netProfit');
        print('Profit Margin: ${profitMargin.toStringAsFixed(1)}%');
        print('=======================');

        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.dynamicSurface(context).withAlpha(204), // 0.8 * 255
                    AppColors.dynamicSurface(context).withAlpha(153), // 0.6 * 255
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withAlpha(26), // 0.1 * 255
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13), // 0.05 * 255
                    blurRadius: 20,
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
                          color: AppColors.primary.withAlpha(26), // 0.1 * 255
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Profit/Loss Analysis',
                        style: AppTheme.title3.copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
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
                  ),
                  const SizedBox(height: 12),
                  _buildProfitLossCard(
                    'Total Debts',
                    totalDebts,
                    Icons.arrow_downward,
                    AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: netProfit >= 0
                            ? [AppColors.success.withAlpha(26), AppColors.success.withAlpha(13)] // 0.1 * 255, 0.05 * 255
                            : [AppColors.error.withAlpha(26), AppColors.error.withAlpha(13)], // 0.1 * 255, 0.05 * 255
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: netProfit >= 0
                            ? AppColors.success.withAlpha(77) // 0.3 * 255
                            : AppColors.error.withAlpha(77), // 0.3 * 255
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: netProfit >= 0 ? AppColors.success : AppColors.error,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Net Profit',
                                style: AppTheme.footnote.copyWith(
                                  color: AppColors.dynamicTextSecondary(context),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatAmount(context, netProfit),
                                style: AppTheme.title1.copyWith(
                                  color: netProfit >= 0 ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: netProfit >= 0 ? AppColors.success : AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${profitMargin.toStringAsFixed(1)}%',
                            style: AppTheme.footnote.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildProfitLossCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context).withAlpha(128), // 0.5 * 255
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha(26), // 0.1 * 255
        ),
      ),
      child: Row(
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
    );
  }

  // Removed _calculateTotalExpenses method as we now use totalDebt from AppState
} 