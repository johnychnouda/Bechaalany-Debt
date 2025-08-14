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
  final bool compact;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.iconColor,
    this.onAction,
    this.actionText,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.dynamicSurface(context).withAlpha(204), // 0.8 * 255
            AppColors.dynamicSurface(context).withAlpha(153), // 0.6 * 255
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 12 : 20),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withAlpha(26), // 0.1 * 255
              borderRadius: BorderRadius.circular(compact ? 30 : 50),
            ),
            child: Icon(
              icon,
              size: compact ? 24 : 48,
              color: iconColor ?? AppColors.primary,
            ),
          ),
          SizedBox(height: compact ? 12 : 24),
          Text(
            title,
            style: AppTheme.title2.copyWith(
              color: AppColors.dynamicTextPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: compact ? 14 : null,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            message,
            style: AppTheme.body.copyWith(
              color: AppColors.dynamicTextSecondary(context),
              fontSize: compact ? 12 : null,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            SizedBox(height: compact ? 12 : 24),
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
      title: 'All caught up!',
      message: 'No new activity in the last 24 hours',
      icon: Icons.access_time_outlined,
      compact: true,
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