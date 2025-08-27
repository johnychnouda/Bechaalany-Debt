import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2,
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
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    title,
                    style: AppTheme.title2.copyWith(
                      color: AppColors.dynamicTextPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                                    const SizedBox(height: 8),
                                    // Revenue Summary Cards - Compact Design
                  Row(
                    children: [
                         // Total Revenue Card
                         Expanded(
                           child: Container(
                             padding: const EdgeInsets.all(10),
                             decoration: BoxDecoration(
                               color: AppColors.dynamicSuccess(context).withOpacity(0.1),
                               borderRadius: BorderRadius.circular(6),
                               border: Border.all(
                                 color: AppColors.dynamicSuccess(context).withOpacity(0.3),
                                 width: 1,
                               ),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   children: [
                                     Container(
                                       padding: const EdgeInsets.all(6),
                                       decoration: BoxDecoration(
                                         color: AppColors.dynamicSuccess(context).withOpacity(0.15),
                                         borderRadius: BorderRadius.circular(6),
                                       ),
                                       child: Icon(
                                         Icons.trending_up_rounded,
                                         color: AppColors.dynamicSuccess(context),
                                         size: 16,
                                       ),
                                     ),
                                     const SizedBox(width: 8),
                                     Expanded(
                                       child: Text(
                                         'Total Revenue: ${CurrencyFormatter.formatAmount(context, _calculateTotalRevenueForPeriod(appState, view))}',
                                         style: TextStyle(
                                           fontSize: 12,
                                           fontWeight: FontWeight.w600,
                                           color: AppColors.dynamicTextSecondary(context),
                                         ),
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                           ),
                         ),
                         const SizedBox(width: 12),
                         // Total Paid Card
                         Expanded(
                           child: Container(
                             padding: const EdgeInsets.all(10),
                             decoration: BoxDecoration(
                               color: AppColors.dynamicPrimary(context).withOpacity(0.1),
                               borderRadius: BorderRadius.circular(6),
                               border: Border.all(
                                 color: AppColors.dynamicPrimary(context).withOpacity(0.3),
                                 width: 1,
                               ),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   children: [
                                     Container(
                                       padding: const EdgeInsets.all(6),
                                       decoration: BoxDecoration(
                                         color: AppColors.dynamicPrimary(context).withOpacity(0.15),
                                         borderRadius: BorderRadius.circular(6),
                                       ),
                                       child: Icon(
                                         Icons.payment_rounded,
                                         color: AppColors.dynamicPrimary(context),
                                         size: 16,
                                       ),
                                     ),
                                     const SizedBox(width: 8),
                                     Expanded(
                                       child: Text(
                                         'Total Paid: ${CurrencyFormatter.formatAmount(context, _calculateTotalPaidForPeriod(appState, view))}',
                                         style: TextStyle(
                                           fontSize: 12,
                                           fontWeight: FontWeight.w600,
                                           color: AppColors.dynamicTextSecondary(context),
                                         ),
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                           ),
                         ),
                       ],
                     ),
                ],
              ),
            ),
            const SizedBox(height: 4),
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
            const SizedBox(height: 12),
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
    String statusText;

    switch (activity.type) {
      case ActivityType.payment:
        // Check if this is a full payment or partial payment
        if (activity.isPaymentCompleted) {
          icon = Icons.check_circle;
          iconColor = AppColors.success;
          backgroundColor = AppColors.success.withValues(alpha: 0.1);
          statusText = 'Fully Paid';
        } else {
          icon = Icons.payment;
          iconColor = AppColors.warning;
          backgroundColor = AppColors.warning.withValues(alpha: 0.1);
          statusText = 'Partial Payment';
        }
        break;
      case ActivityType.newDebt:
        // Check if this debt is still pending or has been paid
        if (activity.debtId != null) {
          // Try to find the current debt status
          final appState = Provider.of<AppState>(context, listen: false);
          final currentDebt = appState.debts.where(
            (debt) => debt.id == activity.debtId,
          ).firstOrNull;
          
          if (currentDebt != null && currentDebt.remainingAmount > 0) {
            // Debt is still pending - show clock icon to indicate waiting
            icon = Icons.schedule;
            iconColor = AppColors.error;
            backgroundColor = AppColors.error.withValues(alpha: 0.1);
            statusText = 'Outstanding Debt';
          } else {
            // Debt has been paid - show blue checkmark to distinguish from "Fully Paid"
            icon = Icons.check_circle;
            iconColor = AppColors.info;
            backgroundColor = AppColors.info.withValues(alpha: 0.1);
            statusText = 'Debt Paid';
          }
        } else {
          // Fallback to blue plus if no debt ID
          icon = Icons.add_shopping_cart;
          iconColor = AppColors.primary;
          backgroundColor = AppColors.primary.withValues(alpha: 0.1);
          statusText = 'New Debt';
        }
        break;
      case ActivityType.debtCleared:
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        statusText = 'Debt Cleared';
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        statusText = 'Activity';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (activity.type != ActivityType.payment || activity.isPaymentCompleted)
                  Text(
                    activity.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.type == ActivityType.payment && !activity.isPaymentCompleted
                    ? 'Partial Payment: ${CurrencyFormatter.formatAmount(context, activity.paymentAmount ?? 0)}'
                    : statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatActivityDate(activity.date),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    // Format time as HH:MM:SS AM/PM
    int hour = date.hour;
    String period = 'AM';
    
    if (hour >= 12) {
      period = 'PM';
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
        return 'Today\'s Activity';
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
        return 'No activity today\nAdd debts or make payments to see activity here';
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
        // Show only today's activities (from 00:00:00 to 23:59:59)
        final startDate = today;
        final endDate = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        return _getActivitiesForPeriod(appState, startDate, endDate);
        
      case ActivityView.weekly:
        // Show activities created this week (Monday to Sunday)
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return _getActivitiesForPeriod(appState, startOfWeek, endOfWeek);
        
      case ActivityView.monthly:
        // Show activities created this month
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return _getActivitiesForPeriod(appState, startOfMonth, endOfMonth);
        
      case ActivityView.yearly:
        // Show activities created this year
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
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
      
      // Always use date-only comparison for consistent behavior
      // This ensures activities are grouped by calendar date, not by time
      final activityDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
      final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
      
      isWithinPeriod = (activityDate.isAtSameMomentAs(startDateOnly) || activityDate.isAfter(startDateOnly)) && 
                      (activityDate.isAtSameMomentAs(endDateOnly) || activityDate.isBefore(endDateOnly));
      
      if (isWithinPeriod) {
        // Show all activities within the period - no additional filtering
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

  /// Calculate total revenue for a specific time period view using the same logic as main dashboard
  double _calculateTotalRevenueForPeriod(AppState appState, ActivityView view) {
    // Get the date range for the selected view
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime startDate;
    DateTime endDate;
    
    switch (view) {
      case ActivityView.daily:
        // Today only (not last 24 hours)
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0); // Start of today
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59); // End of today
        break;
      case ActivityView.weekly:
        // This week (Monday to Sunday) - inclusive
        // weekday returns 1=Monday, 2=Tuesday, ..., 7=Sunday
        // If today is Sunday (weekday=7), we want to go back 6 days to Monday
        // If today is Monday (weekday=1), we want to go back 0 days
        final daysFromMonday = today.weekday - 1;
        startDate = DateTime(today.year, today.month, today.day - daysFromMonday);
        endDate = DateTime(today.year, today.month, today.day, 23, 59, 59); // End of today
        break;
      case ActivityView.monthly:
        // This month - inclusive
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case ActivityView.yearly:
        // This year - inclusive
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
    }
    

    
    // Filter debts that were created or had payments within the selected period
    final relevantDebts = <String>{}; // Set to avoid duplicates
    
    // Add debts created within the period (inclusive of boundaries)
    for (final debt in appState.debts) {
      // Check if debt was created within the date range (inclusive)
      if (debt.createdAt.isAtSameMomentAs(startDate) || 
          debt.createdAt.isAtSameMomentAs(endDate) ||
          (debt.createdAt.isAfter(startDate) && debt.createdAt.isBefore(endDate))) {
        relevantDebts.add(debt.id);
      }
    }
    
    // Add debts that had payments within the period (inclusive of boundaries)
    for (final activity in appState.activities) {
      if (activity.type == ActivityType.payment) {
        // Check if payment activity was within the date range (inclusive)
        if ((activity.date.isAtSameMomentAs(startDate) || 
             activity.date.isAtSameMomentAs(endDate) ||
             (activity.date.isAfter(startDate) && activity.date.isBefore(endDate))) &&
            activity.debtId != null) {
          relevantDebts.add(activity.debtId!);
        }
      }
    }
    
    // Calculate revenue using the same logic as main dashboard
    double totalRevenue = 0.0;
    
    for (final debtId in relevantDebts) {
      final associatedDebts = appState.debts.where((d) => d.id == debtId).toList();
      if (associatedDebts.isEmpty) continue;
      
      final debt = associatedDebts.first;
      
      if (debt.originalCostPrice != null && debt.originalSellingPrice != null) {
        final debtRevenue = debt.originalSellingPrice! - debt.originalCostPrice!;
        
        // Check if customer is fully paid (same logic as main dashboard)
        final isCustomerFullyPaid = appState.isCustomerFullyPaid(debt.customerId);
        final isCustomerPartiallyPaid = appState.isCustomerPartiallyPaid(debt.customerId);
        
        if (isCustomerFullyPaid) {
          // Customer has settled ALL debts - recognize full revenue for this debt
          totalRevenue += debtRevenue;
        } else if (isCustomerPartiallyPaid && debt.paidAmount > 0) {
          // Customer has made some payments but not settled all debts - recognize proportional revenue
          totalRevenue += debt.earnedRevenue;
        }
        // If customer is pending (no payments), no revenue is recognized
      }
    }
    
    // Revenue calculation is already in USD (same as debt amounts)
    // No currency conversion needed - return the calculated revenue directly
    return totalRevenue;
  }

  /// Calculate total payments made by customers for a specific time period view
  double _calculateTotalPaidForPeriod(AppState appState, ActivityView view) {
    // Get the date range for the selected view
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime startDate;
    DateTime endDate;
    
    switch (view) {
      case ActivityView.daily:
        // Today only (not last 24 hours)
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0); // Start of today
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59); // End of today
        break;
      case ActivityView.weekly:
        // This week (Monday to Sunday) - inclusive
        // weekday returns 1=Monday, 2=Tuesday, ..., 7=Sunday
        // If today is Sunday (weekday=7), we want to go back 6 days to Monday
        // If today is Monday (weekday=1), we want to go back 0 days
        final daysFromMonday = today.weekday - 1;
        startDate = DateTime(today.year, today.month, today.day - daysFromMonday);
        endDate = DateTime(today.year, today.month, today.day, 23, 59, 59); // End of today
        break;
      case ActivityView.monthly:
        // This month - inclusive
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case ActivityView.yearly:
        // This year - inclusive
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
    }
    
    // Calculate total payments made within the selected period
    double totalPaid = 0.0;
    
    // Sum all payment activities within the date range
    for (final activity in appState.activities) {
      if (activity.type == ActivityType.payment && activity.paymentAmount != null) {
        // Check if payment activity was within the date range (inclusive)
        if ((activity.date.isAtSameMomentAs(startDate) || 
             activity.date.isAtSameMomentAs(endDate) ||
             (activity.date.isAfter(startDate) && activity.date.isBefore(endDate)))) {
          totalPaid += activity.paymentAmount!;
        }
      }
    }
    
    // Payment amounts are already in USD (same as debt amounts)
    // No currency conversion needed - return the calculated total directly
    return totalPaid;
  }

  /// Get a user-friendly label for the current time period
  String _getPeriodLabel(ActivityView view) {
    switch (view) {
      case ActivityView.daily:
        return 'TODAY';
      case ActivityView.weekly:
        return 'WEEK';
      case ActivityView.monthly:
        return 'MONTH';
      case ActivityView.yearly:
        return 'YEAR';
    }
  }



} 