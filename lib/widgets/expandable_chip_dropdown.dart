import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ExpandableChipDropdown<T> extends StatefulWidget {
  final String label;
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
    required this.label,
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

class _ExpandableChipDropdownState<T> extends State<ExpandableChipDropdown<T>> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main chip
        GestureDetector(
          onTap: widget.enabled ? () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            });
          } : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? Colors.grey[50],
              border: Border.all(
                color: widget.borderColor ?? Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(12),
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
                        : (widget.placeholder ?? widget.label),
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.value != null ? Colors.black : Colors.grey[600],
                      fontWeight: widget.value != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (widget.enabled)
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
        
        // Expandable options
        SizeTransition(
          sizeFactor: _animation,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26), // 0.1 * 255
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
                      _animationController.reverse();
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
                    _animationController.reverse();
                  },
                )),
              ],
            ),
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
          color: isSelected ? AppColors.primary.withAlpha(26) : Colors.transparent, // 0.1 * 255
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? AppColors.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
} 