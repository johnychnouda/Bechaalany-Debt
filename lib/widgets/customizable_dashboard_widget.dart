import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../utils/logo_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/settings_screen.dart';

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
        id: 'top_debtors',
        title: 'Top Debtors',
        icon: Icons.people,
        color: AppColors.warning,
        widget: const TopDebtorsWidget(),
        isEnabled: true,
      ),
      DashboardWidget(
        id: 'profit_loss',
        title: 'Financial Analysis',
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
    // Default order: 1- Revenue/Debts Analysis, 2- Total Customers and Debtors, 3- Top Debtors
    final defaultOrder = ['profit_loss', 'total_debtors', 'top_debtors'];
    
    final orderedWidgets = <DashboardWidget>[];
    
    // Add widgets in the default order
    for (final widgetId in defaultOrder) {
      final widget = _availableWidgets.firstWhere((w) => w.id == widgetId);
      orderedWidgets.add(widget);
    }
    
    return orderedWidgets;
  }

  void _loadWidgetPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .get();
        
        List<String> enabledWidgetIds = [];
        if (doc.exists) {
          enabledWidgetIds = List<String>.from(doc.data()!['dashboard_widget_order'] ?? []);
        }
        
        // Force remove the activity widget from preferences if it exists
        final filteredWidgetIds = enabledWidgetIds.where((id) => id != 'weekly_activity').toList();
        if (filteredWidgetIds.length != enabledWidgetIds.length) {
          // Save the filtered preferences to remove the activity widget
          await FirebaseFirestore.instance
              .collection('user_settings')
              .doc(user.uid)
              .set({
            'dashboard_widget_order': filteredWidgetIds,
          }, SetOptions(merge: true));
        }
        
          if (filteredWidgetIds.isNotEmpty) {
            // User has custom preferences - load them
            final orderedWidgets = <DashboardWidget>[];
            final availableWidgetIds = _availableWidgets.map((w) => w.id).toSet();
            
            for (final widgetId in filteredWidgetIds) {
              if (availableWidgetIds.contains(widgetId) && widgetId != 'weekly_activity') {
                final widget = _availableWidgets.firstWhere((w) => w.id == widgetId);
                orderedWidgets.add(widget);
              }
            }
            
            // Add any remaining widgets that weren't in the saved order (except activity widget)
            for (final widget in _availableWidgets) {
              if (!orderedWidgets.any((w) => w.id == widget.id) && widget.id != 'weekly_activity') {
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
        }
      } catch (e) {
        // Error loading preferences, use defaults
        setState(() {
          _enabledWidgets = _getDefaultWidgetOrder();
          _isLoading = false;
        });
      }
    }

  void _saveWidgetPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final widgetIds = _enabledWidgets.map((w) => w.id).toList();
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .set({
          'dashboard_widget_order': widgetIds,
        }, SetOptions(merge: true));
      }
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
      padding: const EdgeInsets.all(16), // Increased padding for larger elements
      child: Row(
        children: [
          // Original clean logo design - matching iOS app
          LogoUtils.buildLogo(
            context: context,
            width: 56, // Increased from 40
            height: 56, // Increased from 40
            // Removed placeholder to let actual logo show
          ),
          const SizedBox(width: 12), // Increased spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bechaalany Connect',
                  style: AppTheme.getDynamicTitle3(context).copyWith(
                    color: AppColors.dynamicTextPrimary(context),
                    fontSize: 22, // Increased from 16
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Welcome back',
                  style: AppTheme.getDynamicFootnote(context).copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                    fontSize: 16, // Increased from 12
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (appState.isSyncing)
            Container(
              padding: const EdgeInsets.all(6), // Increased padding
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8), // Increased border radius
              ),
              child: const SizedBox(
                width: 16, // Increased from 12
                height: 16, // Increased from 12
                child: CircularProgressIndicator(
                  strokeWidth: 2, // Increased from 1.5
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
              size: 26, // Increased from 18
            ),
            padding: const EdgeInsets.all(8), // Increased padding
            constraints: const BoxConstraints(
              minWidth: 44, // Increased from 32
              minHeight: 44, // Increased from 32
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalMode() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12), // Further reduced from 16
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