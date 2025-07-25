import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.iconColor,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              size: 48,
              color: iconColor ?? AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTheme.title2.copyWith(
              color: AppColors.dynamicTextPrimary(context),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTheme.body.copyWith(
              color: AppColors.dynamicTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionText!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Predefined empty states
class EmptyStates {
  static Widget noCustomers() {
    return const EmptyStateWidget(
      title: 'No Customers Yet',
      message: 'Start by adding your first customer to track their debts and payments.',
      icon: Icons.people_outline,
      actionText: 'Add Customer',
    );
  }

  static Widget noDebts() {
    return const EmptyStateWidget(
      title: 'No Debts Recorded',
      message: 'Begin tracking debts by adding your first debt entry.',
      icon: Icons.account_balance_wallet_outlined,
      actionText: 'Add Debt',
    );
  }

  static Widget noPayments() {
    return const EmptyStateWidget(
      title: 'No Payment History',
      message: 'Payment patterns will appear here once customers start making payments.',
      icon: Icons.payment_outlined,
    );
  }

  static Widget noRecentActivity() {
    return const EmptyStateWidget(
      title: 'No Recent Activity',
      message: 'Activity will appear here as you add customers and debts.',
      icon: Icons.access_time_outlined,
    );
  }

  static Widget noOverdueDebts() {
    return const EmptyStateWidget(
      title: 'No Overdue Debts',
      message: 'Great! All your debts are up to date.',
      icon: Icons.check_circle_outline,
      iconColor: AppColors.success,
    );
  }

  static Widget noPendingDebts() {
    return const EmptyStateWidget(
      title: 'No Pending Debts',
      message: 'All debts have been resolved.',
      icon: Icons.done_all_outlined,
      iconColor: AppColors.success,
    );
  }

  static Widget noSearchResults() {
    return const EmptyStateWidget(
      title: 'No Results Found',
      message: 'Try adjusting your search criteria or add new entries.',
      icon: Icons.search_off_outlined,
      iconColor: AppColors.warning,
    );
  }

  static Widget noData() {
    return const EmptyStateWidget(
      title: 'No Data Available',
      message: 'Start by adding customers and debts to see your dashboard.',
      icon: Icons.dashboard_outlined,
    );
  }
} 