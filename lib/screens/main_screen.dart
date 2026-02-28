import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/admin_service.dart';
import 'home_screen.dart';
import 'customers_screen.dart';
import 'products_screen.dart';
import 'full_activity_list_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  final List<Widget> _regularScreens = [
    const HomeScreen(),
    const CustomersScreen(),
    const ProductsScreen(),
  ];

  List<Widget> get _screens {
    if (_isAdmin) {
      return [
        ..._regularScreens,
        const AdminDashboardScreen(),
      ];
    }
    return _regularScreens;
  }

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final adminService = AdminService();
    // Force refresh to get latest admin status from Firestore
    final isAdmin = await adminService.refreshAdminStatus();
    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
    });
  }

  Widget _buildNavigationItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? AppColors.dynamicPrimary(context).withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected 
                  ? AppColors.dynamicPrimary(context)
                  : AppColors.dynamicTextSecondary(context),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected 
                    ? AppColors.dynamicPrimary(context)
                    : AppColors.dynamicTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesNavigationItem() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FullActivityListScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 24,
              color: AppColors.dynamicTextSecondary(context),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.navActivities,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.dynamicTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: const Key('main_screen'),
        backgroundColor: AppColors.dynamicBackground(context),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
          // Use lazy loading - only build visible screen initially
          sizing: StackFit.expand,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            border: Border(
              top: BorderSide(
                color: AppColors.dynamicBorder(context),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _isCheckingAdmin
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavigationItem(
                          index: 0,
                          icon: Icons.dashboard_rounded,
                          label: AppLocalizations.of(context)!.navDashboard,
                          isSelected: _currentIndex == 0,
                        ),
                        _buildNavigationItem(
                          index: 1,
                          icon: Icons.people_rounded,
                          label: AppLocalizations.of(context)!.navCustomers,
                          isSelected: _currentIndex == 1,
                        ),
                        _buildNavigationItem(
                          index: 2,
                          icon: Icons.inventory_2_rounded,
                          label: AppLocalizations.of(context)!.navProducts,
                          isSelected: _currentIndex == 2,
                        ),
                        _buildActivitiesNavigationItem(),
                        if (_isAdmin)
                          _buildNavigationItem(
                            index: 3,
                            icon: Icons.admin_panel_settings,
                            label: AppLocalizations.of(context)!.navAdmin,
                            isSelected: _currentIndex == 3,
                          ),
                      ],
                    ),
            ),
          ),
        ),
    );
  }
}
