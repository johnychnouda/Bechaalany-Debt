import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/app_update_service.dart';
import '../constants/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AppUpdateService _appUpdateService = AppUpdateService();
  

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkDeviceCapabilities();
  }

  Future<void> _loadSettings() async {
    final settings = await _notificationService.loadNotificationSettings();
  }

  Future<void> _checkDeviceCapabilities() async {
  }

  Future<void> _saveSettings() async {
    await _notificationService.updateNotificationSettings(
      dailySummaryEnabled: true, // Enabled
      weeklyReportEnabled: true, // Enabled
      monthlyReportEnabled: true, // Enabled
      yearlyReportEnabled: true, // Enabled
      dailySummaryTime: const TimeOfDay(hour: 23, minute: 59),
      weeklyReportWeekday: DateTime.sunday,
      weeklyReportTime: const TimeOfDay(hour: 23, minute: 59),
      monthlyReportDay: 31,
      monthlyReportTime: const TimeOfDay(hour: 23, minute: 59),
      yearlyReportMonth: 12,
      yearlyReportDay: 31,
      yearlyReportTime: const TimeOfDay(hour: 23, minute: 59),
    );
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Notification Types
            _buildSectionTitle('Notification Types'),
            _buildNotificationTypeCard(
              title: 'Immediate Action Notifications',
              subtitle: 'Notifications for customer and debt actions',
              icon: Icons.person_add,
              color: Colors.blue,
              notifications: [
                'Customer Added/Updated/Deleted',
                'Debt Added',
                'Payment Applied',
                'Payment Successful',
                'Category Added/Updated/Deleted',
              ],
            ),
            const SizedBox(height: 12),
            _buildNotificationTypeCard(
              title: 'System Notifications',
              subtitle: 'Notifications for app system events',
              icon: Icons.settings,
              color: Colors.green,
              notifications: [
                'App Updates',
                'System Maintenance',
                'Backup Success',
                'Auto-Backup',
              ],
            ),
            const SizedBox(height: 12),
            _buildNotificationTypeCard(
              title: 'Business Intelligence',
              subtitle: 'Notifications for business insights and automation',
              icon: Icons.analytics,
              color: Colors.purple,
              notifications: [
                'Auto-Reminder Sent',
                'App Update Available',
              ],
            ),
            const SizedBox(height: 12),
            _buildNotificationTypeCard(
              title: 'Report Notifications',
              subtitle: 'Automated business reports and summaries',
              icon: Icons.assessment,
              color: Colors.orange,
              notifications: [
                'Daily Summary (11:59 PM)',
                'Weekly Report (Sunday 11:59 PM)',
                'Monthly Report (Last day 11:59 PM)',
                'Yearly Report (Dec 31st 11:59 PM)',
              ],
            ),
            
            const SizedBox(height: 20),
            
            
            const SizedBox(height: 20),
            
            // Test Notifications
            _buildSectionTitle('Test New Notifications'),
            _buildTestNotificationButtons(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }


  Widget _buildNotificationTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> notifications,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...notifications.map((notification) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.textPrimary : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? AppColors.textSecondary : Colors.grey,
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTestNotificationButtons() {
    return Column(
      children: [
        // Permission Test
        _buildTestButton(
          title: 'Request Notification Permissions',
          onPressed: () async {
            await _notificationService.reRequestPermissions();
          },
        ),
        const SizedBox(height: 8),
        
        
        // Customer Management Notifications
        _buildSectionTitle('Customer Management'),
        _buildTestButton(
          title: 'Test Customer Added',
          onPressed: () async {
            await _notificationService.showCustomerAddedNotification('John Smith');
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Customer Updated',
          onPressed: () async {
            await _notificationService.showCustomerUpdatedNotification('Jane Doe');
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Customer Deleted',
          onPressed: () async {
            await _notificationService.showCustomerDeletedNotification('Bob Johnson');
          },
        ),
        const SizedBox(height: 16),
        
        // Category Management Notifications
        _buildSectionTitle('Category Management'),
        _buildTestButton(
          title: 'Test Category Added',
          onPressed: () async {
            await _notificationService.showCategoryAddedNotification('Electronics');
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Category Updated',
          onPressed: () async {
            await _notificationService.showCategoryUpdatedNotification('Electronics');
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Category Deleted',
          onPressed: () async {
            await _notificationService.showCategoryDeletedNotification('Electronics');
          },
        ),
        const SizedBox(height: 16),
        
        // Debt Management Notifications
        _buildSectionTitle('Debt Management'),
        _buildTestButton(
          title: 'Test Debt Recorded',
          onPressed: () async {
            await _notificationService.showDebtAddedNotification('Alice Brown', 1250.50);
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Payment Applied',
          onPressed: () async {
            await _notificationService.showPaymentAppliedNotification('Charlie Wilson', 350.75);
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Payment Successful',
          onPressed: () async {
            await _notificationService.showPaymentSuccessfulNotification('David Lee');
          },
        ),
        const SizedBox(height: 16),
        
        // Backup Notifications
        _buildSectionTitle('Backup & Data'),
        _buildTestButton(
          title: 'Test Backup Created',
          onPressed: () async {
            await _notificationService.showBackupCreatedNotification();
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Backup Restored',
          onPressed: () async {
            await _notificationService.showBackupRestoredNotification();
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Backup Failed',
          onPressed: () async {
            await _notificationService.showBackupFailedNotification('Network connection error');
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Daily Backup Success',
          onPressed: () async {
            await _notificationService.showDailyBackupSuccessNotification();
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Auto-Backup',
          onPressed: () async {
            await _notificationService.showAutoBackupNotification('12:00 AM');
          },
        ),
        const SizedBox(height: 16),
        
        // Business Intelligence Notifications
        _buildSectionTitle('Business Intelligence'),
        _buildTestButton(
          title: 'Test Auto-Reminder Sent',
          onPressed: () async {
            await _notificationService.showAutoReminderSentNotification(5);
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test App Update Available',
          onPressed: () async {
            await _notificationService.showAppUpdateAvailableNotification('2.1.0');
          },
        ),
        const SizedBox(height: 16),
        
        // Report Notifications
        _buildSectionTitle('Report Notifications'),
        _buildTestButton(
          title: 'Test Daily Summary',
          onPressed: () async {
            await _notificationService.showDailySummaryNotification(
              totalPaid: 350.75,
              totalRevenue: 1250.50,
            );
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Weekly Report',
          onPressed: () async {
            await _notificationService.showWeeklyReportNotification(
              totalPaid: 850.25,
              totalRevenue: 2100.00,
            );
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Monthly Report',
          onPressed: () async {
            await _notificationService.showMonthlyReportNotification(
              totalPaid: 2100.00,
              totalRevenue: 8500.00,
            );
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test Yearly Report',
          onPressed: () async {
            await _notificationService.showYearlyReportNotification(
              totalPaid: 12500.00,
              totalRevenue: 45000.00,
            );
          },
        ),
        const SizedBox(height: 16),
        
        // System Notifications
        _buildSectionTitle('System Notifications'),
        _buildTestButton(
          title: 'Test App Update',
          onPressed: () async {
            await _notificationService.showAppUpdateNotification('2.1.0');
          },
        ),
        const SizedBox(height: 8),
        _buildTestButton(
          title: 'Test System Maintenance',
          onPressed: () async {
            await _notificationService.showSystemMaintenanceNotification('Scheduled maintenance in 30 minutes');
          },
        ),
        const SizedBox(height: 16),
        
        
        // Test All Notifications
        _buildSectionTitle('Bulk Testing'),
        _buildTestButton(
          title: 'Test All Notifications (5 second intervals)',
          onPressed: () async {
            await _testAllNotifications();
          },
        ),
      ],
    );
  }

  Widget _buildTestButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(title),
      ),
    );
  }

  // Test all notifications with 5-second intervals
  Future<void> _testAllNotifications() async {
    // Customer management
    await _notificationService.showCustomerAddedNotification('John Smith');
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showCustomerUpdatedNotification('Jane Doe');
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showCustomerDeletedNotification('Bob Johnson');
    await Future.delayed(const Duration(seconds: 5));

    // Category management
    await _notificationService.showCategoryAddedNotification('Electronics');
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showCategoryUpdatedNotification('Electronics');
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showCategoryDeletedNotification('Electronics');
    await Future.delayed(const Duration(seconds: 5));

    // Debt management
    await _notificationService.showDebtAddedNotification('Alice Brown', 1250.50);
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showPaymentAppliedNotification('Charlie Wilson', 350.75);
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showPaymentSuccessfulNotification('David Lee');
    await Future.delayed(const Duration(seconds: 5));

    // Backup notifications
    await _notificationService.showBackupCreatedNotification();
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showBackupRestoredNotification();
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showBackupFailedNotification('Network connection error');
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showDailyBackupSuccessNotification();
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showAutoBackupNotification('12:00 AM');
    await Future.delayed(const Duration(seconds: 5));

    // Business intelligence
    await _notificationService.showAutoReminderSentNotification(5);
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showAppUpdateAvailableNotification('2.1.0');
    await Future.delayed(const Duration(seconds: 5));

    // System notifications
    await _notificationService.showAppUpdateNotification('2.1.0');
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showSystemMaintenanceNotification('Scheduled maintenance in 30 minutes');
    await Future.delayed(const Duration(seconds: 5));

    // Report notifications
    await _notificationService.showDailySummaryNotification(
      totalPaid: 350.75,
      totalRevenue: 1250.50,
    );
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showWeeklyReportNotification(
      totalPaid: 850.25,
      totalRevenue: 2100.00,
    );
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showMonthlyReportNotification(
      totalPaid: 2100.00,
      totalRevenue: 8500.00,
    );
    await Future.delayed(const Duration(seconds: 5));

    await _notificationService.showYearlyReportNotification(
      totalPaid: 12500.00,
      totalRevenue: 45000.00,
    );
    await Future.delayed(const Duration(seconds: 5));

  }

} 