import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Access? _access;
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isSavingProfile = false;
  String _userDisplayName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _shopName = '';

  @override
  void initState() {
    super.initState();
    _userDisplayName = widget.userDisplayName;
    _userEmail = widget.userEmail;
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
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      final userData = userDoc.data();
      setState(() {
        _access = access;
        _userDisplayName = (userData?['displayName'] as String?)?.trim().isNotEmpty == true
            ? (userData?['displayName'] as String).trim()
            : widget.userDisplayName;
        _userEmail = (userData?['email'] as String?)?.trim().isNotEmpty == true
            ? (userData?['email'] as String).trim()
            : widget.userEmail;
        _userPhone = (userData?['phone'] as String?)?.trim() ?? '';
        _shopName = (userData?['businessName'] as String?)?.trim() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidPhoneNumber(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return true;
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 8 || digitsOnly.length > 15) return false;
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
    return phoneRegex.hasMatch(trimmed);
  }

  Future<void> _showEditProfileDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: _userDisplayName);
    final phoneController = TextEditingController(text: _userPhone);
    String? validationError;

    final result = await showCupertinoDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return CupertinoAlertDialog(
            title: Text(l10n.editCustomer),
            content: Column(
              children: [
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: l10n.enterCustomerName,
                  autofocus: true,
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: phoneController,
                  placeholder: l10n.enterPhoneNumber,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    validationError!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() {
                      validationError = l10n.pleaseEnterCustomerName;
                    });
                    return;
                  }
                  if (!_isValidPhoneNumber(phone)) {
                    setDialogState(() {
                      validationError = l10n.validPhoneNumber;
                    });
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    'name': name,
                    'phone': phone,
                  });
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    phoneController.dispose();

    if (result == null || !mounted) return;
    await _saveProfileChanges(result['name'] ?? '', result['phone'] ?? '');
  }

  Future<void> _saveProfileChanges(String name, String phone) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSavingProfile) return;

    setState(() => _isSavingProfile = true);
    try {
      await _firestore.collection('users').doc(widget.userId).set({
        'displayName': name,
        'phone': phone,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _userDisplayName = name;
        _userPhone = phone;
      });
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(l10n.error),
          content: Text(l10n.saveFailedTryAgain),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
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
        final l10n = AppLocalizations.of(context)!;
        final duration = type == AccessType.monthly ? l10n.oneMonthLabel : l10n.oneYearLabel;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.success),
            content: Text(l10n.accessGrantedSuccess(duration)),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text(l10n.failedToGrantAccess(e.toString())),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.revokeAccess),
        content: Text(l10n.revokeAccessConfirm),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.revoke),
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
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.success),
            content: Text(l10n.accessRevokedSuccess),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text(l10n.failedToRevokeAccess(e.toString())),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
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
  String _formatDateWithContext(BuildContext context, DateTime date, int? daysRemaining, {bool isEndDate = true}) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = _formatDate(date);
    if (daysRemaining == null) return dateStr;
    if (daysRemaining <= 0) return isEndDate ? '$dateStr ${l10n.dateExpired}' : dateStr;
    if (daysRemaining == 1) return '$dateStr ${l10n.dateDaysLeftOne}';
    return '$dateStr ${l10n.dateDaysLeftOther(daysRemaining.toString())}';
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
    final l10n = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.userDetails),
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
                      l10n.loadingUserDetails,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 24,
                                onPressed: _isSavingProfile ? null : _showEditProfileDialog,
                                child: Icon(
                                  CupertinoIcons.pencil,
                                  size: 20,
                                  color: AppColors.dynamicPrimary(context),
                                ),
                              ),
                            ],
                          ),
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
                            _userDisplayName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                          if (_userPhone.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _userPhone,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.dynamicTextSecondary(context),
                              ),
                            ),
                          ],
                          if (_shopName.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.shopName}: $_shopName',
                              style: TextStyle(
                                fontSize: 20,
                                color: AppColors.dynamicTextSecondary(context),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _userEmail,
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColors.dynamicTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Current Status
                    Text(
                      l10n.currentStatus,
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
                      l10n.actions,
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
                                    l10n.updating,
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
                            title: l10n.grantAccess,
                            description: l10n.grantAccessDescription,
                            child: Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton.filled(
                                    onPressed: _isUpdating
                                        ? null
                                        : () => _grantAccess(AccessType.monthly),
                                    child: Text(l10n.oneMonth),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CupertinoButton.filled(
                                    onPressed: _isUpdating
                                        ? null
                                        : () => _grantAccess(AccessType.yearly),
                                    child: Text(l10n.oneYear),
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
                              title: l10n.revokeAccess,
                              description: l10n.revokeAccessDescription,
                              isDestructive: true,
                              child: _buildDestructiveOutlineButton(
                                context,
                                label: l10n.revokeAccess,
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
    final l10n = AppLocalizations.of(context)!;
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
                    l10n.noAccessData,
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
                _buildStatusRow(l10n.status, _getActualStatusLabel(context, sub),
                    valueColor: _getActualStatusColor(sub)),
                if (sub.trialStartDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(l10n.trialStarted, _formatDate(sub.trialStartDate!)),
                ],
                if (sub.trialEndDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    l10n.trialEnds,
                    _formatDateWithContext(
                      context,
                      sub.trialEndDate!,
                      sub.trialDaysRemaining,
                      isEndDate: true,
                    ),
                  ),
                ],
                if (sub.accessStartDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    l10n.accessStarted,
                    _formatDate(sub.accessStartDate!),
                  ),
                ],
                if (sub.accessEndDate != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    l10n.accessEnds,
                    _formatDateWithContext(
                      context,
                      sub.accessEndDate!,
                      sub.accessDaysRemaining,
                      isEndDate: true,
                    ),
                  ),
                ],
                if (sub.type != null) ...[
                  _buildStatusDivider(),
                  _buildStatusRow(
                    l10n.accessPeriod,
                    sub.type == AccessType.monthly ? l10n.oneMonthLabel : l10n.oneYearLabel,
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
                        l10n.updatedDate(_formatDate(sub.lastUpdated)),
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

  String _statusLabel(BuildContext context, AccessStatus s) {
    final l10n = AppLocalizations.of(context)!;
    switch (s) {
      case AccessStatus.trial:
        return l10n.trial;
      case AccessStatus.active:
        return l10n.active;
      case AccessStatus.expired:
        return l10n.expired;
      case AccessStatus.cancelled:
        return l10n.cancelled;
    }
  }

  String _getActualStatusLabel(BuildContext context, Access access) {
    final l10n = AppLocalizations.of(context)!;
    if (access.status == AccessStatus.cancelled) return l10n.cancelled;
    if (access.status == AccessStatus.expired) return l10n.expired;
    if (access.status == AccessStatus.active) {
      if (access.accessEndDate != null) {
        if (DateTime.now().isAfter(access.accessEndDate!)) return l10n.expired;
      }
      return l10n.active;
    }
    if (access.status == AccessStatus.trial) {
      if (access.trialEndDate != null) {
        if (DateTime.now().isAfter(access.trialEndDate!)) return l10n.trialExpired;
      }
      return l10n.trial;
    }
    return _statusLabel(context, access.status);
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
