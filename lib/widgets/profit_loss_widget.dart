import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../models/debt.dart';
import '../models/activity.dart';

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
        // Calculate revenue from product sales + ALL customer payments (including cleared debts)
        final productRevenue = appState.productPurchases.fold<double>(0.0, (sum, purchase) => sum + purchase.totalAmount);
        
        // Get ALL payment activities (including from cleared debts)
        final allPaymentActivities = appState.activities.where((activity) => 
          activity.type == ActivityType.payment && activity.paymentAmount != null
        ).toList();
        final paymentRevenue = allPaymentActivities.fold<double>(0.0, (sum, activity) => sum + (activity.paymentAmount ?? 0));
        
        final totalRevenue = productRevenue + paymentRevenue;
        
        // Calculate total debts: sum of all debt amounts minus total partial payments
        final totalDebtAmount = appState.debts.fold<double>(0.0, (sum, debt) => sum + debt.amount);
        final totalPartialPayments = appState.debts.fold<double>(0.0, (sum, debt) => sum + debt.paidAmount);
        final totalDebts = totalDebtAmount - totalPartialPayments;


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
                    AppColors.dynamicSurface(context).withValues(alpha: 0.8),
                    AppColors.dynamicSurface(context).withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                  ),
                  const SizedBox(height: 12),
                  _buildProfitLossCard(
                    'Total Debts',
                    totalDebts,
                    Icons.arrow_downward,
                    AppColors.error,
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
        color: AppColors.dynamicSurface(context).withValues(alpha: 0.5), // 0.5 * 255
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.1), // 0.1 * 255
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