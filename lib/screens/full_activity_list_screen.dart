import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../models/activity.dart';
import '../utils/currency_formatter.dart';
import '../utils/debt_description_utils.dart';

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
    // Sample data generation removed
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
    IconData icon;
    Color iconColor;
    Color backgroundColor;

    // Determine if this is a full payment
    bool isFullPayment = activity.type == ActivityType.payment && 
                        activity.paymentAmount != null && 
                        activity.paymentAmount == activity.amount;

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
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
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  // Only show product description for new debts, not for payments
                  if (activity.type == ActivityType.newDebt)
                    Text(
                      DebtDescriptionUtils.cleanDescription(activity.description),
                      style: AppTheme.caption1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatActivityDate(activity.date),
                          style: AppTheme.caption1.copyWith(
                            color: AppColors.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (activity.type == ActivityType.newDebt)
                        Flexible(
                          child: Text(
                            CurrencyFormatter.formatAmount(context, activity.amount),
                            style: AppTheme.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      if (activity.type == ActivityType.payment && activity.paymentAmount != null)
                        Flexible(
                          child: Text(
                            isFullPayment
                                ? 'Fully Paid: ${CurrencyFormatter.formatAmount(context, activity.paymentAmount!)}'
                                : 'Partial: ${CurrencyFormatter.formatAmount(context, activity.paymentAmount!)}',
                            style: AppTheme.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isFullPayment ? AppColors.success : AppColors.warning,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
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
      // Filter out debtCleared activities - only show new debts and payments
      if (activity.type == ActivityType.debtCleared) {
        continue; // Skip cleared activities
      }
      
      // Filter out activities for customers that no longer exist
      final customerExists = appState.customers.any((customer) => 
        customer.name.toLowerCase() == activity.customerName.toLowerCase()
      );
      
      if (!customerExists) {
        continue;
      }
      
      // Add only activities for existing customers
      activities.add(activity);
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