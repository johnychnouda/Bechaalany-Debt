import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/app_colors.dart';
import '../../services/access_service.dart';
import '../../models/access.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userDisplayName;

  const UserDetailsScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userDisplayName,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final AccessService _accessService = AccessService();
  Access? _access;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccess();
    });
  }

  Future<void> _loadAccess() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final access = await _accessService.getUserAccess(widget.userId);
      setState(() {
        _access = access;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _grantAccess(AccessType type) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await _accessService.grantAccess(widget.userId, type);
      await _loadAccess();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text(
              'Access granted successfully (${type == AccessType.monthly ? "1 month" : "1 year"})!',
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
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to grant access: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _revokeAccess() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Revoke Access'),
        content: const Text('Are you sure you want to revoke this user\'s access?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _accessService.revokeAccess(widget.userId);
      await _loadAccess();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Access revoked successfully!'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to revoke access: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Returns contextual text like "21/1/2026 (7 days remaining)" or "28/1/2026 (Expired)".
  String _formatDateWithContext(DateTime date, int? daysRemaining, {bool isEndDate = true}) {
    final dateStr = _formatDate(date);
    if (daysRemaining == null) return dateStr;
    if (daysRemaining <= 0) return isEndDate ? '$dateStr (Expired)' : dateStr;
    if (daysRemaining == 1) return '$dateStr (1 day left)';
    return '$dateStr ($daysRemaining days left)';
  }

  Color _statusColor(AccessStatus status) {
    switch (status) {
      case AccessStatus.active:
        return AppColors.dynamicSuccess(context);
      case AccessStatus.trial:
        return AppColors.dynamicPrimary(context);
      case AccessStatus.expired:
      case AccessStatus.cancelled:
        return AppColors.dynamicError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('User Details'),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CupertinoActivityIndicator(radius: 14),
                    const SizedBox(height: 16),
                    Text(
                      'Loading user details…',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.dynamicTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // User Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.dynamicSurface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.dynamicBorder(context),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.person,
                              color: AppColors.dynamicPrimary(context),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.userDisplayName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.dynamicTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Current Status
                    Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusCard(context),
                    const SizedBox(height: 32),
                    
                    // Actions
                    Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.dynamicSurface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.dynamicBorder(context),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isUpdating)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CupertinoActivityIndicator(
                                      radius: 7,
                                      color: AppColors.dynamicPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Updating…',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.dynamicTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _buildActionGroup(
                            context,
                            icon: CupertinoIcons.checkmark_circle,
                            title: 'Grant Access',
                            description: 'Grant continued access to this user. Choose duration.',
                            child: Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton.filled(
                                    onPressed: _isUpdating
                                        ? null
                                        : () => _grantAccess(AccessType.monthly),
                                    child: const Text('1 Month'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CupertinoButton.filled(
                                    onPressed: _isUpdating
                                        ? null
                                        : () => _grantAccess(AccessType.yearly),
                                    child: const Text('1 Year'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isAccessActuallyActive(_access)) ...[
                            const SizedBox(height: 24),
                            _buildActionGroup(
                              context,
                              icon: CupertinoIcons.xmark_circle_fill,
                              title: 'Revoke Access',
                              description: 'Temporarily suspend this account. The user can contact you if there is an issue.',
                              isDestructive: true,
                              child: _buildDestructiveOutlineButton(
                                context,
                                label: 'Revoke Access',
                                icon: CupertinoIcons.xmark_circle,
                                onPressed: _isUpdating ? null : _revokeAccess,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionGroup(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Widget child,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive
        ? AppColors.dynamicError(context)
        : AppColors.dynamicPrimary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextPrimary(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDestructiveOutlineButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    final errorColor = AppColors.dynamicError(context);
    final fg = enabled ? errorColor : errorColor.withValues(alpha: 0.5);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      color: Colors.transparent,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: errorColor.withValues(alpha: enabled ? 0.08 : 0.04),
          border: Border.all(
            color: fg.withValues(alpha: enabled ? 0.5 : 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildStatusCard(BuildContext context) {
    final sub = _access;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 1,
        ),
      ),
      child: sub == null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    size: 20,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No access data',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.dynamicTextSecondary(context),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildStatusRow('Status', _getActualStatusLabel(sub),
                    valueColor: _getActualStatusColor(sub)),
                if (sub.trialStartDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow('Trial Started', _formatDate(sub.trialStartDate!)),
                ],
                if (sub.trialEndDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    'Trial Ends',
                    _formatDateWithContext(
                      sub.trialEndDate!,
                      sub.trialDaysRemaining,
                      isEndDate: true,
                    ),
                  ),
                ],
                if (sub.accessStartDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    'Access Started',
                    _formatDate(sub.accessStartDate!),
                  ),
                ],
                if (sub.accessEndDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    'Access Ends',
                    _formatDateWithContext(
                      sub.accessEndDate!,
                      sub.accessDaysRemaining,
                      isEndDate: true,
                    ),
                  ),
                ],
                if (sub.type != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    'Access Period',
                    sub.type == AccessType.monthly ? '1 month' : '1 year',
                    valueColor: AppColors.dynamicPrimary(context),
                  ),
                ],
                _buildStatusDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 12,
                        color: AppColors.dynamicTextSecondary(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Updated ${_formatDate(sub.lastUpdated)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _statusLabel(AccessStatus s) {
    switch (s) {
      case AccessStatus.trial:
        return 'Trial';
      case AccessStatus.active:
        return 'Active';
      case AccessStatus.expired:
        return 'Expired';
      case AccessStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getActualStatusLabel(Access access) {
    if (access.status == AccessStatus.cancelled) return 'Cancelled';
    if (access.status == AccessStatus.expired) return 'Expired';
    if (access.status == AccessStatus.active) {
      if (access.accessEndDate != null) {
        if (DateTime.now().isAfter(access.accessEndDate!)) return 'Expired';
      }
      return 'Active';
    }
    if (access.status == AccessStatus.trial) {
      if (access.trialEndDate != null) {
        if (DateTime.now().isAfter(access.trialEndDate!)) return 'Trial Expired';
      }
      return 'Trial';
    }
    return _statusLabel(access.status);
  }

  bool _isAccessActuallyActive(Access? access) {
    if (access == null) return false;
    if (access.status == AccessStatus.cancelled ||
        access.status == AccessStatus.expired) return false;
    if (access.status == AccessStatus.active) {
      if (access.accessEndDate != null) {
        if (DateTime.now().isAfter(access.accessEndDate!)) return false;
      }
      return true;
    }
    return false;
  }

  Color _getActualStatusColor(Access access) {
    if (access.status == AccessStatus.cancelled) return AppColors.dynamicError(context);
    if (access.status == AccessStatus.expired) return AppColors.dynamicError(context);
    if (access.status == AccessStatus.active) {
      if (access.accessEndDate != null) {
        if (DateTime.now().isAfter(access.accessEndDate!)) return AppColors.dynamicError(context);
      }
      return AppColors.dynamicSuccess(context);
    }
    if (access.status == AccessStatus.trial) {
      if (access.trialEndDate != null) {
        if (DateTime.now().isAfter(access.trialEndDate!)) return Colors.orange;
      }
      return AppColors.dynamicPrimary(context);
    }
    return _statusColor(access.status);
  }

  Widget _buildStatusDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.dynamicDivider(context),
      indent: 12,
      endIndent: 12,
    );
  }

  Widget _buildStatusRow(String label, String value, {Color? valueColor}) {
    final color = valueColor ?? AppColors.dynamicTextPrimary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
