import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';

class CustomerPaymentHistoryWidget extends StatefulWidget {
  const CustomerPaymentHistoryWidget({super.key});

  @override
  State<CustomerPaymentHistoryWidget> createState() => _CustomerPaymentHistoryWidgetState();
}

class _CustomerPaymentHistoryWidgetState extends State<CustomerPaymentHistoryWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      begin: const Offset(0, 0.2),
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
        final customersWithHistory = _getCustomersWithPaymentHistory(appState.customers, appState.debts);
        
        if (customersWithHistory.isEmpty) {
          return _buildEmptyState();
        }

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
                    AppColors.dynamicSurface(context).withOpacity(0.8),
                    AppColors.dynamicSurface(context).withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Payment History',
                        style: AppTheme.title3.copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...customersWithHistory.take(3).map((customerData) => 
                    _buildCustomerPaymentCard(customerData)
                  ).toList(),
                  if (customersWithHistory.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(
                          '+${customersWithHistory.length - 3} more customers',
                          style: AppTheme.footnote.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.dynamicSurface(context).withOpacity(0.8),
            AppColors.dynamicSurface(context).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: AppColors.dynamicTextSecondary(context).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Payment History',
            style: AppTheme.title3.copyWith(
              color: AppColors.dynamicTextPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment patterns will appear here once customers start making payments',
            style: AppTheme.footnote.copyWith(
              color: AppColors.dynamicTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerPaymentCard(Map<String, dynamic> customerData) {
    final customer = customerData['customer'] as Customer;
    final totalPaid = customerData['totalPaid'] as double;
    final totalDebt = customerData['totalDebt'] as double;
    final paymentCount = customerData['paymentCount'] as int;
    final lastPayment = customerData['lastPayment'] as DateTime?;
    final averagePayment = paymentCount > 0 ? totalPaid / paymentCount : 0.0;
    final paymentRate = totalDebt > 0 ? (totalPaid / totalDebt) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: AppTheme.title3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: AppTheme.title3.copyWith(
                        color: AppColors.dynamicTextPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${paymentCount} payments',
                      style: AppTheme.footnote.copyWith(
                        color: AppColors.dynamicTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: paymentRate >= 80 
                      ? AppColors.success 
                      : paymentRate >= 50 
                          ? AppColors.warning 
                          : AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${paymentRate.toStringAsFixed(0)}%',
                  style: AppTheme.footnote.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPaymentStat(
                  'Total Paid',
                  '\$${totalPaid.toStringAsFixed(0)}',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentStat(
                  'Avg Payment',
                  '\$${averagePayment.toStringAsFixed(0)}',
                  Icons.analytics,
                  AppColors.primary,
                ),
              ),
            ],
          ),
          if (lastPayment != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppColors.dynamicTextSecondary(context),
                ),
                const SizedBox(width: 4),
                Text(
                  'Last payment: ${_formatDate(lastPayment)}',
                  style: AppTheme.footnote.copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTheme.footnote.copyWith(
                  color: AppColors.dynamicTextSecondary(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.title3.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCustomersWithPaymentHistory(List<Customer> customers, List<Debt> debts) {
    final List<Map<String, dynamic>> customersWithHistory = [];

    for (final customer in customers) {
      final customerDebts = debts.where((d) => d.customerId == customer.id).toList();
      final paidDebts = customerDebts.where((d) => d.status == DebtStatus.paid).toList();
      
      if (paidDebts.isNotEmpty) {
        final totalPaid = paidDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
        final totalDebt = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
        final lastPayment = paidDebts
            .map((d) => d.paidAt!)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        customersWithHistory.add({
          'customer': customer,
          'totalPaid': totalPaid,
          'totalDebt': totalDebt,
          'paymentCount': paidDebts.length,
          'lastPayment': lastPayment,
        });
      }
    }

    // Sort by total paid amount (descending)
    customersWithHistory.sort((a, b) => (b['totalPaid'] as double).compareTo(a['totalPaid'] as double));
    
    return customersWithHistory;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 