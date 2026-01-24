import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../services/subscription_service.dart';
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
  final SubscriptionService _subscriptionService = SubscriptionService();
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

  String _getStatusText(String? status, Map<String, dynamic> user) {
    // Check if trial has expired but no subscription was started
    if (status == 'trial') {
      final trialEndDate = user['trialEndDate'] as Timestamp?;
      final subscriptionType = user['subscriptionType'] as String?;
      
      // If trial has ended and no subscription was started, show "Trial Expired"
      if (trialEndDate != null && subscriptionType == null) {
        final now = DateTime.now();
        final trialEnd = trialEndDate.toDate();
        if (now.isAfter(trialEnd)) {
          return 'Trial Expired';
        }
      }
      return 'Trial';
    }
    
    switch (status) {
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Trial';
    }
  }

  Color _getStatusColor(String? status, {bool isTrialExpired = false}) {
    // If trial expired, use orange/red color
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
    final status = user['subscriptionStatus'] as String? ?? 'trial';
    if (status != 'trial') return false;
    
    final trialEndDate = user['trialEndDate'] as Timestamp?;
    final subscriptionType = user['subscriptionType'] as String?;
    
    // Trial expired if: status is trial, trialEndDate exists and is past, and no subscription started
    if (trialEndDate != null && subscriptionType == null) {
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

  String _getFilterLabel(UserFilter filter) {
    switch (filter) {
      case UserFilter.all:
        return 'All';
      case UserFilter.trial:
        return 'Trial';
      case UserFilter.monthly:
        return 'Monthly';
      case UserFilter.yearly:
        return 'Yearly';
      case UserFilter.expired:
        return 'Expired';
    }
  }

  bool _matchesFilter(Map<String, dynamic> user, UserFilter filter) {
    final status = user['subscriptionStatus'] as String? ?? 'trial';
    final subscriptionType = user['subscriptionType'] as String?;
    final isTrialExpired = _isTrialExpired(user);

    switch (filter) {
      case UserFilter.all:
        return true;
      case UserFilter.trial:
        // Show only active trials (exclude expired trials)
        return status == 'trial' && !isTrialExpired;
      case UserFilter.monthly:
        return status == 'active' && subscriptionType?.toLowerCase() == 'monthly';
      case UserFilter.yearly:
        return status == 'active' && subscriptionType?.toLowerCase() == 'yearly';
      case UserFilter.expired:
        // Include both expired subscriptions and expired trials
        return status == 'expired' || isTrialExpired;
    }
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'No users match your search';
    }
    
    switch (_selectedFilter) {
      case UserFilter.all:
        return 'No users found';
      case UserFilter.trial:
        return 'No trial users found';
      case UserFilter.monthly:
        return 'No monthly users found';
      case UserFilter.yearly:
        return 'No yearly users found';
      case UserFilter.expired:
        return 'No expired users found';
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
          middle: const Text('User Management'),
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
                placeholder: 'Search by email or name...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            
            // Filter Chips
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
                            _getFilterLabel(filter),
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
            
            const SizedBox(height: 8),
            
            // Users List
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
                                  'Access Denied',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.dynamicTextPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You do not have admin permissions to view this page.',
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
                          stream: _subscriptionService.getAllUsersWithSubscriptionsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CupertinoActivityIndicator());
                            }

                            if (snapshot.hasError) {
                              final error = snapshot.error.toString();
                              final isPermissionError = error.contains('permission-denied');
                              
                              return Center(
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
                                            ? 'Permission Denied'
                                            : 'Error',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.dynamicTextPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isPermissionError
                                            ? 'You do not have permission to access user data. Please ensure your account is marked as admin in Firestore.'
                                            : 'Error: $error',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.dynamicTextSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: 'No users found',
                            style: TextStyle(
                              color: AppColors.dynamicTextSecondary(context),
                              fontSize: 16,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Filter out admin users, apply search query, and apply subscription filter
                  final users = snapshot.data!.where((user) {
                    // Exclude admin users
                    final isAdmin = user['isAdmin'] == true;
                    if (isAdmin) return false;
                    
                    // Apply subscription filter
                    if (!_matchesFilter(user, _selectedFilter)) return false;
                    
                    // Apply search filter
                    if (_searchQuery.isEmpty) return true;
                    final email = (user['email'] ?? '').toString().toLowerCase();
                    final displayName = (user['displayName'] ?? '').toString().toLowerCase();
                    return email.contains(_searchQuery) || displayName.contains(_searchQuery);
                  }).toList();

                  if (users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: _getEmptyStateMessage(),
                            style: TextStyle(
                              color: AppColors.dynamicTextSecondary(context),
                              fontSize: 16,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final status = user['subscriptionStatus'] as String? ?? 'trial';
                      final isTrialExpired = _isTrialExpired(user);
                      final statusColor = _getStatusColor(status, isTrialExpired: isTrialExpired);
                      
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
                                              _getStatusText(status, user),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                          if (user['subscriptionType'] != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '• ${user['subscriptionType']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.dynamicTextSecondary(context),
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
