import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/ios18_service.dart';
import '../constants/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  // iOS 18.6+ notification settings
  String _interruptionLevel = 'active';
  
  // iOS 18.6+ advanced features
  bool _focusModeIntegration = true;
  bool _dynamicIslandEnabled = true;
  bool _liveActivitiesEnabled = true;
  bool _smartStackEnabled = true;
  bool _aiFeaturesEnabled = true;
  
  // Device capabilities
  Map<String, bool> _deviceCapabilities = {};
  bool _isIOS186Supported = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkDeviceCapabilities();
  }

  Future<void> _loadSettings() async {
    final settings = await _notificationService.loadNotificationSettings();
    
    setState(() {
      _interruptionLevel = settings['interruptionLevel'] ?? 'active';
    });
  }

  Future<void> _checkDeviceCapabilities() async {
    final isSupported = await IOS18Service.isIOS186Supported();
    final capabilities = await IOS18Service.getDeviceCapabilities();
    
    setState(() {
      _isIOS186Supported = isSupported;
      _deviceCapabilities = capabilities;
    });
  }

  Future<void> _saveSettings() async {
    await _notificationService.updateNotificationSettings(
      paymentRemindersEnabled: false, // Disabled
      dailySummaryEnabled: false, // Disabled
      weeklyReportEnabled: false, // Disabled
      dailySummaryTime: const TimeOfDay(hour: 9, minute: 0), // Not used
      weeklyReportWeekday: DateTime.monday, // Not used
      weeklyReportTime: const TimeOfDay(hour: 10, minute: 0), // Not used
      interruptionLevel: _interruptionLevel,
    );
    
    // Update iOS 18.6+ advanced features
    if (_focusModeIntegration) {
      await IOS18Service.enableFocusModeIntegration();
    }
    if (_dynamicIslandEnabled) {
      await IOS18Service.enableDynamicIslandIntegration();
    }
    if (_liveActivitiesEnabled) {
      await IOS18Service.enableLiveActivities();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
            // iOS 18.6+ Status
            if (_isIOS186Supported) ...[
              _buildIOS186StatusCard(),
              const SizedBox(height: 20),
            ],
            
            // Notification Types
            _buildSectionTitle('Notification Types'),
            _buildNotificationTypeCard(
              title: 'Immediate Action Notifications',
              subtitle: 'Notifications for customer and debt actions',
              icon: Icons.person_add,
              color: Colors.blue,
              notifications: [
                'Customer Added/Updated/Deleted',
                'Debt Added/Updated/Paid/Deleted',
                'Payment Applied',
                'Category Added/Updated/Deleted',
                'Product Added/Updated/Deleted',
              ],
            ),
            const SizedBox(height: 12),
            _buildNotificationTypeCard(
              title: 'System Notifications',
              subtitle: 'Notifications for app system events',
              icon: Icons.settings,
              color: Colors.green,
              notifications: [

                'Cache Cleared',
                'Sync Complete/Failed',
                'App Updates',
                'System Maintenance',
              ],
            ),
            
            const SizedBox(height: 20),
            
            // iOS 18.6+ Advanced Features
            if (_isIOS186Supported) ...[
              _buildSectionTitle('iOS 18.6+ Advanced Features'),
              _buildSwitchTile(
                title: 'Focus Mode Integration',
                subtitle: 'Smart notifications based on your Focus mode',
                value: _focusModeIntegration,
                onChanged: (value) => setState(() => _focusModeIntegration = value),
                enabled: _deviceCapabilities['focusMode'] ?? false,
              ),
              _buildSwitchTile(
                title: 'Dynamic Island',
                subtitle: 'Show debt information in Dynamic Island',
                value: _dynamicIslandEnabled,
                onChanged: (value) => setState(() => _dynamicIslandEnabled = value),
                enabled: _deviceCapabilities['dynamicIsland'] ?? false,
              ),
              _buildSwitchTile(
                title: 'Live Activities',
                subtitle: 'Track debt payments with Live Activities',
                value: _liveActivitiesEnabled,
                onChanged: (value) => setState(() => _liveActivitiesEnabled = value),
                enabled: _deviceCapabilities['liveActivities'] ?? false,
              ),
              _buildSwitchTile(
                title: 'Smart Stack',
                subtitle: 'Add debt widgets to Smart Stack',
                value: _smartStackEnabled,
                onChanged: (value) => setState(() => _smartStackEnabled = value),
                enabled: _deviceCapabilities['smartStack'] ?? false,
              ),
              _buildSwitchTile(
                title: 'AI Features',
                subtitle: 'Use AI-powered insights and predictions',
                value: _aiFeaturesEnabled,
                onChanged: (value) => setState(() => _aiFeaturesEnabled = value),
                enabled: _deviceCapabilities['aiFeatures'] ?? false,
              ),
              
              const SizedBox(height: 20),
              
              // Interruption Levels
              _buildSectionTitle('Interruption Level'),
              _buildInterruptionLevelSelector(),
            ],
            
            const SizedBox(height: 20),
            
            // Test Notifications
            _buildSectionTitle('Test Notifications'),
            _buildTestNotificationButtons(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIOS186StatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'iOS 18.6+ Supported',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your device supports advanced iOS 18.6+ notification features',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildInterruptionLevelSelector() {
    final levels = [
      {'value': 'active', 'title': 'Active', 'subtitle': 'Standard notifications'},
      {'value': 'timeSensitive', 'title': 'Time Sensitive', 'subtitle': 'Important but not critical'},
      {'value': 'critical', 'title': 'Critical', 'subtitle': 'Emergency notifications only'},
      {'value': 'passive', 'title': 'Passive', 'subtitle': 'Silent notifications'},
    ];
    
    return Container(
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
        children: levels.map((level) {
          final isSelected = _interruptionLevel == level['value'];
          return RadioListTile<String>(
            title: Text(
              level['title']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              level['subtitle']!,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.primary.withOpacity(0.8) : AppColors.textSecondary,
              ),
            ),
            value: level['value']!,
            groupValue: _interruptionLevel,
            onChanged: (value) => setState(() => _interruptionLevel = value!),
            activeColor: AppColors.primary,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestNotificationButtons() {
    return Column(
      children: [
        _buildTestButton(
          title: 'Test Success Notification',
          onPressed: () => _notificationService.showSuccessNotification(
            title: 'Test Success',
            body: 'This is a test success notification',
          ),
        ),
        _buildTestButton(
          title: 'Test Error Notification',
          onPressed: () => _notificationService.showErrorNotification(
            title: 'Test Error',
            body: 'This is a test error notification',
          ),
        ),
        _buildTestButton(
          title: 'Test Info Notification',
          onPressed: () => _notificationService.showInfoNotification(
            title: 'Test Info',
            body: 'This is a test info notification',
          ),
        ),
        _buildTestButton(
          title: 'Test Warning Notification',
          onPressed: () => _notificationService.showWarningNotification(
            title: 'Test Warning',
            body: 'This is a test warning notification',
          ),
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
} 