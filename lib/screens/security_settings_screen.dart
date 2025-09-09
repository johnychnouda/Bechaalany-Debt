import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';
import '../services/security_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final SecurityService _securityService = SecurityService();
  bool _isSecurityEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  int _autoLockMinutes = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _securityService.initialize();
    
    final securityEnabled = await _securityService.isSecurityEnabled();
    final biometricEnabled = await _securityService.isBiometricEnabled();
    final biometricAvailable = await _securityService.isBiometricAvailable();
    final autoLockMinutes = _securityService.autoLockMinutes;

    setState(() {
      _isSecurityEnabled = securityEnabled;
      _isBiometricEnabled = biometricEnabled;
      _isBiometricAvailable = biometricAvailable;
      _autoLockMinutes = autoLockMinutes;
      _isLoading = false;
    });
  }

  Future<void> _toggleSecurity(bool enabled) async {
    if (enabled) {
      // Check if biometric is available before enabling security
      if (!_isBiometricAvailable) {
        _showBiometricRequiredDialog();
        return;
      }
      
      // Enable security and biometric
      await _securityService.setSecurityEnabled(true);
      await _securityService.setBiometricEnabled(true);
      await _loadSettings();
    } else {
      // Disable security
      await _securityService.setSecurityEnabled(false);
      await _loadSettings();
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    await _securityService.setBiometricEnabled(enabled);
    await _loadSettings();
  }

  void _showBiometricRequiredDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Biometric Required'),
        content: const Text(
          'Biometric authentication (Face ID/Touch ID) is required to enable app security. Please set up biometric authentication in your device settings first.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAutoLockOptions() async {
    final options = [1, 2, 5, 10, 15, 30, 60];
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Auto-lock timeout'),
        actions: options.map((minutes) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _setAutoLockMinutes(minutes);
            },
            child: Text(
              minutes == 1 ? '1 minute' : '$minutes minutes',
              style: TextStyle(
                color: _autoLockMinutes == minutes 
                    ? AppColors.primary 
                    : AppColors.textPrimary,
                fontWeight: _autoLockMinutes == minutes 
                    ? FontWeight.w600 
                    : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _setAutoLockMinutes(int minutes) async {
    await _securityService.setAutoLockMinutes(minutes);
    setState(() {
      _autoLockMinutes = minutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.dynamicSurface(context),
        elevation: 0,
        leading: CupertinoNavigationBarBackButton(
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Security Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security Section
          _buildSection(
            title: 'App Security',
            children: [
              _buildSwitchTile(
                title: 'Enable App Lock',
                subtitle: 'Require authentication to access the app',
                value: _isSecurityEnabled,
                onChanged: _toggleSecurity,
              ),
              
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Biometric Section
          if (_isBiometricAvailable) ...[
            _buildSection(
              title: 'Biometric Authentication',
              children: [
              _buildSwitchTile(
                title: 'Enable ${_securityService.getPlatformBiometricName()}',
                subtitle: 'Use biometric authentication for app access',
                value: _isBiometricEnabled,
                onChanged: _isSecurityEnabled ? _toggleBiometric : null,
                enabled: _isSecurityEnabled,
              ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Auto-lock Section
          if (_isSecurityEnabled) ...[
            _buildSection(
              title: 'Auto-lock Settings',
              children: [
                _buildActionTile(
                  title: 'Auto-lock timeout',
                  subtitle: _autoLockMinutes == 1 
                      ? '1 minute' 
                      : '$_autoLockMinutes minutes',
                  onTap: _showAutoLockOptions,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Info Section
          _buildSection(
            title: 'Security Information',
            children: [
              _buildInfoTile(
                title: 'How it works',
                subtitle: 'When enabled, you\'ll need to authenticate with your biometrics every time you open the app or after the auto-lock timeout.',
              ),
              
              const SizedBox(height: 8),
              
              _buildInfoTile(
                title: 'Data Protection',
                subtitle: 'Your debt data is protected by device-level security. The app lock adds an extra layer of protection.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withOpacity(0.6),
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        color: AppColors.textSecondary,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
