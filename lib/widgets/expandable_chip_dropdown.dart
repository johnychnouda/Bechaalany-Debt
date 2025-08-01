import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ExpandableChipDropdown<T> extends StatefulWidget {
  final String? label;
  final T? value;
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(T?) onChanged;
  final bool enabled;
  final String? placeholder;
  final Widget? prefixIcon;
  final Color? backgroundColor;
  final Color? borderColor;

  const ExpandableChipDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.itemToString,
    required this.onChanged,
    this.enabled = true,
    this.placeholder,
    this.prefixIcon,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<ExpandableChipDropdown<T>> createState() => _ExpandableChipDropdownState<T>();
}

class _ExpandableChipDropdownState<T> extends State<ExpandableChipDropdown<T>> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.dynamicTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: widget.enabled ? () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          } : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? AppColors.dynamicSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.borderColor ?? AppColors.dynamicBorder(context),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.value != null 
                        ? widget.itemToString(widget.value as T)
                        : (widget.placeholder ?? widget.label ?? 'Select'),
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.value != null 
                          ? AppColors.dynamicTextPrimary(context) 
                          : AppColors.dynamicTextSecondary(context),
                      fontWeight: widget.value != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (widget.enabled)
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
              ],
            ),
          ),
        ),
        if (_isExpanded && widget.items.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.dynamicBorder(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // None option (if value is nullable and items are empty)
                if (widget.value == null && widget.items.isEmpty) ...[
                  _buildOptionTile(
                    widget.placeholder ?? 'None',
                    null,
                    widget.value == null,
                    (value) {
                      widget.onChanged(null);
                      setState(() {
                        _isExpanded = false;
                      });
                    },
                  ),
                ],
                // Item options
                ...widget.items.map((item) => _buildOptionTile(
                  widget.itemToString(item),
                  item,
                  widget.value == item,
                  (value) {
                    widget.onChanged(value);
                    setState(() {
                      _isExpanded = false;
                    });
                  },
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOptionTile(String title, T? value, bool isSelected, Function(T?) onTap) {
    return InkWell(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.dynamicPrimary(context).withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected 
                      ? AppColors.dynamicPrimary(context) 
                      : AppColors.dynamicTextPrimary(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.close,
                color: AppColors.dynamicError(context),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
} 