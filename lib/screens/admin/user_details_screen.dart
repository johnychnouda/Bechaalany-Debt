import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/app_colors.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription.dart';

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
  final SubscriptionService _subscriptionService = SubscriptionService();
  Subscription? _subscription;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubscription();
    });
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subscription = await _subscriptionService.getUserSubscription(widget.userId);
      setState(() {
        _subscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _grantSubscription(SubscriptionType type) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await _subscriptionService.grantSubscription(widget.userId, type);
      await _loadSubscription();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text(
              '${type == SubscriptionType.monthly ? "Monthly" : "Yearly"} subscription granted successfully!',
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
            content: Text('Failed to grant subscription: $e'),
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

  Future<void> _revokeSubscription() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Revoke Subscription'),
        content: const Text('Are you sure you want to revoke this subscription?'),
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
      await _subscriptionService.revokeSubscription(widget.userId);
      await _loadSubscription();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Subscription revoked successfully!'),
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
            content: Text('Failed to revoke subscription: $e'),
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

  Color _statusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return AppColors.dynamicSuccess(context);
      case SubscriptionStatus.trial:
        return AppColors.dynamicPrimary(context);
      case SubscriptionStatus.expired:
      case SubscriptionStatus.cancelled:
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
                            icon: CupertinoIcons.gift,
                            title: 'Grant Subscription',
                            description: 'Activate a paid plan for this user.',
                            child: Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton.filled(
                                    onPressed: _isUpdating
                                        ? null
                                        : () => _grantSubscription(SubscriptionType.monthly),
                                    child: const Text('Monthly'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CupertinoButton.filled(
                                    onPressed: _isUpdating
                                        ? null
                                        : () => _grantSubscription(SubscriptionType.yearly),
                                    child: const Text('Yearly'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isSubscriptionActuallyActive(_subscription)) ...[
                            const SizedBox(height: 24),
                            _buildActionGroup(
                              context,
                              icon: CupertinoIcons.xmark_circle_fill,
                              title: 'Revoke Subscription',
                              description: 'Remove paid access. The user will lose subscription benefits.',
                              isDestructive: true,
                              child: _buildDestructiveOutlineButton(
                                context,
                                label: 'Revoke Subscription',
                                icon: CupertinoIcons.xmark_circle,
                                onPressed: _isUpdating ? null : _revokeSubscription,
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
    final sub = _subscription;
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
                    'No subscription data',
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
                if (sub.subscriptionStartDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    'Subscription Started',
                    _formatDate(sub.subscriptionStartDate!),
                  ),
                ],
                if (sub.subscriptionEndDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    'Subscription Ends',
                    _formatDateWithContext(
                      sub.subscriptionEndDate!,
                      sub.subscriptionDaysRemaining,
                      isEndDate: true,
                    ),
                  ),
                ],
                if (sub.type != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    'Plan',
                    sub.type == SubscriptionType.monthly ? 'Monthly' : 'Yearly',
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

  String _statusLabel(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.trial:
        return 'Trial';
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get the actual status label based on both status and dates
  String _getActualStatusLabel(Subscription subscription) {
    // If status is cancelled, always show cancelled
    if (subscription.status == SubscriptionStatus.cancelled) {
      return 'Cancelled';
    }
    
    // If status is expired, always show expired
    if (subscription.status == SubscriptionStatus.expired) {
      return 'Expired';
    }
    
    // If status is active, check if subscription has actually expired
    if (subscription.status == SubscriptionStatus.active) {
      if (subscription.subscriptionEndDate != null) {
        final now = DateTime.now();
        if (now.isAfter(subscription.subscriptionEndDate!)) {
          return 'Expired';
        }
      }
      return 'Active';
    }
    
    // If status is trial, check if trial has expired
    if (subscription.status == SubscriptionStatus.trial) {
      if (subscription.trialEndDate != null) {
        final now = DateTime.now();
        if (now.isAfter(subscription.trialEndDate!)) {
          return 'Trial Expired';
        }
      }
      return 'Trial';
    }
    
    // Default to status label
    return _statusLabel(subscription.status);
  }

  /// Check if subscription is actually active (not expired)
  bool _isSubscriptionActuallyActive(Subscription? subscription) {
    if (subscription == null) return false;
    
    // If status is cancelled or expired, it's not active
    if (subscription.status == SubscriptionStatus.cancelled || 
        subscription.status == SubscriptionStatus.expired) {
      return false;
    }
    
    // If status is active, check if subscription end date has passed
    if (subscription.status == SubscriptionStatus.active) {
      if (subscription.subscriptionEndDate != null) {
        final now = DateTime.now();
        if (now.isAfter(subscription.subscriptionEndDate!)) {
          return false; // Subscription has expired
        }
      }
      return true; // Active and not expired
    }
    
    // Trial status is not considered an active subscription for revoke purposes
    return false;
  }

  /// Get the actual status color based on both status and dates
  Color _getActualStatusColor(Subscription subscription) {
    // If status is cancelled, always show cancelled color
    if (subscription.status == SubscriptionStatus.cancelled) {
      return AppColors.dynamicError(context);
    }
    
    // If status is expired, always show expired color
    if (subscription.status == SubscriptionStatus.expired) {
      return AppColors.dynamicError(context);
    }
    
    // If status is active, check if subscription has actually expired
    if (subscription.status == SubscriptionStatus.active) {
      if (subscription.subscriptionEndDate != null) {
        final now = DateTime.now();
        if (now.isAfter(subscription.subscriptionEndDate!)) {
          return AppColors.dynamicError(context);
        }
      }
      return AppColors.dynamicSuccess(context);
    }
    
    // If status is trial, check if trial has expired
    if (subscription.status == SubscriptionStatus.trial) {
      if (subscription.trialEndDate != null) {
        final now = DateTime.now();
        if (now.isAfter(subscription.trialEndDate!)) {
          return Colors.orange;
        }
      }
      return AppColors.dynamicPrimary(context);
    }
    
    // Default to status color
    return _statusColor(subscription.status);
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
