import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/logo_utils.dart';
import '../utils/responsive_layout.dart';

class WebSidebarNavItem {
  final int? index;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const WebSidebarNavItem({
    this.index,
    required this.icon,
    required this.label,
    this.onTap,
  }) : assert(index != null || onTap != null);
}

class WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<WebSidebarNavItem> items;
  final ValueChanged<int> onIndexSelected;

  const WebSidebar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onIndexSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: ResponsiveLayout.sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        border: Border(
          right: BorderSide(
            color: AppColors.dynamicBorder(context),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                LogoUtils.buildLogo(
                  context: context,
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bechaalany',
                        style: AppTheme.getDynamicTitle3(context).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.signInTitleConnect,
                        style: AppTheme.getDynamicFootnote(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final item in items) _buildNavTile(context, item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, WebSidebarNavItem item) {
    final isSelected = item.index != null && item.index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (item.onTap != null) {
              item.onTap!();
            } else if (item.index != null) {
              onIndexSelected(item.index!);
            }
          },
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.dynamicPrimary(context).withValues(alpha: 0.06),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? AppColors.dynamicPrimary(context).withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.dynamicPrimary(context)
                      : AppColors.dynamicTextSecondary(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.dynamicPrimary(context)
                          : AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
