import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../models/debt.dart';
import '../models/activity.dart';
import '../screens/full_activity_list_screen.dart';

class WeeklyActivityWidget extends StatefulWidget {
  const WeeklyActivityWidget({super.key});

  @override
  State<WeeklyActivityWidget> createState() => _WeeklyActivityWidgetState();
}

class _WeeklyActivityWidgetState extends State<WeeklyActivityWidget>
    with TickerProviderStateMixin {
  ActivityView _currentView = ActivityView.daily;

  void _cycleView() {
    setState(() {
      switch (_currentView) {
        case ActivityView.daily:
          _currentView = ActivityView.weekly;
          break;
        case ActivityView.weekly:
          _currentView = ActivityView.monthly;
          break;
        case ActivityView.monthly:
          _currentView = ActivityView.daily;
          break;
      }
    });
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  String _getViewTitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_currentView) {
      case ActivityView.daily:
        return 'Daily Activity - ${_getDayName(today)}';
      case ActivityView.weekly:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return 'Weekly Activity - ${_formatShortDate(startOfWeek)} - ${_formatShortDate(endOfWeek)}';
      case ActivityView.monthly:
        return 'Monthly Activity - ${_getMonthYear(now)}';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
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
                    GestureDetector(
                      onTap: _cycleView,
                      child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppColors.secondary,
                        size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getViewTitle(),
                        style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullActivityListScreen(
                              initialView: _currentView,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt_outlined),
                      color: AppColors.secondary,
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
    switch (_currentView) {
      case ActivityView.daily:
        return _buildDailyView(appState);
      case ActivityView.weekly:
        return _buildWeeklyView(appState);
      case ActivityView.monthly:
        return _buildMonthlyView(appState);
    }
  }

  List<Activity> _getActivitiesForPeriod(AppState appState, DateTime startDate, DateTime endDate) {
    final activities = <Activity>[];

    // Get activities from the new Activity model
    for (final activity in appState.activities) {
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

  List<Activity> _getActivitiesForDailyPeriod(AppState appState, DateTime startDate, DateTime endDate) {
    final activities = <Activity>[];

    // Get activities from the new Activity model
    for (final activity in appState.activities) {
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

  Widget _buildDailyView(AppState appState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today; // Start at 12:00 AM (midnight) of today
    final endDate = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // End at 11:59:59.999 PM of today
    
    final activities = _getActivitiesForDailyPeriod(appState, startDate, endDate);
    final emptyMessage = "No activity today";

    return _buildActivityContent(
      activities: activities,
      emptyMessage: emptyMessage,
      emptyIcon: Icons.today_outlined,
      showNewBadge: false,
    );
  }

  Widget _buildWeeklyView(AppState appState) {
    final now = DateTime.now();
    // Get start of week (Monday) and end of week (Sunday)
    final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final activities = _getActivitiesForPeriod(appState, startOfWeek, endOfWeek);
    
    return _buildActivityContent(
      activities: activities,
      emptyMessage: 'No activity this week',
      emptyIcon: Icons.event_busy,
      showNewBadge: false, // Don't show blue "New" badge for weekly view
    );
  }

  Widget _buildMonthlyView(AppState appState) {
    final now = DateTime.now();
    // Get start of month (day 1) and end of month (last day)
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0); // Last day of current month
    
    final activities = _getActivitiesForPeriod(appState, startOfMonth, endOfMonth);
    
    return _buildActivityContent(
      activities: activities,
      emptyMessage: 'No activity this month',
      emptyIcon: Icons.calendar_month_outlined,
      showNewBadge: false, // Don't show blue "New" badge for monthly view
    );
  }

  Widget _buildActivityContent({
    required List<Activity> activities,
    required String emptyMessage,
    required IconData emptyIcon,
    bool showNewBadge = false,
  }) {
    // Limit to latest 3 activities
    final limitedActivities = activities.take(3).toList();
    
    if (limitedActivities.isEmpty) {
      return Container(
        height: 120,
        child: Center(
                    child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                emptyIcon,
                          size: 32,
                          color: AppColors.textLight,
                        ),
              const SizedBox(height: 8),
                        Text(
                emptyMessage,
                style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Activity List (limited to 3)
        ...limitedActivities.map((activity) => _buildActivityItem(activity, showNewBadge: showNewBadge)).toList(),
      ],
    );
  }

  Widget _buildActivityItem(Activity activity, {bool showNewBadge = false}) {
    IconData icon;
    Color iconColor;
    String typeText;
    Color typeColor;

    switch (activity.type) {
      case ActivityType.newDebt:
        icon = Icons.add_circle;
        iconColor = AppColors.primary;
        typeText = 'New';
        typeColor = AppColors.primary;
        break;
      case ActivityType.payment:
        icon = Icons.payment;
        // Use orange for partial payments, green for full payments
        if (activity.paymentAmount != null && activity.paymentAmount! < activity.amount) {
          iconColor = AppColors.warning; // Orange for partial payments
        } else {
          iconColor = AppColors.success; // Green for full payments
        }
        typeText = 'Paid';
        typeColor = AppColors.success;
        break;
      case ActivityType.debtCleared:
        icon = Icons.update;
        iconColor = AppColors.warning;
        typeText = 'Status';
        typeColor = AppColors.warning;
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
              color: iconColor.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (showNewBadge && activity.type == ActivityType.newDebt)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'New',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                                    ),
                                  ),
                                ],
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (activity.paymentAmount != null && activity.paymentAmount! > 0)
                            Text(
                  activity.paymentAmount == activity.amount 
                    ? 'Paid: ${CurrencyFormatter.formatAmount(context, activity.paymentAmount!)}'
                    : 'Partial: ${CurrencyFormatter.formatAmount(context, activity.paymentAmount!)}',
                              style: TextStyle(
                    fontSize: 14,
                    color: activity.paymentAmount == activity.amount ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                  ),
              ],
            ),
    );
  }
} 