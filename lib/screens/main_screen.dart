import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/admin_service.dart';
import '../utils/responsive_layout.dart';
import '../widgets/web_sidebar.dart';
import 'admin/admin_dashboard_screen.dart';
import 'customers_screen.dart';
import 'full_activity_list_screen.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<State<SettingsScreen>> _settingsScreenKey =
      GlobalKey<State<SettingsScreen>>();
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  static const int _activitiesTabIndex = 3;
  static const int _settingsTabIndex = 4;
  static const int _adminTabIndexMobile = 4;
  static const int _adminTabIndexWeb = 5;

  List<Widget> get _mobileScreens {
    if (_isAdmin) {
      return const [
        HomeScreen(),
        CustomersScreen(),
        ProductsScreen(),
        FullActivityListScreen(embeddedInShell: true),
        const AdminDashboardScreen(embeddedInShell: true),
      ];
    }
    return const [
      HomeScreen(),
      CustomersScreen(),
      ProductsScreen(),
      FullActivityListScreen(embeddedInShell: true),
    ];
  }

  List<Widget> get _webScreens {
    if (_isAdmin) {
      return [
        const HomeScreen(),
        const CustomersScreen(),
        const ProductsScreen(),
        const FullActivityListScreen(embeddedInShell: true),
        SettingsScreen(key: _settingsScreenKey, embeddedInShell: true),
        const AdminDashboardScreen(embeddedInShell: true),
      ];
    }
    return [
      const HomeScreen(),
      const CustomersScreen(),
      const ProductsScreen(),
      const FullActivityListScreen(embeddedInShell: true),
      SettingsScreen(key: _settingsScreenKey, embeddedInShell: true),
    ];
  }

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final adminService = AdminService();
    final isAdmin = await adminService.refreshAdminStatus();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
      final maxIndex = isAdmin
          ? (ResponsiveLayout.isWeb ? _adminTabIndexWeb : _adminTabIndexMobile)
          : (ResponsiveLayout.isWeb ? _settingsTabIndex : _activitiesTabIndex);
      if (_currentIndex > maxIndex) {
        _currentIndex = 0;
      }
    });
  }

  bool _useDesktopWebLayout(BuildContext context) =>
      ResponsiveLayout.isDesktopWeb(context);

  void _selectIndex(int index) {
    final useDesktopWeb = _useDesktopWebLayout(context);
    final screenCount =
        (useDesktopWeb ? _webScreens : _mobileScreens).length;
    if (index < 0 || index >= screenCount) return;
    if (_currentIndex == index) return;
    if (useDesktopWeb &&
        _currentIndex == _settingsTabIndex &&
        index != _settingsTabIndex) {
      SettingsScreen.popInnerToRootFromHost(_settingsScreenKey);
    }
    setState(() => _currentIndex = index);
  }

  List<WebSidebarNavItem> _sidebarItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <WebSidebarNavItem>[
      WebSidebarNavItem(
        index: 0,
        icon: Icons.dashboard_rounded,
        label: l10n.navDashboard,
      ),
      WebSidebarNavItem(
        index: 1,
        icon: Icons.people_rounded,
        label: l10n.navCustomers,
      ),
      WebSidebarNavItem(
        index: 2,
        icon: Icons.inventory_2_rounded,
        label: l10n.navProducts,
      ),
      WebSidebarNavItem(
        index: _activitiesTabIndex,
        icon: Icons.history_rounded,
        label: l10n.navActivities,
      ),
      WebSidebarNavItem(
        index: _settingsTabIndex,
        icon: Icons.settings_outlined,
        label: l10n.navSettings,
      ),
    ];
    if (_isAdmin) {
      items.add(
        WebSidebarNavItem(
          index: _adminTabIndexWeb,
          icon: Icons.admin_panel_settings,
          label: l10n.navAdmin,
        ),
      );
    }
    return items;
  }

  Widget _buildNavigationItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectIndex(index),
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

  Widget _buildMobileBottomNav() {
    return Container(
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
          child: Row(
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
                    _buildNavigationItem(
                      index: _activitiesTabIndex,
                      icon: Icons.history_rounded,
                      label: AppLocalizations.of(context)!.navActivities,
                      isSelected: _currentIndex == _activitiesTabIndex,
                    ),
                    if (_isAdmin)
                      _buildNavigationItem(
                        index: _adminTabIndexMobile,
                        icon: Icons.admin_panel_settings,
                        label: AppLocalizations.of(context)!.navAdmin,
                        isSelected: _currentIndex == _adminTabIndexMobile,
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildIndexedTabBody(List<Widget> screens, {required bool wrapTabsInNavigator}) {
    final index = screens.isEmpty
        ? 0
        : _currentIndex.clamp(0, screens.length - 1);
    return IndexedStack(
      index: index,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < screens.length; i++)
          wrapTabsInNavigator
              ? _WebTabNavigator(
                  key: ValueKey('web-tab-$i'),
                  root: screens[i],
                )
              : screens[i],
      ],
    );
  }

  Widget _buildWebDesktopShell(List<Widget> screens) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WebSidebar(
          selectedIndex: _currentIndex,
          items: _sidebarItems(context),
          onIndexSelected: _selectIndex,
        ),
        Expanded(
          child: _buildIndexedTabBody(screens, wrapTabsInNavigator: true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final useDesktopWeb = _useDesktopWebLayout(context);
    final screens = useDesktopWeb ? _webScreens : _mobileScreens;

    return Scaffold(
      key: const Key('main_screen'),
      backgroundColor: AppColors.dynamicBackground(context),
      body: useDesktopWeb
          ? _buildWebDesktopShell(screens)
          : _buildIndexedTabBody(_mobileScreens, wrapTabsInNavigator: false),
      bottomNavigationBar:
          useDesktopWeb ? null : _buildMobileBottomNav(),
    );
  }
}

/// One navigator per web tab so [SettingsNavigation.pushSubpage] keeps the sidebar visible.
class _WebTabNavigator extends StatelessWidget {
  final Widget root;

  const _WebTabNavigator({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => root,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
