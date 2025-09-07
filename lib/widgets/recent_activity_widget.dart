import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';

import '../models/activity.dart';
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
        final topActivities = activities.take(3).toList();
        
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last 24 Hours Activity',
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
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: topActivities.map((activity) {
                                                          // Determine if this is a full payment using the helper method
                                    bool isFullPayment = activity.isPaymentCompleted;
                      
                      IconData icon;
                      Color iconColor;
                      Color backgroundColor;

                      switch (activity.type) {
                        case ActivityType.newDebt:
                          // Check if this debt is still pending or has been paid
                          if (activity.debtId != null) {
                            // Try to find the current debt status
                            final currentDebt = appState.debts.where(
                              (debt) => debt.id == activity.debtId,
                            ).firstOrNull;
                            
                            if (currentDebt != null) {
                              // Use customer-level status to determine display
                              final isCustomerFullyPaid = appState.isCustomerFullyPaid(currentDebt.customerId);
                              
                              if (isCustomerFullyPaid) {
                                // Customer has settled ALL debts - show green checkmark
                                icon = Icons.check_circle;
                                iconColor = AppColors.success;
                                backgroundColor = AppColors.success.withValues(alpha: 0.1);
                              } else {
                                // Customer still has outstanding debts - show red X
                                icon = Icons.close;
                                iconColor = AppColors.error;
                                backgroundColor = AppColors.error.withValues(alpha: 0.1);
                              }
                            } else {
                              // Debt not found - show as outstanding
                              icon = Icons.close;
                              iconColor = AppColors.error;
                              backgroundColor = AppColors.error.withValues(alpha: 0.1);
                            }
                          } else {
                            // Fallback to blue plus if no debt ID
                            icon = Icons.add_circle;
                            iconColor = AppColors.primary;
                            backgroundColor = AppColors.primary.withValues(alpha: 0.1);
                          }
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
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: iconColor,
                                size: 16,
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
                                  // For fully paid activities, show only the payment amount
                                  if (activity.type == ActivityType.payment && isFullPayment && appState.isCustomerFullyPaid(activity.customerId))
                                    Text(
                                      '${activity.paymentAmount?.toStringAsFixed(2)}\$',
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
        return 'Last 24 Hours Activity';
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

    // Get activities without duplicates (without modifying state)
    final activitiesWithoutDuplicates = _removeDuplicatesFromList(appState.activities);

    for (final activity in activitiesWithoutDuplicates) {
      
      // Check if activity date is within the period
      if (startDate.hour == 0 && startDate.minute == 0 && startDate.second == 0) {
        // This is a date-only range (weekly, monthly, yearly)
        final activityDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
        if ((activityDate.isAtSameMomentAs(startDate) || activityDate.isAfter(startDate)) && 
            (activityDate.isAtSameMomentAs(endDate) || activityDate.isBefore(endDate))) {
          activities.add(activity);
        }
      } else {
        // This is a time-based range (daily - last 24 hours)
        if (activity.date.isAfter(startDate) && activity.date.isBefore(endDate)) {
          activities.add(activity);
        }
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
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    // Convert to 12-hour format with AM/PM and seconds
    int hour12 = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');
    String ampm = dateTime.hour < 12 ? 'am' : 'pm';
    String timeString = '$hour12:$minute:$second $ampm';
    
    // Compare the actual date part
    final activityDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (activityDate == today) {
      return 'Today at $timeString';
    } else if (activityDate == yesterday) {
      return 'Yesterday at $timeString';
    } else {
      // Show full date and time for activities older than yesterday
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      String month = months[dateTime.month - 1];
      String day = dateTime.day.toString().padLeft(2, '0');
      String year = dateTime.year.toString();
      
      return '$month $day, $year at $timeString';
    }
  }

  /// Helper method to remove duplicates from a list without modifying state
  List<Activity> _removeDuplicatesFromList(List<Activity> activities) {
    try {
      final activitiesToKeep = <Activity>[];
      final seenIds = <String>{};
      
      for (final activity in activities) {
        if (!seenIds.contains(activity.id)) {
          activitiesToKeep.add(activity);
          seenIds.add(activity.id);
        }
      }
      
      return activitiesToKeep;
    } catch (e) {
      return activities; // Return original list if error occurs
    }
  }
} 