import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';

import '../models/activity.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../utils/debt_description_utils.dart';

enum ActivityPeriod { daily, weekly, monthly, yearly }

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Get daily activities only
        final activities = _getActivitiesForPeriod(appState, ActivityPeriod.daily);
        
        // Take the top 3 activities and filter out cleared activities
        final topActivities = activities.where((activity) => activity.type != ActivityType.debtCleared).take(3).toList();
        
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
                    Expanded(
                      child: Text(
                        'Today\'s Activity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (topActivities.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 32,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add debts or make payments to see activity here',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: topActivities.map((activity) {
                      // Determine if this is a full payment
                      bool isFullPayment = activity.type == ActivityType.payment && 
                                         activity.paymentAmount != null && 
                                         activity.newStatus == DebtStatus.paid;
                      
                      IconData icon;
                      Color iconColor;
                      Color backgroundColor;

                      switch (activity.type) {
                        case ActivityType.newDebt:
                          icon = Icons.add_circle;
                          iconColor = AppColors.primary;
                          backgroundColor = AppColors.primary.withValues(alpha: 0.1);
                          break;
                        case ActivityType.payment:
                          if (isFullPayment) {
                            icon = Icons.check_circle;
                            iconColor = AppColors.success;
                            backgroundColor = AppColors.success.withValues(alpha: 0.1);
                          } else {
                            icon = Icons.payment;
                            iconColor = AppColors.warning;
                            backgroundColor = AppColors.warning.withValues(alpha: 0.1);
                          }
                          break;
                        case ActivityType.debtCleared:
                          icon = Icons.check_circle;
                          iconColor = AppColors.success;
                          backgroundColor = AppColors.success.withValues(alpha: 0.1);
                          break;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: iconColor,
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
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  // Only show product description for new debts, not for payments
                                  if (activity.type == ActivityType.newDebt)
                                    Text(
                                      DebtDescriptionUtils.cleanDescription(activity.description),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  Text(
                                    _getActivityText(activity, isFullPayment),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: activity.type == ActivityType.payment 
                                          ? (isFullPayment ? AppColors.success : AppColors.warning)
                                          : AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Centered date between left icon and right amount
                            Expanded(
                              child: Center(
                                child: Text(
                                  _getTimeAgo(activity.date),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (activity.type == ActivityType.newDebt)
                                  Text(
                                    CurrencyFormatter.formatAmount(context, activity.amount),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                if (activity.type == ActivityType.payment && activity.paymentAmount != null)
                                  Text(
                                    CurrencyFormatter.formatAmount(context, activity.paymentAmount!),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isFullPayment ? AppColors.success : AppColors.warning,
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

  String _getPeriodTitle(ActivityPeriod period) {
    switch (period) {
      case ActivityPeriod.daily:
        return 'Today\'s Activity';
      case ActivityPeriod.weekly:
        return 'Weekly Activity';
      case ActivityPeriod.monthly:
        return 'Monthly Activity';
      case ActivityPeriod.yearly:
        return 'Yearly Activity';
    }
  }

  List<Activity> _getActivitiesForPeriod(AppState appState, ActivityPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (period) {
      case ActivityPeriod.daily:
        final startDate = today;
        final endDate = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        return _getActivitiesForDateRange(appState, startDate, endDate);
        
      case ActivityPeriod.weekly:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return _getActivitiesForDateRange(appState, startOfWeek, endOfWeek);
        
      case ActivityPeriod.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return _getActivitiesForDateRange(appState, startOfMonth, endOfMonth);
        
      case ActivityPeriod.yearly:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        return _getActivitiesForDateRange(appState, startOfYear, endOfYear);
    }
  }

  List<Activity> _getActivitiesForDateRange(AppState appState, DateTime startDate, DateTime endDate) {
    final activities = <Activity>[];

    for (final activity in appState.activities) {
      // Filter out debtCleared activities - only show new debts and payments
      if (activity.type == ActivityType.debtCleared) {
        continue; // Skip cleared activities
      }
      
      // Check if activity date is within the period (inclusive)
      final activityDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
      if ((activityDate.isAtSameMomentAs(startDate) || activityDate.isAfter(startDate)) && 
          (activityDate.isAtSameMomentAs(endDate) || activityDate.isBefore(endDate))) {
        
        activities.add(activity);
      }
    }

    // Sort by date (newest first)
    activities.sort((a, b) => b.date.compareTo(a.date));
    return activities;
  }

  String _getActivityText(Activity activity, bool isFullPayment) {
    switch (activity.type) {
      case ActivityType.payment:
        return isFullPayment ? 'Payment completed' : 'Partial payment';
      case ActivityType.newDebt:
        return 'New debt added';
      case ActivityType.debtCleared:
        return 'Debt cleared'; // This case should not be reached since we filter out debtCleared
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