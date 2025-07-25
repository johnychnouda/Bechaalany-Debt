import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final allDebts = appState.debts;
        
        // Get recent activities (last 7 days)
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        
        final recentDebts = allDebts.where((debt) => 
          debt.createdAt.isAfter(sevenDaysAgo) || 
          (debt.status == DebtStatus.paid && debt.paidAt != null && debt.paidAt!.isAfter(sevenDaysAgo))
        ).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Take the most recent 5 activities
        final recentActivities = recentDebts.take(5).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (recentActivities.isEmpty)
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 32,
                          color: AppColors.textLight,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: recentActivities.map((debt) {
                      final isPaid = debt.status == DebtStatus.paid;
                      final isNew = debt.createdAt.isAfter(now.subtract(const Duration(days: 1)));
                      final isRecentlyPaid = debt.paidAt != null && 
                                           debt.paidAt!.isAfter(now.subtract(const Duration(days: 1)));
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isPaid 
                                    ? AppColors.success.withOpacity(0.1)
                                    : isNew 
                                        ? AppColors.primary.withOpacity(0.1)
                                        : AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isPaid 
                                    ? Icons.check_circle
                                    : isNew 
                                        ? Icons.add_circle
                                        : Icons.edit,
                                color: isPaid 
                                    ? AppColors.success
                                    : isNew 
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    debt.customerName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    debt.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _getActivityText(debt, isNew, isRecentlyPaid),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isPaid 
                                          ? AppColors.success
                                          : isNew 
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${debt.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isPaid 
                                        ? AppColors.success
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(isPaid ? debt.paidAt! : debt.createdAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getActivityText(Debt debt, bool isNew, bool isRecentlyPaid) {
    if (debt.status == DebtStatus.paid) {
      return 'Payment completed';
    } else if (isNew) {
      return 'New debt added';
    } else if (isRecentlyPaid) {
      return 'Recently paid';
    } else {
      return 'Debt created';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
} 