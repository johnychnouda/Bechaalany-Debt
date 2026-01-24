import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../services/subscription_service.dart';
import 'user_management_screen.dart';
import 'subscription_pricing_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isRefreshing = false;

  Map<String, int> _calculateStatistics(List<Map<String, dynamic>> allUsers) {
    // Filter out admin users
    final users = allUsers.where((user) {
      final isAdmin = user['isAdmin'] == true;
      return !isAdmin;
    }).toList();
    
    int total = users.length;
    int active = 0;
    int trial = 0;
    int expired = 0;

    for (var user in users) {
      final status = user['subscriptionStatus'] as String? ?? 'trial';
      final subscriptionType = user['subscriptionType'];
      final subscriptionEndDate = user['subscriptionEndDate'] as Timestamp?;
      final trialEndDate = user['trialEndDate'] as Timestamp?;
      
      // Priority 1: Check status first - if cancelled or expired, count as expired/cancelled
      if (status == 'cancelled' || status == 'expired') {
        expired++;
      }
      // Priority 2: If status is 'active', they have an active subscription
      else if (status == 'active') {
        if (subscriptionEndDate != null) {
          final endDateTime = subscriptionEndDate.toDate();
          if (DateTime.now().isBefore(endDateTime)) {
            // Active subscription
            active++;
          } else {
            // Subscription expired (date passed but status still active)
            expired++;
          }
        } else {
          // Status is active but no end date - count as active
          active++;
        }
      }
      // Priority 3: Check if user has subscription type (even if status is not 'active')
      else {
        final hasSubscriptionType = subscriptionType != null && 
                                     subscriptionType.toString().trim().isNotEmpty &&
                                     (subscriptionType.toString().toLowerCase() == 'monthly' || 
                                      subscriptionType.toString().toLowerCase() == 'yearly');
        
        if (hasSubscriptionType) {
          // User has a subscription (monthly or yearly)
          if (subscriptionEndDate != null) {
            final endDateTime = subscriptionEndDate.toDate();
            if (DateTime.now().isBefore(endDateTime)) {
              // Active subscription
              active++;
            } else {
              // Subscription expired
              expired++;
            }
          } else {
            // Has subscription type but no end date - count as active
            active++;
          }
        }
        // Priority 4: User is on trial (no subscription type)
        else if (status == 'trial') {
          if (trialEndDate != null) {
            final trialEndDateTime = trialEndDate.toDate();
            if (DateTime.now().isAfter(trialEndDateTime)) {
              // Trial expired
              expired++;
            } else {
              // Active trial
              trial++;
            }
          } else {
            // Trial with no end date (shouldn't happen, but count as trial)
            trial++;
          }
        }
      }
    }

    return {
      'total': total,
      'active': active,
      'trial': trial,
      'expired': expired,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => CupertinoPageRoute(
        builder: _buildDashboardContent,
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    // Wait a bit to show refresh animation
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isRefreshing = false);
  }

  Widget _buildDashboardContent(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
      ),
      child: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _subscriptionService.getAllUsersWithSubscriptionsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return _buildLoadingState(context);
            }

            if (snapshot.hasError) {
              return _buildErrorState(context, snapshot.error.toString());
            }

            final allUsers = snapshot.data ?? [];
            final stats = _calculateStatistics(allUsers);

            if (allUsers.isEmpty) {
              return _buildEmptyState(context);
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: _handleRefresh,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Welcome header
                      _buildWelcomeHeader(context),
                      const SizedBox(height: 24),
                      // Overview section
                      _buildSectionLabel(context, 'Overview'),
                      const SizedBox(height: 16),
                      // Statistics cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Total Users',
                              value: stats['total'].toString(),
                              icon: CupertinoIcons.person_2_fill,
                              color: AppColors.info,
                              description: 'All registered users',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Active',
                              value: stats['active'].toString(),
                              icon: CupertinoIcons.check_mark_circled_solid,
                              color: AppColors.success,
                              description: 'Active subscriptions',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Trial',
                              value: stats['trial'].toString(),
                              icon: CupertinoIcons.clock_fill,
                              color: AppColors.warning,
                              description: 'On trial period',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Expired',
                              value: stats['expired'].toString(),
                              icon: CupertinoIcons.exclamationmark_circle_fill,
                              color: AppColors.error,
                              description: 'Expired subscriptions',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSectionLabel(context, 'Quick Actions'),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                context,
                                title: 'Manage Users',
                                subtitle: 'View & manage all users',
                                icon: CupertinoIcons.person_3_fill,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => const UserManagementScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                context,
                                title: 'Subscription Pricing',
                                subtitle: 'Set monthly & yearly prices',
                                icon: CupertinoIcons.money_dollar,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => const SubscriptionPricingScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.chart_bar_alt_fill,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitor your user statistics',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.dynamicTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.dynamicTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.person_2,
                color: AppColors.info,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Users Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.dynamicTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'User statistics will appear here once users start registering.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.dynamicTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.dynamicTextPrimary(context),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicTextPrimary(context),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.dynamicTextPrimary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.dynamicTextSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final primary = AppColors.dynamicPrimary(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.dynamicSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.dynamicBorder(context),
            width: 1,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primary, size: 24),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.dynamicTextPrimary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.dynamicTextSecondary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
