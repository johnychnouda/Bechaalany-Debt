import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as fw;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../models/activity.dart';
import '../utils/currency_formatter.dart';
import '../services/receipt_sharing_service.dart';
import '../widgets/pdf_viewer_popup.dart';

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
  static const String _arabicIndicNumerals = '٠١٢٣٤٥٦٧٨٩';

  static String _toArabicNumerals(String s) {
    return s.replaceAllMapped(
        RegExp(r'\d'), (m) => _arabicIndicNumerals[int.parse(m.group(0)!)]);
  }

  static String _formatNumbersForLocale(BuildContext context, String s) {
    if (Localizations.localeOf(context).languageCode == 'ar') {
      return _toArabicNumerals(s);
    }
    return s;
  }

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
          AppLocalizations.of(context)!.activityHistory,
          style: AppTheme.title3.copyWith(
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        actions: [
          // Show PDF button only when monthly filter is selected
          if (_currentView == ActivityView.monthly)
            Consumer<AppState>(
              builder: (context, appState, child) {
                return IconButton(
                  icon: const Icon(Icons.assessment, size: 32),
                  onPressed: () => _generateMonthlyPDF(context, appState),
                  tooltip: AppLocalizations.of(context)!.generateMonthlyReport,
                  iconSize: 32,
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.daily),
            Tab(text: AppLocalizations.of(context)!.weekly),
            Tab(text: AppLocalizations.of(context)!.monthly),
            Tab(text: AppLocalizations.of(context)!.yearly),
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
        final title = _getViewTitle(context, view);
        final emptyMessage = _searchQuery.isNotEmpty
            ? AppLocalizations.of(context)!.noActivitiesFoundForQuery(_searchQuery)
            : _getEmptyMessage(context, view);


        // Get period-specific financial data from AppState
        final periodData = appState.getPeriodFinancialData(_getPeriodString(view));

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
                  // Revenue Summary Cards - Using AppState data
                  Row(
                    children: [
                      // Total Revenue Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicSuccess(context).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.dynamicSuccess(context).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.dynamicSuccess(context).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.trending_up_rounded,
                                      color: AppColors.dynamicSuccess(context),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)!.totalRevenue,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dynamicTextSecondary(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Center(
                                child: fw.Directionality(
                                  textDirection: fw.TextDirection.ltr,
                                  child: Text(
                                    CurrencyFormatter.formatAmount(context, periodData['totalRevenue'] ?? 0.0),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dynamicTextPrimary(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Total Paid Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.dynamicPrimary(context).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.dynamicPrimary(context).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.payment_rounded,
                                      color: AppColors.dynamicPrimary(context),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)!.totalPaid,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dynamicTextSecondary(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Center(
                                child: fw.Directionality(
                                  textDirection: fw.TextDirection.ltr,
                                  child: Text(
                                    CurrencyFormatter.formatAmount(context, periodData['totalPaid'] ?? 0.0),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dynamicTextPrimary(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                  hintText: AppLocalizations.of(context)!.searchByNameOrId,
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
                        return _buildActivityItem(context, filteredActivities[index], appState);
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

  Widget _buildStatusRow(
    BuildContext context,
    Activity activity,
    AppLocalizations l10n,
    String statusText,
    Color iconColor,
  ) {
    final style = TextStyle(
      fontSize: 10,
      color: iconColor,
      fontWeight: FontWeight.w600,
    );
    final isPartial = activity.type == ActivityType.payment && !activity.isPaymentCompleted;
    final isFullyPaidWithAmount = activity.type == ActivityType.payment &&
        activity.isPaymentCompleted &&
        activity.description.startsWith('Fully paid:');
    if (isPartial || isFullyPaidWithAmount) {
      final label = isPartial ? l10n.partialPayment : l10n.fullyPaid;
      final amountStr = CurrencyFormatter.formatAmount(context, activity.paymentAmount ?? 0);
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          fw.Directionality(
            textDirection: fw.TextDirection.ltr,
            child: Text(amountStr, style: style),
          ),
          Text(' $label', style: style),
        ],
      );
    }
    return Text(statusText, style: style);
  }

  /// Normalize description so dollar sign shows on the right (e.g. "$20.00 x" → "20.00$ x")
  static String _descriptionWithDollarOnRight(String description) {
    return description.replaceAllMapped(
      RegExp(r'\$(\d+(?:\.\d+)?)'),
      (m) => '${m.group(1)}\$',
    );
  }

  Widget _buildActivityItem(BuildContext context, Activity activity, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    IconData icon;
    Color iconColor;
    Color backgroundColor;
    String statusText;

    switch (activity.type) {
      case ActivityType.payment:
        // Check if this is a full payment or partial payment
        if (activity.isPaymentCompleted) {
          // Check if this is a customer-level "Fully paid" activity or individual debt payment
          if (activity.description.startsWith('Fully paid:')) {
            icon = Icons.check_circle;
            iconColor = AppColors.success;
            backgroundColor = AppColors.success.withValues(alpha: 0.1);
            statusText = l10n.fullyPaid;
          } else {
            // Individual debt payment
            icon = Icons.check_circle;
            iconColor = AppColors.primary;
            backgroundColor = AppColors.primary.withValues(alpha: 0.1);
            statusText = l10n.debtPaid;
          }
        } else {
          icon = Icons.payment;
          iconColor = AppColors.warning;
          backgroundColor = AppColors.warning.withValues(alpha: 0.1);
          statusText = l10n.partialPayment;
        }
        break;
      case ActivityType.newDebt:
        // Check the specific debt's payment status
        if (activity.debtId != null) {
          final currentDebt = appState.debts.where(
            (debt) => debt.id == activity.debtId,
          ).firstOrNull;
          
          if (currentDebt != null) {
            
            // Check the specific debt's payment status
            if (currentDebt.paidAmount >= currentDebt.amount) {
              // This specific debt is fully paid - show blue checkmark
              icon = Icons.check_circle;
              iconColor = AppColors.primary;
              backgroundColor = AppColors.primary.withValues(alpha: 0.1);
              statusText = l10n.debtPaid;
            } else if (currentDebt.paidAmount > 0.1) {
              // This specific debt has partial payments - show red for outstanding debt
              icon = Icons.payment;
              iconColor = AppColors.error;
              backgroundColor = AppColors.error.withValues(alpha: 0.1);
              statusText = l10n.outstandingDebt;
            } else {
              // This specific debt has no payments - show blue plus
              icon = Icons.add_circle;
              iconColor = AppColors.primary;
              backgroundColor = AppColors.primary.withValues(alpha: 0.1);
              statusText = l10n.newDebt;
            }
          } else {
            // Debt not found - show as "New Debt" with blue plus
            icon = Icons.add_circle;
            iconColor = AppColors.primary;
            backgroundColor = AppColors.primary.withValues(alpha: 0.1);
            statusText = l10n.newDebt;
          }
        } else {
          // No debt ID - show as "New Debt" with blue plus
          icon = Icons.add_circle;
          iconColor = AppColors.primary;
          backgroundColor = AppColors.primary.withValues(alpha: 0.1);
          statusText = l10n.newDebt;
        }
        break;
      case ActivityType.debtCleared:
        icon = Icons.check_circle;
        iconColor = AppColors.primary;
        backgroundColor = AppColors.primary.withValues(alpha: 0.1);
        statusText = l10n.debtPaid;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        statusText = l10n.activity;
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
                if (activity.type != ActivityType.payment || (activity.isPaymentCompleted && !activity.description.startsWith('Fully paid:')))
                  fw.Directionality(
                    textDirection: fw.TextDirection.ltr,
                    child: Text(
                      _descriptionWithDollarOnRight(activity.description),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusRow(
                context,
                activity,
                l10n,
                statusText,
                iconColor,
              ),
              Text(
                _formatActivityDate(context, activity.date),
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

  String _localeString(BuildContext context) {
    return Localizations.localeOf(context).toString().split('_').first;
  }

  String _formatActivityDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);
    final l10n = AppLocalizations.of(context)!;
    final timeStr = _formatNumbersForLocale(context, _formatTime12Hour(context, date));

    switch (_currentView) {
      case ActivityView.daily:
        if (activityDate == today) {
          return l10n.todayAtTime(timeStr);
        } else if (activityDate == yesterday) {
          return l10n.yesterdayAtTime(timeStr);
        } else {
          return l10n.dateAtTime(_formatNumbersForLocale(context, _formatDate(context, date)), timeStr);
        }
      case ActivityView.weekly:
      case ActivityView.monthly:
      case ActivityView.yearly:
        return l10n.dateAtTime(_formatNumbersForLocale(context, _formatDayDate(context, date)), timeStr);
    }
  }

  String _formatTime12Hour(BuildContext context, DateTime date) {
    final locale = _localeString(context);
    return DateFormat.jm(locale).format(date);
  }

  String _formatDayDate(BuildContext context, DateTime date) {
    final locale = _localeString(context);
    return DateFormat('EEE MMM d', locale).format(date);
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = _localeString(context);
    return DateFormat.MMMd(locale).format(date);
  }

  String _getViewTitle(BuildContext context, ActivityView view) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final l10n = AppLocalizations.of(context)!;
    switch (view) {
      case ActivityView.daily:
        return l10n.todaysActivity;
      case ActivityView.weekly:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return l10n.weeklyActivityRange(
          _formatNumbersForLocale(context, _formatShortDate(context, startOfWeek)),
          _formatNumbersForLocale(context, _formatShortDate(context, endOfWeek)),
        );
      case ActivityView.monthly:
        return l10n.monthlyActivityMonth(_formatNumbersForLocale(context, _getMonthYear(context, now)));
      case ActivityView.yearly:
        return l10n.yearlyActivityYear(_formatNumbersForLocale(context, now.year.toString()));
    }
  }

  String _formatShortDate(BuildContext context, DateTime date) {
    final locale = _localeString(context);
    return DateFormat.MMMd(locale).format(date);
  }

  String _getMonthYear(BuildContext context, DateTime date) {
    final locale = _localeString(context);
    return DateFormat.yMMMM(locale).format(date);
  }

  String _getEmptyMessage(BuildContext context, ActivityView view) {
    final l10n = AppLocalizations.of(context)!;
    switch (view) {
      case ActivityView.daily:
        return l10n.noActivityToday;
      case ActivityView.weekly:
        return l10n.noActivityThisWeek;
      case ActivityView.monthly:
        return l10n.noActivityThisMonth;
      case ActivityView.yearly:
        return l10n.noActivityThisYear;
    }
  }

  String _getPeriodString(ActivityView view) {
    switch (view) {
      case ActivityView.daily:
        return 'daily';
      case ActivityView.weekly:
        return 'weekly';
      case ActivityView.monthly:
        return 'monthly';
      case ActivityView.yearly:
        return 'yearly';
    }
  }

  List<Activity> _getActivitiesForView(AppState appState, ActivityView view) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<Activity> activities;
    
    
    switch (view) {
      case ActivityView.daily:
        // Show only today's activities (from 00:00:00 to 23:59:59)
        final startDate = today; // Start of today (00:00:00)
        final endDate = today.add(const Duration(days: 1)); // Start of tomorrow (00:00:00)
        activities = _getActivitiesForPeriod(appState, startDate, endDate);
        break;
        
      case ActivityView.weekly:
        // Show activities created this week (Monday to Sunday)
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        activities = _getActivitiesForPeriod(appState, startOfWeek, endOfWeek);
        break;
        
      case ActivityView.monthly:
        // Show activities created this month
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        activities = _getActivitiesForPeriod(appState, startOfMonth, endOfMonth);
        break;
        
      case ActivityView.yearly:
        // Show activities created this year
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year + 1, 1, 1).subtract(const Duration(milliseconds: 1));
        activities = _getActivitiesForPeriod(appState, startOfYear, endOfYear);
        break;
    }
    
    // FALLBACK: If no activities found for the specific period, show all activities
    // This ensures activities are visible even if there are date filtering issues
    // EXCEPT for daily view - it should only show today's activities
    if (activities.isEmpty && appState.activities.isNotEmpty && view != ActivityView.daily) {
      activities = List.from(appState.activities);
      activities.sort((a, b) => b.date.compareTo(a.date));
    }
    
    return activities;
  }

  List<Activity> _getActivitiesForPeriod(AppState appState, DateTime startDate, DateTime endDate) {
    final activities = <Activity>[];
    
    // Get activities without duplicates (without modifying state)
    final activitiesWithoutDuplicates = _removeDuplicatesFromList(appState.activities);
    
    // Use exact date ranges without buffers for precise filtering
    final bufferedStartDate = startDate;
    final bufferedEndDate = endDate;
    
    
    // Get activities from the new Activity model
    for (final activity in activitiesWithoutDuplicates) {
      
      // IMPROVED: More robust date comparison with buffer
      final activityTimestamp = activity.date.millisecondsSinceEpoch;
      final startTimestamp = bufferedStartDate.millisecondsSinceEpoch;
      final endTimestamp = bufferedEndDate.millisecondsSinceEpoch;
      
      // Enhanced inclusive comparison - start inclusive, end inclusive
      final isWithinPeriod = activityTimestamp >= startTimestamp && activityTimestamp <= endTimestamp;
      
      
      if (isWithinPeriod) {
        // Show all activities within the period - no additional filtering
        activities.add(activity);
      }
    }
    
    // Activities are now filtered strictly by the specified period without additional buffers

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

  /// Generate monthly activity PDF report
  Future<void> _generateMonthlyPDF(BuildContext context, AppState appState) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Get monthly activities and data
      final now = DateTime.now();
      final monthlyActivities = _getActivitiesForView(appState, ActivityView.monthly);
      final monthlyDebts = appState.debts.where((debt) {
        final debtDate = DateTime(debt.createdAt.year, debt.createdAt.month, debt.createdAt.day);
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return debtDate.isAtSameMomentAs(startOfMonth) || 
               debtDate.isAtSameMomentAs(endOfMonth) ||
               (debtDate.isAfter(startOfMonth) && debtDate.isBefore(endOfMonth));
      }).toList();

      // Get monthly financial data
      final monthlyData = appState.getPeriodFinancialData('monthly');
      final totalRevenue = monthlyData['totalRevenue'] ?? 0.0;
      final totalPaid = monthlyData['totalPaid'] ?? 0.0;

      // Generate PDF (pass l10n so report is in app language, e.g. Arabic)
      final l10n = AppLocalizations.of(context);
      final pdfFile = await ReceiptSharingService.generateMonthlyActivityPDF(
        monthlyActivities: monthlyActivities,
        monthlyDebts: monthlyDebts,
        totalRevenue: totalRevenue,
        totalPaid: totalPaid,
        monthDate: now,
        l10n: l10n,
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      if (pdfFile != null) {
        // Open PDF directly in the app
        final reportTitle = l10n?.monthlyActivityReport ?? 'Monthly Activity Report';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PDFViewerPopup(
              pdfFile: pdfFile,
              customerName: reportTitle,
            ),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate monthly report. Please try again.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if it's still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

} 