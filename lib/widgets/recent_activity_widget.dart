import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/debt.dart';
import '../models/activity.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../utils/debt_description_utils.dart';

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Get recent activities (last 7 days)
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        
        // Debug: Print total activities count
        print('Total activities in appState: ${appState.activities.length}');
        
        final recentActivities = appState.activities.where((activity) => 
          activity.date.isAfter(sevenDaysAgo)
        ).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        
        // Debug: Print recent activities count
        print('Recent activities count: ${recentActivities.length}');
        
        // Take the most recent 5 activities
        final recentActivitiesList = recentActivities.take(5).toList();

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
                        color: AppColors.success.withValues(alpha: 0.1),
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
                
                if (recentActivitiesList.isEmpty)
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
                    children: recentActivitiesList.map((activity) {
                      final isPaid = activity.type == ActivityType.payment;
                      final isNew = activity.type == ActivityType.newDebt;
                      final isRecentlyPaid = activity.type == ActivityType.payment && 
                                           activity.date.isAfter(now.subtract(const Duration(days: 1)));
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isPaid 
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : isNew 
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : AppColors.secondary.withValues(alpha: 0.1),
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
                                    activity.customerName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    DebtDescriptionUtils.cleanDescription(activity.description),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    _getActivityText(activity, isNew, isRecentlyPaid),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isPaid 
                                          ? AppColors.success
                                          : AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.formatAmount(context, activity.amount),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isPaid 
                                        ? AppColors.success
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(activity.date),
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

  String _getActivityText(Activity activity, bool isNew, bool isRecentlyPaid) {
    switch (activity.type) {
      case ActivityType.payment:
        return 'Payment completed';
      case ActivityType.newDebt:
        return 'New debt added';
      case ActivityType.debtCleared:
        return 'Debt cleared';
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