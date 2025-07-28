import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../models/activity.dart';
import '../utils/currency_formatter.dart';

enum ActivityView { daily, weekly, monthly }

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
      length: 3,
      vsync: this,
      initialIndex: _currentView.index,
    );
    _tabController.addListener(() {
      setState(() {
        _currentView = ActivityView.values[_tabController.index];
      });
    });
    
    // Add sample data for testing if no debts exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addSampleDataIfNeeded();
    });
  }

  void _addSampleDataIfNeeded() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.debts.isNotEmpty) {
      for (final debt in appState.debts) {
      }
    }
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
              ),
            ),
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by customer name or ID...',
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
    IconData icon;
    Color iconColor;

    switch (activity.type) {
      case ActivityType.newDebt:
        icon = Icons.add_circle;
        iconColor = AppColors.primary;
        break;
      case ActivityType.payment:
        icon = Icons.payment;
        iconColor = AppColors.success;
        break;
      case ActivityType.debtCleared:
        icon = Icons.delete_forever;
        iconColor = AppColors.warning;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
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
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: AppTheme.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatActivityDate(activity.date),
                        style: AppTheme.caption1.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      if (activity.type == ActivityType.newDebt)
                        Text(
                          CurrencyFormatter.formatAmount(context, activity.amount),
                          style: AppTheme.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      if (activity.type == ActivityType.payment && activity.paymentAmount != null)
                        Text(
                          activity.paymentAmount == activity.amount
                              ? 'Fully Paid: ${CurrencyFormatter.formatAmount(context, activity.paymentAmount!)}'
                              : 'Partial Payment: ${CurrencyFormatter.formatAmount(context, activity.paymentAmount!)}',
                          style: AppTheme.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: activity.paymentAmount == activity.amount ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      if (activity.type == ActivityType.debtCleared)
                        Text(
                          'Cleared: ${CurrencyFormatter.formatAmount(context, activity.amount)}',
                          style: AppTheme.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    return '$hour:$minute $period';
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
        return 'Daily Activity - ${_getDayName(today)}';
      case ActivityView.weekly:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return 'Weekly Activity - ${_formatShortDate(startOfWeek)} - ${_formatShortDate(endOfWeek)}';
      case ActivityView.monthly:
        return 'Monthly Activity - ${_getMonthYear(now)}';
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
        return 'No activity today';
      case ActivityView.weekly:
        return 'No activity this week';
      case ActivityView.monthly:
        return 'No activity this month';
    }
  }

  List<Activity> _getActivitiesForView(AppState appState, ActivityView view) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (view) {
      case ActivityView.daily:
        final startDate = today;
        final endDate = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        return _getActivitiesForPeriod(appState, startDate, endDate);
        
      case ActivityView.weekly:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return _getActivitiesForPeriod(appState, startOfWeek, endOfWeek);
        
      case ActivityView.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return _getActivitiesForPeriod(appState, startOfMonth, endOfMonth);
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

  List<Activity> _filterActivities(List<Activity> activities) {
    if (_searchQuery.isEmpty) {
      return activities;
    }
    
    return activities.where((activity) {
      final customerName = activity.customerName.toLowerCase();
      final customerId = activity.customerId.toLowerCase();
      final searchQuery = _searchQuery.toLowerCase();
      
      return customerName.contains(searchQuery) || 
             customerId.contains(searchQuery) ||
             customerId == searchQuery; // Exact match for ID
    }).toList();
  }
} 