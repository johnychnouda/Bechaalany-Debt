import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/firestore_access_keys.dart';
import '../../l10n/app_localizations.dart';
import '../../services/access_service.dart';
import '../../services/admin_service.dart';
import 'user_details_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

enum UserFilter {
  all,
  trial,
  monthly,
  yearly,
  expired,
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AccessService _accessService = AccessService();
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserFilter _selectedFilter = UserFilter.all;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _adminService.isAdmin();
      setState(() {
        _isAdmin = isAdmin;
        _isCheckingAdmin = false;
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// True when paid access period has ended by [accessEndDate], matching
  /// [AdminDashboardScreen] stats and [UserDetailsScreen] labels (Firestore
  /// [accessStatus] can remain `active` after the end date).
  bool _isPaidAccessEndedByDate(Map<String, dynamic> user) {
    final end = user[FirestoreAccessKeys.endDate] as Timestamp?;
    if (end == null) return false;
    if (DateTime.now().isBefore(end.toDate())) return false;

    final status = user[FirestoreAccessKeys.status] as String? ?? 'trial';
    if (status == 'active') return true;

    final accessType = user[FirestoreAccessKeys.type];
    final hasPaidType = accessType != null &&
        accessType.toString().trim().isNotEmpty &&
        (accessType.toString().toLowerCase() == 'monthly' ||
            accessType.toString().toLowerCase() == 'yearly');
    return hasPaidType;
  }

  String _getStatusText(BuildContext context, String? status, Map<String, dynamic> user) {
    final l10n = AppLocalizations.of(context)!;
    if (status == 'cancelled') return l10n.cancelled;
    if (status == 'expired') return l10n.expired;
    if (_isPaidAccessEndedByDate(user)) return l10n.expired;

    // Check if trial has expired but no access was granted
    if (status == 'trial') {
      final trialEndDate = user['trialEndDate'] as Timestamp?;
      final accessType = user[FirestoreAccessKeys.type] as String?;
      
      // If trial has ended and no access was granted, show "Trial Expired"
      if (trialEndDate != null && accessType == null) {
        final now = DateTime.now();
        final trialEnd = trialEndDate.toDate();
        if (now.isAfter(trialEnd)) {
          return l10n.trialExpired;
        }
      }
      return l10n.trial;
    }
    
    switch (status) {
      case 'active':
        return l10n.activeStatus;
      case 'expired':
        return l10n.expired;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return l10n.trial;
    }
  }

  Color _getStatusColor(String? status, Map<String, dynamic> user,
      {bool isTrialExpired = false}) {
    if (status == 'cancelled') return Colors.grey;
    if (status == 'expired' || _isPaidAccessEndedByDate(user)) {
      return Colors.red;
    }
    if (isTrialExpired) {
      return Colors.orange;
    }

    switch (status) {
      case 'trial':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
  
  bool _isTrialExpired(Map<String, dynamic> user) {
    final status = user[FirestoreAccessKeys.status] as String? ?? 'trial';
    if (status != 'trial') return false;
    
    final trialEndDate = user['trialEndDate'] as Timestamp?;
    final accessType = user[FirestoreAccessKeys.type] as String?;
    
    // Trial expired if: status is trial, trialEndDate exists and is past, and no access granted
    if (trialEndDate != null && accessType == null) {
      final now = DateTime.now();
      final trialEnd = trialEndDate.toDate();
      return now.isAfter(trialEnd);
    }
    
    return false;
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  String _localizeAccessType(BuildContext context, String type) {
    final t = type.toLowerCase();
    final l10n = AppLocalizations.of(context)!;
    if (t == 'monthly') return l10n.monthlyFilter;
    if (t == 'yearly') return l10n.yearlyFilter;
    return type;
  }

  String _getFilterLabel(BuildContext context, UserFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    switch (filter) {
      case UserFilter.all:
        return l10n.filterAll;
      case UserFilter.trial:
        return l10n.trial;
      case UserFilter.monthly:
        return l10n.monthlyFilter;
      case UserFilter.yearly:
        return l10n.yearlyFilter;
      case UserFilter.expired:
        return l10n.expired;
    }
  }

  /// Count non-admin users that match each filter. Call only when user list is available.
  Map<UserFilter, int> _getFilterCounts(List<Map<String, dynamic>> allUsers) {
    final nonAdmin = allUsers.where((u) => u['isAdmin'] != true).toList();
    return {
      UserFilter.all: nonAdmin.length,
      UserFilter.trial: nonAdmin.where((u) => _matchesFilter(u, UserFilter.trial)).length,
      UserFilter.monthly: nonAdmin.where((u) => _matchesFilter(u, UserFilter.monthly)).length,
      UserFilter.yearly: nonAdmin.where((u) => _matchesFilter(u, UserFilter.yearly)).length,
      UserFilter.expired: nonAdmin.where((u) => _matchesFilter(u, UserFilter.expired)).length,
    };
  }

  /// Matches the green "Active" badge (paid access still valid by end date).
  bool _isDisplayedActive(Map<String, dynamic> user) {
    final status = user[FirestoreAccessKeys.status] as String? ?? 'trial';
    return status == 'active' && !_isPaidAccessEndedByDate(user);
  }

  /// Days until paid access ends or trial ends; null when not applicable or already ended.
  int? _daysRemainingForUser(Map<String, dynamic> user) {
    final status = user[FirestoreAccessKeys.status] as String? ?? 'trial';
    if (status == 'cancelled') return null;
    final now = DateTime.now();
    final accessEnd = user[FirestoreAccessKeys.endDate] as Timestamp?;
    final trialEnd = user['trialEndDate'] as Timestamp?;
    final accessType = user[FirestoreAccessKeys.type] as String?;
    final t = accessType?.toLowerCase();

    if (accessEnd != null) {
      final endDt = accessEnd.toDate();
      if (!now.isAfter(endDt)) {
        final hasPaidType = t == 'monthly' || t == 'yearly';
        if (hasPaidType || status == 'active') {
          return endDt.difference(now).inDays;
        }
      }
    }

    if (status == 'trial' && trialEnd != null && !_isTrialExpired(user)) {
      final tEnd = trialEnd.toDate();
      if (now.isBefore(tEnd)) {
        return tEnd.difference(now).inDays;
      }
    }
    return null;
  }

  /// 0 = ongoing trial, 1 = paid active, 2 = expired (incl. trial expired / ended access), 3 = cancelled.
  int _allListSortTier(Map<String, dynamic> user) {
    final status = user[FirestoreAccessKeys.status] as String? ?? 'trial';
    if (status == 'cancelled') return 3;

    final isTrialExpired = _isTrialExpired(user);
    if (status == 'expired' ||
        isTrialExpired ||
        _isPaidAccessEndedByDate(user)) {
      return 2;
    }

    if (status == 'trial') return 0;
    if (_isDisplayedActive(user)) return 1;
    if (status == 'active') return 1;

    return 2;
  }

  String _userSortNameKey(Map<String, dynamic> user) {
    final name = (user['displayName'] ?? '').toString().toLowerCase();
    if (name.isNotEmpty) return name;
    return (user['email'] ?? '').toString().toLowerCase();
  }

  /// Trial → Active → Expired → Cancelled; trial/active sorted by fewer days remaining first.
  int _compareUsersForAllList(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    const largeDays = 1 << 30;
    final ta = _allListSortTier(a);
    final tb = _allListSortTier(b);
    if (ta != tb) return ta.compareTo(tb);

    if (ta == 0 || ta == 1) {
      final da = _daysRemainingForUser(a) ?? largeDays;
      final db = _daysRemainingForUser(b) ?? largeDays;
      if (da != db) return da.compareTo(db);
    }

    return _userSortNameKey(a).compareTo(_userSortNameKey(b));
  }

  int _compareUsersByDaysRemainingAscThenName(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    const largeDays = 1 << 30;
    final da = _daysRemainingForUser(a) ?? largeDays;
    final db = _daysRemainingForUser(b) ?? largeDays;
    if (da != db) return da.compareTo(db);
    return _userSortNameKey(a).compareTo(_userSortNameKey(b));
  }

  bool _matchesFilter(Map<String, dynamic> user, UserFilter filter) {
    final status = user[FirestoreAccessKeys.status] as String? ?? 'trial';
    final accessType = user[FirestoreAccessKeys.type] as String?;
    final isTrialExpired = _isTrialExpired(user);

    switch (filter) {
      case UserFilter.all:
        return true;
      case UserFilter.trial:
        // Show only active trials (exclude expired trials)
        return status == 'trial' && !isTrialExpired;
      case UserFilter.monthly:
        if (accessType?.toLowerCase() != 'monthly') return false;
        if (status == 'cancelled' || status == 'expired') return false;
        if (isTrialExpired) return false;
        if (_isPaidAccessEndedByDate(user)) return false;
        return true;
      case UserFilter.yearly:
        if (accessType?.toLowerCase() != 'yearly') return false;
        if (status == 'cancelled' || status == 'expired') return false;
        if (isTrialExpired) return false;
        if (_isPaidAccessEndedByDate(user)) return false;
        return true;
      case UserFilter.expired:
        return status == 'expired' ||
            status == 'cancelled' ||
            isTrialExpired ||
            _isPaidAccessEndedByDate(user);
    }
  }

  String _getEmptyStateMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_searchQuery.isNotEmpty) {
      return l10n.noUsersMatchSearch;
    }
    switch (_selectedFilter) {
      case UserFilter.all:
        return l10n.noUsersFound;
      case UserFilter.trial:
        return l10n.noTrialUsersFound;
      case UserFilter.monthly:
        return l10n.noMonthlyUsersFound;
      case UserFilter.yearly:
        return l10n.noYearlyUsersFound;
      case UserFilter.expired:
        return l10n.noExpiredUsersFound;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.dynamicBackground(context),
        navigationBar: CupertinoNavigationBar(
          middle: Text(AppLocalizations.of(context)!.userManagement),
          backgroundColor: AppColors.dynamicSurface(context),
          border: null,
        ),
        child: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: AppLocalizations.of(context)!.searchByEmailOrName,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Users List (StreamBuilder wraps filter chips + list so we can show counts)
            Expanded(
              child: _isCheckingAdmin
                  ? const Center(child: CupertinoActivityIndicator())
                  : !_isAdmin
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  size: 64,
                                  color: AppColors.dynamicTextSecondary(context),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.accessDenied,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.dynamicTextPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.noAdminPermissions,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.dynamicTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _accessService.getAllUsersWithAccessStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CupertinoActivityIndicator());
                            }

                            // Build filter chips row (labels only) and a small counts summary below.
                            final allUsers = snapshot.hasData ? snapshot.data! : <Map<String, dynamic>>[];
                            final counts = allUsers.isNotEmpty ? _getFilterCounts(allUsers) : null;
                            final filterChips = Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: UserFilter.values.map((filter) {
                                        final isSelected = _selectedFilter == filter;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              setState(() {
                                                _selectedFilter = filter;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.dynamicPrimary(context)
                                                    : AppColors.dynamicSurface(context),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.dynamicPrimary(context)
                                                      : AppColors.dynamicBorder(context),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                _getFilterLabel(context, filter),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppColors.dynamicTextPrimary(context),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                if (counts != null) ...[
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      AppLocalizations.of(context)!.userSummaryCounts(
                                        (counts[UserFilter.all] ?? 0).toString(),
                                        (counts[UserFilter.trial] ?? 0).toString(),
                                        (counts[UserFilter.monthly] ?? 0).toString(),
                                        (counts[UserFilter.yearly] ?? 0).toString(),
                                        (counts[UserFilter.expired] ?? 0).toString(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.dynamicTextSecondary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );

                            if (snapshot.hasError) {
                              final error = snapshot.error.toString();
                              final isPermissionError = error.contains('permission-denied');
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  filterChips,
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.exclamationmark_triangle,
                                              size: 64,
                                              color: AppColors.dynamicTextSecondary(context),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              isPermissionError
                                                  ? AppLocalizations.of(context)!.permissionDenied
                                                  : AppLocalizations.of(context)!.error,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.dynamicTextPrimary(context),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              isPermissionError
                                                  ? AppLocalizations.of(context)!.permissionDeniedMessage
                                                  : '${AppLocalizations.of(context)!.error}: $error',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.dynamicTextSecondary(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        filterChips,
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: AppLocalizations.of(context)!.noUsersFound,
                                  style: TextStyle(
                                    color: AppColors.dynamicTextSecondary(context),
                                    fontSize: 16,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Filter out admin users, apply search query, and apply access filter
                  final users = snapshot.data!.where((user) {
                    // Exclude admin users
                    final isAdmin = user['isAdmin'] == true;
                    if (isAdmin) return false;
                    
                    // Apply access filter
                    if (!_matchesFilter(user, _selectedFilter)) return false;
                    
                    // Apply search filter
                    if (_searchQuery.isEmpty) return true;
                    final email = (user['email'] ?? '').toString().toLowerCase();
                    final displayName = (user['displayName'] ?? '').toString().toLowerCase();
                    return email.contains(_searchQuery) || displayName.contains(_searchQuery);
                  }).toList();

                  if (_selectedFilter == UserFilter.all) {
                    users.sort(_compareUsersForAllList);
                  } else if (_selectedFilter == UserFilter.trial ||
                      _selectedFilter == UserFilter.monthly ||
                      _selectedFilter == UserFilter.yearly) {
                    users.sort(_compareUsersByDaysRemainingAscThenName);
                  }

                  if (users.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        filterChips,
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: _getEmptyStateMessage(context),
                                  style: TextStyle(
                                    color: AppColors.dynamicTextSecondary(context),
                                    fontSize: 16,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      filterChips,
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final status = user[FirestoreAccessKeys.status] as String? ?? 'trial';
                      final isTrialExpired = _isTrialExpired(user);
                      final statusColor =
                          _getStatusColor(status, user, isTrialExpired: isTrialExpired);
                      final daysLeft = _daysRemainingForUser(user);
                      final l10n = AppLocalizations.of(context)!;
                      final hidePlanUnderEmail = _selectedFilter == UserFilter.all &&
                          _matchesFilter(user, UserFilter.expired);
                      final accessTypeLower =
                          (user[FirestoreAccessKeys.type] as String?)?.toLowerCase();
                      final hideRedundantAccessTypeLabel =
                          (_selectedFilter == UserFilter.monthly &&
                                  accessTypeLower == 'monthly') ||
                              (_selectedFilter == UserFilter.yearly &&
                                  accessTypeLower == 'yearly') ||
                              (_selectedFilter == UserFilter.trial) ||
                              (_selectedFilter == UserFilter.expired);
                      final showAccessTypePart =
                          user[FirestoreAccessKeys.type] != null &&
                              !hideRedundantAccessTypeLabel;
                      final showDaysPart = daysLeft != null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.dynamicSurface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.dynamicBorder(context),
                            width: 1,
                          ),
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => UserDetailsScreen(
                                  userId: user['userId'] as String,
                                  userEmail: user['email'] as String? ?? 'No email',
                                  userDisplayName: user['displayName'] as String? ?? 'No name',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.person,
                                    color: statusColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['displayName'] as String? ?? 'No name',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.dynamicTextPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user['email'] as String? ?? 'No email',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.dynamicTextSecondary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getStatusText(context, status, user),
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.2,
                                                fontWeight: FontWeight.w600,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                          if (!hidePlanUnderEmail &&
                                              (showAccessTypePart || showDaysPart)) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    height: 1.2,
                                                    color: AppColors.dynamicTextSecondary(
                                                        context),
                                                  ),
                                                  children: [
                                                    if (showAccessTypePart)
                                                      TextSpan(
                                                        text:
                                                            '• ${_localizeAccessType(context, user[FirestoreAccessKeys.type].toString())}',
                                                      ),
                                                    if (showDaysPart)
                                                      TextSpan(
                                                        text: showAccessTypePart
                                                            ? ' (${l10n.daysRemaining(daysLeft.toString())})'
                                                            : '(${l10n.daysRemaining(daysLeft.toString())})',
                                                      ),
                                                  ],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  color: AppColors.dynamicTextSecondary(context),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                        ),
                      ),
                    ],
                  );
                          },
                        ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
