import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../utils/logo_utils.dart';
import 'profit_loss_widget.dart';
import 'customer_payment_history_widget.dart';
import 'total_debtors_widget.dart';
import 'top_debtors_widget.dart';
import 'recent_activity_widget.dart';
import 'recent_debts_list.dart';
import '../screens/settings_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomizableDashboardWidget extends StatefulWidget {
  const CustomizableDashboardWidget({super.key});

  @override
  State<CustomizableDashboardWidget> createState() => _CustomizableDashboardWidgetState();
}

class _CustomizableDashboardWidgetState extends State<CustomizableDashboardWidget> {
  List<DashboardWidget> _availableWidgets = [];
  List<DashboardWidget> _enabledWidgets = [];
  bool _isEditMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWidgets();
    _loadWidgetPreferences();
  }

  void _initializeWidgets() {
    _availableWidgets = [
      DashboardWidget(
        id: 'profit_loss',
        title: 'Profit/Loss Analysis',
        icon: Icons.trending_up,
        color: AppColors.success,
        widget: const ProfitLossWidget(),
        isEnabled: true,
      ),
      DashboardWidget(
        id: 'payment_history',
        title: 'Payment History',
        icon: Icons.history,
        color: AppColors.secondary,
        widget: const CustomerPaymentHistoryWidget(),
        isEnabled: true,
      ),
      DashboardWidget(
        id: 'total_debtors',
        title: 'Total Debtors',
        icon: Icons.people,
        color: AppColors.primary,
        widget: const TotalDebtorsWidget(),
        isEnabled: true,
      ),
      DashboardWidget(
        id: 'top_debtors',
        title: 'Top Debtors',
        icon: Icons.people,
        color: AppColors.error,
        widget: const TopDebtorsWidget(),
        isEnabled: true,
      ),
      DashboardWidget(
        id: 'recent_activity',
        title: 'Recent Activity',
        icon: Icons.access_time,
        color: AppColors.secondary,
        widget: const RecentActivityWidget(),
        isEnabled: true,
      ),
      DashboardWidget(
        id: 'recent_debts',
        title: 'Recent Debts',
        icon: Icons.account_balance_wallet,
        color: AppColors.primary,
        widget: const RecentDebtsList(),
        isEnabled: true,
      ),
    ];
  }

  Future<void> _loadWidgetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabledWidgetsJson = prefs.getString('enabled_widgets');
      
      if (enabledWidgetsJson != null) {
        final enabledIds = List<String>.from(jsonDecode(enabledWidgetsJson));
        // Filter out any old 'quick_actions' widget that might still be in preferences
        final filteredIds = enabledIds.where((id) => id != 'quick_actions').toList();
        
        // Check if total_debtors is missing and add it if needed
        if (!filteredIds.contains('total_debtors')) {
          filteredIds.add('total_debtors');
          await prefs.setString('enabled_widgets', jsonEncode(filteredIds));
        }
        
        _enabledWidgets = _availableWidgets
            .where((widget) => filteredIds.contains(widget.id))
            .toList();
        
        // If we filtered out quick_actions, update the preferences
        if (filteredIds.length != enabledIds.length) {
          await prefs.setString('enabled_widgets', jsonEncode(filteredIds));
        }
      } else {
        // Default enabled widgets - include total_debtors in the first 6
        final defaultWidgetIds = [
          'profit_loss',
          'payment_history', 
          'total_debtors',
          'top_debtors',
          'recent_activity',
          'recent_debts',
        ];
        
        _enabledWidgets = _availableWidgets
            .where((widget) => defaultWidgetIds.contains(widget.id))
            .toList();
      }
    } catch (e) {
      // Fallback to default widgets
      final defaultWidgetIds = [
        'profit_loss',
        'payment_history', 
        'total_debtors',
        'top_debtors',
        'recent_activity',
        'recent_debts',
      ];
      
      _enabledWidgets = _availableWidgets
          .where((widget) => defaultWidgetIds.contains(widget.id))
          .toList();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveWidgetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabledIds = _enabledWidgets.map((widget) => widget.id).toList();
      await prefs.setString('enabled_widgets', jsonEncode(enabledIds));
    } catch (e) {
      debugPrint('Error saving widget preferences: $e');
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _toggleWidget(String widgetId) {
    setState(() {
      final widget = _availableWidgets.firstWhere((w) => w.id == widgetId);
      final isEnabled = _enabledWidgets.any((w) => w.id == widgetId);
      
      if (isEnabled) {
        _enabledWidgets.removeWhere((w) => w.id == widgetId);
      } else {
        _enabledWidgets.add(widget);
      }
    });
    
    _saveWidgetPreferences();
  }

  void _reorderWidgets(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
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
    final padding = 20.0;
    final spacing = 12.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          LogoUtils.buildLogoWithBackground(
            context: context,
            width: 24,
            height: 24,
            borderRadius: 12,
            padding: EdgeInsets.all(spacing),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: AppTheme.title3.copyWith(
                    color: AppColors.dynamicTextPrimary(context),
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Welcome back',
                  style: AppTheme.footnote.copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (appState.isSyncing)
            Container(
              padding: EdgeInsets.all(spacing * 0.5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
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

  Widget _buildEditMode() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _enabledWidgets.length,
      onReorder: _reorderWidgets,
      itemBuilder: (context, index) {
        final widget = _enabledWidgets[index];
        return Container(
          key: ValueKey(widget.id),
          margin: const EdgeInsets.only(bottom: 16),
          child: Stack(
            children: [
              widget.widget,
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWidgetPreferences() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Widget Preferences',
                    style: AppTheme.title3.copyWith(
                      color: AppColors.dynamicTextPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _availableWidgets.length,
                itemBuilder: (context, index) {
                  final widget = _availableWidgets[index];
                  final isEnabled = _enabledWidgets.any((w) => w.id == widget.id);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isEnabled 
                          ? widget.color.withOpacity(0.1)
                          : AppColors.dynamicSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isEnabled 
                            ? widget.color.withOpacity(0.3)
                            : AppColors.dynamicTextSecondary(context).withOpacity(0.2),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        widget.title,
                        style: AppTheme.title3.copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Switch(
                        value: isEnabled,
                        onChanged: (value) => _toggleWidget(widget.id),
                        activeColor: widget.color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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