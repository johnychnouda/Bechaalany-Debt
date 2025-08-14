import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../models/activity.dart';
import '../utils/currency_formatter.dart';
import '../utils/debt_description_utils.dart';

enum ActivityView { daily, weekly, monthly, yearly }

class FullActivityListScreen extends StatefulWidget {
  final ActivityView initialView;

  const FullActivityListScreen({
    super.key,
    this.initialView = ActivityView.daily,
  });

  @override
  State<FullActivityListScreen> createState() => _FullActivityListScreenState();
}

class _FullActivityListScreenState extends State<FullActivityListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ActivityView _currentView = ActivityView.daily;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _currentView.index,
    );
    _tabController.addListener(() {
      setState(() {
        _currentView = ActivityView.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.dynamicSurface(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Activity History',
          style: AppTheme.title3.copyWith(
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Activity List
          Expanded(
            child: TabBarView(
              controller: _tabController,
                        children: [
            _buildActivityView(ActivityView.daily),
            _buildActivityView(ActivityView.weekly),
            _buildActivityView(ActivityView.monthly),
            _buildActivityView(ActivityView.yearly),
          ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityView(ActivityView view) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final activities = _getActivitiesForView(appState, view);
        final filteredActivities = _filterActivities(activities);
        final title = _getViewTitle(view);
        final emptyMessage = _searchQuery.isNotEmpty 
            ? 'No activities found for "$_searchQuery"'
            : _getEmptyMessage(view);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: AppTheme.title2.copyWith(
                  color: AppColors.dynamicTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                                      hintText: 'Search by name or ID',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.dynamicSurface(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: filteredActivities.isEmpty
                  ? _buildEmptyState(emptyMessage)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredActivities.length,
                      itemBuilder: (context, index) {
                        return _buildActivityItem(filteredActivities[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
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
                const SizedBox(height: 4),
                Text(
                  _formatActivityDate(activity.date),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
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

  String _formatActivityDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    switch (_currentView) {
      case ActivityView.daily:
        if (activityDate == today) {
          return 'Today at ${_formatTime12Hour(date)}';
        } else if (activityDate == yesterday) {
          return 'Yesterday at ${_formatTime12Hour(date)}';
        } else {
          return '${_formatDate(date)} at ${_formatTime12Hour(date)}';
        }
      case ActivityView.weekly:
      case ActivityView.monthly:
      case ActivityView.yearly:
        return '${_formatDayDate(date)} at ${_formatTime12Hour(date)}';
    }
  }

  String _formatTime12Hour(DateTime date) {
    int hour = date.hour;
    String period = 'am';
    
    if (hour >= 12) {
      period = 'pm';
      if (hour > 12) {
        hour -= 12;
      }
    }
    if (hour == 0) {
      hour = 12;
    }
    
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second $period';
  }

  String _formatDayDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    final day = date.day;
    
    return '$dayName $day $monthName';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getViewTitle(ActivityView view) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (view) {
      case ActivityView.daily:
        return 'Last 24 Hours Activity';
      case ActivityView.weekly:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return 'Weekly Activity - ${_formatShortDate(startOfWeek)} - ${_formatShortDate(endOfWeek)}';
      case ActivityView.monthly:
        return 'Monthly Activity - ${_getMonthYear(now)}';
      case ActivityView.yearly:
        return 'Yearly Activity - ${now.year}';
    }
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  String _formatShortDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getMonthYear(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getEmptyMessage(ActivityView view) {
    switch (view) {
      case ActivityView.daily:
        return 'No activity in the last 24 hours\nAdd debts or make payments to see activity here';
      case ActivityView.weekly:
        return 'No activity this week\nAdd debts or make payments to see activity here';
      case ActivityView.monthly:
        return 'No activity this month\nAdd debts or make payments to see activity here';
      case ActivityView.yearly:
        return 'No activity this year\nAdd debts or make payments to see activity here';
    }
  }

  List<Activity> _getActivitiesForView(AppState appState, ActivityView view) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (view) {
      case ActivityView.daily:
        // Show activities from the last 24 hours instead of just today
        final startDate = now.subtract(const Duration(hours: 24));
        final endDate = now;
        return _getActivitiesForPeriod(appState, startDate, endDate);
        
      case ActivityView.weekly:
        // Show activities created this week (Monday to Sunday)
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return _getActivitiesForPeriod(appState, startOfWeek, endOfWeek);
        
      case ActivityView.monthly:
        // Show activities created this month
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return _getActivitiesForPeriod(appState, startOfMonth, endOfMonth);
        
      case ActivityView.yearly:
        // Show activities created this year
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        return _getActivitiesForPeriod(appState, startOfYear, endOfYear);
    }
  }

  List<Activity> _getActivitiesForPeriod(AppState appState, DateTime startDate, DateTime endDate) {
    final activities = <Activity>[];

    // Get activities from the new Activity model
    for (final activity in appState.activities) {
      // Filter out debtCleared activities - only show new debts and payments
      if (activity.type == ActivityType.debtCleared) {
        continue; // Skip cleared activities
      }
      
      // Check if activity date is within the period
      bool isWithinPeriod;
      
      // For daily view (24-hour rolling window), use exact time comparison
      if (startDate.hour > 0 || endDate.hour > 0) {
        isWithinPeriod = activity.date.isAfter(startDate) && activity.date.isBefore(endDate);
      } else {
        // For other views (weekly, monthly, yearly), use date-only comparison
        final activityDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
        isWithinPeriod = (activityDate.isAtSameMomentAs(startDate) || activityDate.isAfter(startDate)) && 
                        (activityDate.isAtSameMomentAs(endDate) || activityDate.isBefore(endDate));
      }
      
      if (isWithinPeriod) {
        // Additional filter: For payment activities, check if they're still relevant
        if (activity.type == ActivityType.payment && activity.debtId == null) {
          // Check if this activity is for a customer who still has pending debts
          final customerDebts = appState.debts.where((d) => d.customerId == activity.customerId).toList();
          final hasPendingDebts = customerDebts.any((d) => !d.isFullyPaid);
          
          // Only show payment activities if the customer still has pending debts
          // or if this is a recent activity (within last 24 hours)
          final isRecent = DateTime.now().difference(activity.date).inHours < 24;
          
          if (!hasPendingDebts && !isRecent) {
            continue; // Skip this activity
          }
        }
        
        activities.add(activity);
      }
    }

    // Sort by date (newest first)
    activities.sort((a, b) => b.date.compareTo(a.date));
    
    return activities;
  }

  List<Activity> _filterActivities(List<Activity> activities) {
    if (_searchQuery.isEmpty) {
      return activities;
    }
    
    final searchQuery = _searchQuery.trim();
    final isNumericQuery = int.tryParse(searchQuery) != null;
    
    return activities.where((activity) {
      final customerName = activity.customerName.toLowerCase();
      final searchQueryLower = searchQuery.toLowerCase();
      
      if (isNumericQuery) {
        // Search by customer ID (exact match for numbers)
        return activity.customerId == searchQuery;
      } else {
        // Search by customer name (contains match for text)
        return customerName.contains(searchQueryLower);
      }
    }).toList();
  }
} 