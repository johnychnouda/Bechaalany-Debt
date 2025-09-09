import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/security_wrapper.dart';
import 'home_screen.dart';
import 'customers_screen.dart';
import 'products_screen.dart';
import 'full_activity_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CustomersScreen(),
    const ProductsScreen(),
  ];

  Widget _buildNavigationItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        // Force refresh when switching tabs
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {});
        });
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
              'Activities',
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
    return SecurityWrapper(
      child: Scaffold(
        key: const Key('main_screen'),
        backgroundColor: AppColors.dynamicBackground(context),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
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
          ),
          child: SafeArea(
            child: Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavigationItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: _currentIndex == 0,
                  ),
                  _buildNavigationItem(
                    index: 1,
                    icon: Icons.people_rounded,
                    label: 'Customers',
                    isSelected: _currentIndex == 1,
                  ),
                  _buildNavigationItem(
                    index: 2,
                    icon: Icons.inventory_2_rounded,
                    label: 'Products',
                    isSelected: _currentIndex == 2,
                  ),
                  _buildActivitiesNavigationItem(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
