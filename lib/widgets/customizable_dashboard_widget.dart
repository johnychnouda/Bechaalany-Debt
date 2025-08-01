import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../utils/logo_utils.dart';

import '../screens/settings_screen.dart';

import 'activity_widget.dart';
import 'top_debtors_widget.dart';
import 'profit_loss_widget.dart';
import 'total_debtors_widget.dart';

class CustomizableDashboardWidget extends StatefulWidget {
  const CustomizableDashboardWidget({super.key});

  @override
  State<CustomizableDashboardWidget> createState() => _CustomizableDashboardWidgetState();
}

class _CustomizableDashboardWidgetState extends State<CustomizableDashboardWidget> {
  List<DashboardWidget> _availableWidgets = [];
  List<DashboardWidget> _enabledWidgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWidgets();
    _loadWidgetPreferences();
    
    // Ensure preferences are saved after a short delay to handle any initialization issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_enabledWidgets.isNotEmpty) {
          _saveWidgetPreferences();
        }
      });
    });
  }

  void _initializeWidgets() {
    _availableWidgets = [
      DashboardWidget(
        id: 'weekly_activity',
        title: 'Activity Widget',
        icon: Icons.trending_up,
        color: AppColors.success,
        widget: const ActivityWidget(),
        isEnabled: true,
      ),
      DashboardWidget(
        id: 'top_debtors',
        title: 'Top Debtors',
        icon: Icons.people,
        color: AppColors.warning,
        widget: const TopDebtorsWidget(),
        isEnabled: true,
      ),
      DashboardWidget(
        id: 'profit_loss',
        title: 'Revenue/Debts Analysis',
        icon: Icons.analytics,
        color: AppColors.primary,
        widget: const ProfitLossWidget(),
        isEnabled: true,
      ),
      DashboardWidget(
        id: 'total_debtors',
        title: 'Total Customers and Debtors',
        icon: Icons.group,
        color: AppColors.secondary,
        widget: const TotalDebtorsWidget(),
        isEnabled: true,
      ),
    ];

    // Set default order for first-time installations
    _enabledWidgets = _getDefaultWidgetOrder();
  }

  // Method to get the default widget order for first-time installations
  List<DashboardWidget> _getDefaultWidgetOrder() {
    // Default order: 1- Revenue/Debts Analysis, 2- Activity Widget, 3- Total Customers and Debtors, 4- Top Debtors
    final defaultOrder = ['profit_loss', 'weekly_activity', 'total_debtors', 'top_debtors'];
    
    final orderedWidgets = <DashboardWidget>[];
    
    // Add widgets in the default order
    for (final widgetId in defaultOrder) {
      final widget = _availableWidgets.firstWhere((w) => w.id == widgetId);
      orderedWidgets.add(widget);
    }
    
    return orderedWidgets;
  }

  void _loadWidgetPreferences() {
    SharedPreferences.getInstance().then((prefs) {
      final enabledWidgetIds = prefs.getStringList('dashboard_widget_order') ?? [];
      
      if (enabledWidgetIds.isNotEmpty) {
        // User has custom preferences - load them
        final orderedWidgets = <DashboardWidget>[];
        final availableWidgetIds = _availableWidgets.map((w) => w.id).toSet();
        
        for (final widgetId in enabledWidgetIds) {
          if (availableWidgetIds.contains(widgetId)) {
            final widget = _availableWidgets.firstWhere((w) => w.id == widgetId);
            orderedWidgets.add(widget);
          }
        }
        
        // Add any remaining widgets that weren't in the saved order
        for (final widget in _availableWidgets) {
          if (!orderedWidgets.any((w) => w.id == widget.id)) {
            orderedWidgets.add(widget);
          }
        }
        
        setState(() {
          _enabledWidgets = orderedWidgets;
          _isLoading = false;
        });
      } else {
        // First time installation - use default order and save it
        setState(() {
          _enabledWidgets = _getDefaultWidgetOrder();
          _isLoading = false;
        });
        
        // Save the default order so it's preserved
        _saveWidgetPreferences();
      }
    });
  }

  void _saveWidgetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final widgetIds = _enabledWidgets.map((w) => w.id).toList();
      await prefs.setStringList('dashboard_widget_order', widgetIds);
    } catch (e) {
      // Error saving widget preferences
    }
  }

  void _reorderWidgets(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _enabledWidgets.removeAt(oldIndex);
      _enabledWidgets.insert(newIndex, item);
    });
    
    _saveWidgetPreferences();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          children: [
            // Header with logo, title, and settings
            _buildHeader(appState),
            
            // Widgets
            Expanded(
              child: _buildNormalMode(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          LogoUtils.buildLogo(
            context: context,
            width: 64,
            height: 64,
            placeholder: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.primary,
              size: 64,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bechaalany Connect',
                  style: AppTheme.getDynamicTitle3(context).copyWith(
                    color: AppColors.dynamicTextPrimary(context),
                  ),
                ),
                Text(
                  'Welcome back',
                  style: AppTheme.getDynamicFootnote(context).copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                    fontSize: 14, // Increased from default footnote size
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (appState.isSyncing)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26), // 0.1 * 255
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalMode() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _enabledWidgets.length,
      onReorder: _reorderWidgets,
      itemBuilder: (context, index) {
        final widget = _enabledWidgets[index];
        return Container(
          key: ValueKey(widget.id),
          margin: const EdgeInsets.only(bottom: 16),
          child: widget.widget,
        );
      },
    );
  }
}

class DashboardWidget {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final Widget widget;
  final bool isEnabled;

  DashboardWidget({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.widget,
    required this.isEnabled,
  });
} 