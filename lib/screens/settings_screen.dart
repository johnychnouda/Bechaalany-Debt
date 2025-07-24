import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Force refresh when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bechaalany Debt',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your debts efficiently',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Statistics Section
              const Text(
                'App Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Customers',
                      value: dataService.customers.length.toString(),
                      icon: Icons.people,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Debts',
                      value: dataService.debts.length.toString(),
                      icon: Icons.account_balance_wallet,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Pending Debts',
                      value: dataService.pendingDebtsCount.toString(),
                      icon: Icons.schedule,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Paid Debts',
                      value: dataService.paidDebtsCount.toString(),
                      icon: Icons.check_circle,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Actions Section
              const Text(
                'Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              _ActionCard(
                title: 'Export Data',
                subtitle: 'Export your data to CSV',
                icon: Icons.download,
                onTap: () {
                  // TODO: Implement export functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export functionality coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _ActionCard(
                title: 'Backup Data',
                subtitle: 'Create a backup of your data',
                icon: Icons.backup,
                onTap: () {
                  // TODO: Implement backup functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup functionality coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _ActionCard(
                title: 'Clear All Data',
                subtitle: 'Delete all customers and debts',
                icon: Icons.delete_forever,
                color: AppColors.error,
                onTap: () {
                  _showClearDataDialog(context);
                },
              ),
              
              const SizedBox(height: 24),
              
              // About Section
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              _ActionCard(
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                icon: Icons.privacy_tip,
                onTap: () {
                  // TODO: Show privacy policy
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy policy coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _ActionCard(
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                icon: Icons.description,
                onTap: () {
                  // TODO: Show terms of service
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Terms of service coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _ActionCard(
                title: 'Contact Support',
                subtitle: 'Get help and support',
                icon: Icons.support_agent,
                onTap: () {
                  // TODO: Show contact support
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact support coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'This action will permanently delete all customers and debts. This action cannot be undone. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final dataService = DataService();
                  
                  // Clear all customers
                  for (final customer in dataService.customers) {
                    await dataService.deleteCustomer(customer.id);
                  }
                  
                  // Clear all debts
                  for (final debt in dataService.debts) {
                    await dataService.deleteDebt(debt.id);
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All data cleared successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    // Refresh the screen
                    setState(() {});
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to clear data: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: color ?? AppColors.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
} 