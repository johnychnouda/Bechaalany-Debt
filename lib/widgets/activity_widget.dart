import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../models/activity.dart';
import '../models/debt.dart';
import '../screens/full_activity_list_screen.dart';
import '../utils/debt_description_utils.dart';

class ActivityWidget extends StatefulWidget {
  const ActivityWidget({super.key});

  @override
  State<ActivityWidget> createState() => _ActivityWidgetState();
}

class _ActivityWidgetState extends State<ActivityWidget> {
  ActivityView _currentView = ActivityView.daily;
  Timer? _timer;

  // void _cycleView() { // Removed unused method
  //   setState(() {
  //     switch (_currentView) {
  //       case ActivityView.daily:
  //         _currentView = ActivityView.weekly;
  //         break;
  //       case ActivityView.weekly:
  //         _currentView = ActivityView.monthly;
  //         break;
  //       case ActivityView.monthly:
  //         _currentView = ActivityView.yearly;
  //         break;
  //       case ActivityView.yearly:
  //         _currentView = ActivityView.daily;
  //         break;
  //     }
  //   });
  // }

  // String _getViewTitle() { // Removed unused method
  //   final now = DateTime.now();
  //   switch (_currentView) {
  //     case ActivityView.daily:
  //       return 'Daily Activity - ${_formatShortDate(now)}';
  //     case ActivityView.weekly:
  //       return 'Weekly Activity - ${_getWeekRange(now)}';
  //     case ActivityView.monthly:
  //       return 'Monthly Activity - ${_getMonthYear(now)}';
  //     case ActivityView.yearly:
  //       return 'Yearly Activity - ${now.year}';
  //   }
  // }

  // String _formatShortDate(DateTime date) { // Removed unused method
  //   const months = [
  //     'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  //     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  //   ];
  //   return '${months[date.month - 1]} ${date.day}';
  // }

  // String _getMonthYear(DateTime date) { // Removed unused method
  //   const months = [
  //     'January', 'February', 'March', 'April', 'May', 'June',
  //     'July', 'August', 'September', 'October', 'November', 'December'
  //   ];
  //   return '${months[date.month - 1]} ${date.year}';
  // }

  // String _getWeekRange(DateTime date) { // Removed unused method
  //   final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
  //   final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
  //   // Use compact format with month names
  //   const months = [
  //     'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  //     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  //   ];
    
  //   String startStr = '${months[startOfWeek.month - 1]} ${startOfWeek.day}';
  //   String endStr = '${months[endOfWeek.month - 1]} ${endOfWeek.day}';
    
  //   // If same month, only show month once
  //   if (startOfWeek.month == endOfWeek.month) {
  //     return '$startStr - ${endOfWeek.day}';
  //   } else {
  //     return '$startStr - $endStr';
  //   }
  // }

  @override
  void initState() {
    super.initState();
    // Start timer to update time ago text every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FullActivityListScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.list_alt_outlined,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Content based on current view
                _buildCurrentView(appState),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(AppState appState) {
    return _buildActivitiesList(appState, 'Today\'s Activity');
  }

  List<Activity> _getActivitiesForPeriod(AppState appState, ActivityView view) {
    final activities = <Activity>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Define date ranges based on view
    DateTime startDate, endDate;
    switch (view) {
      case ActivityView.daily:
        startDate = today;
        endDate = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        break;
      case ActivityView.weekly:
        startDate = today.subtract(Duration(days: today.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case ActivityView.monthly:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case ActivityView.yearly:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
    }

    for (final activity in appState.activities) {
      // Filter out debtCleared activities - only show new debts and payments
      if (activity.type == ActivityType.debtCleared) {
        continue;
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

  Widget _buildActivitiesList(AppState appState, String title) {
    final activities = _getActivitiesForPeriod(appState, ActivityView.daily);
    
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Take the top 3 activities
    final topActivities = activities.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...topActivities.map((activity) => _buildActivityItem(activity)),
      ],
    );
  }

  Widget _buildActivityItem(Activity activity) {
    // Determine if this is a full payment using the helper method
    bool isFullPayment = activity.isPaymentCompleted;
    
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
        // This case should not be reached since we filter out debtCleared activities
        icon = Icons.delete_forever;
        iconColor = Colors.red;
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
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
                  ),
                ),
                const SizedBox(height: 2),
                // Only show product description for new debts, not for payments
                if (activity.type == ActivityType.newDebt)
                  Text(
                    DebtDescriptionUtils.cleanDescription(activity.description),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (activity.type == ActivityType.newDebt)
                Text(
                  CurrencyFormatter.formatAmount(context, activity.amount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              if (activity.type == ActivityType.payment && activity.paymentAmount != null)
                Text(
                  isFullPayment
                      ? 'Fully Paid: ${CurrencyFormatter.formatAmount(context, activity.paymentAmount!)}'
                      : 'Partial: ${CurrencyFormatter.formatAmount(context, activity.paymentAmount!)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isFullPayment ? AppColors.success : AppColors.warning,
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
      // Show full date and time for activities older than 1 day
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      String month = months[dateTime.month - 1];
      String day = dateTime.day.toString().padLeft(2, '0');
      
      // Convert to 12-hour format with AM/PM
      int hour12 = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
      String minute = dateTime.minute.toString().padLeft(2, '0');
      String ampm = dateTime.hour < 12 ? 'am' : 'pm';
      
      return '$month $day, $hour12:$minute $ampm';
    }
  }
} 