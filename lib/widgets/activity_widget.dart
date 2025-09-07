import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../providers/app_state.dart';
import 'package:provider/provider.dart';
import '../screens/full_activity_list_screen.dart';
import 'package:flutter/cupertino.dart';

class ActivityWidget extends StatefulWidget {
  final List<Activity> activities;
  
  const ActivityWidget({
    super.key,
    required this.activities,
  });

  @override
  State<ActivityWidget> createState() => _ActivityWidgetState();
}

class _ActivityWidgetState extends State<ActivityWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Text(
                        'Last 24 Hours Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Button to open full activity history page
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
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.list_alt_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Show only daily activities
                _buildDailyActivities(appState),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyActivities(AppState appState) {
    final activities = _getDailyActivities(appState);
    
    if (activities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'No activity for today',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
        ...topActivities.map((activity) => _buildActivityItem(activity, appState)),
      ],
    );
  }

  List<Activity> _getDailyActivities(AppState appState) {
    final activities = <Activity>[];
    final now = DateTime.now();
    
    // Show activities from the last 24 hours
    final startDate = now.subtract(const Duration(hours: 24));
    final endDate = now;

    // Get activities without duplicates (without modifying state)
    final activitiesWithoutDuplicates = _removeDuplicatesFromList(appState.activities);

    for (final activity in activitiesWithoutDuplicates) {
      
      // Check if activity date is within the last 24 hours
      if (activity.date.isAfter(startDate) && activity.date.isBefore(endDate)) {
        activities.add(activity);
      }
    }

    // Sort by date (newest first)
    activities.sort((a, b) => b.date.compareTo(a.date));
    return activities;
  }

  Widget _buildActivityItem(Activity activity, AppState appState) {
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
            iconColor = Colors.green;
            backgroundColor = Colors.green.withValues(alpha: 0.1);
            statusText = 'Fully Paid';
          } else {
            // Individual debt payment
            icon = Icons.check_circle;
            iconColor = Colors.blue;
            backgroundColor = Colors.blue.withValues(alpha: 0.1);
            statusText = 'Debt Paid';
          }
        } else {
          icon = Icons.payment;
          iconColor = Colors.orange;
          backgroundColor = Colors.orange.withValues(alpha: 0.1);
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
            
            if (currentDebt != null) {
              // Check if this specific debt is paid or outstanding
              if (currentDebt.isFullyPaid) {
                // This specific debt is fully paid
                icon = Icons.check_circle;
                iconColor = Colors.green;
                backgroundColor = Colors.green.withValues(alpha: 0.1);
                statusText = 'Debt Paid';
              } else {
                // This specific debt is outstanding (not fully paid)
                icon = Icons.schedule;
                iconColor = Colors.red;
                backgroundColor = Colors.red.withValues(alpha: 0.1);
                statusText = 'Outstanding Debt';
              }
            } else {
              // Debt not found - show as outstanding
              icon = Icons.schedule;
              iconColor = Colors.red;
              backgroundColor = Colors.red.withValues(alpha: 0.1);
              statusText = 'Outstanding Debt';
            }
          } else {
            // Fallback to blue plus if no debt ID
            icon = Icons.add_shopping_cart;
            iconColor = Colors.blue;
            backgroundColor = Colors.blue.withValues(alpha: 0.1);
            statusText = 'New Debt';
          }
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
                Text(
                  _getActivityDescription(activity, appState),
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
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatTime(activity.date),
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

  String _getActivityDescription(Activity activity, AppState appState) {
    // For fully paid activities, show only the payment amount instead of product name
    if (activity.type == ActivityType.payment && 
        activity.isPaymentCompleted && 
        appState.isCustomerFullyPaid(activity.customerId)) {
      return '${activity.paymentAmount?.toStringAsFixed(2)}\$';
    }
    
    // For all other activities, show the original description
    return activity.description;
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