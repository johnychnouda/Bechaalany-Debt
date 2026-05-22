import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Text field with optional red border and error label on the top-left border line.
class BorderErrorTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? borderError;
  final String? label;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final void Function(String)? onChanged;

  const BorderErrorTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.borderError,
    this.label,
    this.prefixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
  });

  static OutlineInputBorder outlineBorder(
    BuildContext context, {
    required bool hasBorderError,
    bool focused = false,
  }) {
    final errorColor = AppColors.dynamicError(context);
    final normalColor = AppColors.dynamicBorder(context);
    final color = hasBorderError
        ? errorColor
        : (focused ? AppColors.dynamicPrimary(context) : normalColor);
    final width = hasBorderError || focused ? 2.0 : 1.0;

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBorderError = borderError != null && borderError!.isNotEmpty;

    final field = Padding(
      padding: EdgeInsets.only(top: hasBorderError ? 8 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextFormField(
            controller: controller,
            enabled: enabled,
            autofocus: autofocus,
            textCapitalization: textCapitalization,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: AppColors.dynamicTextSecondary(context)),
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(
                      prefixIcon,
                      color: hasBorderError
                          ? AppColors.dynamicError(context)
                          : AppColors.dynamicTextSecondary(context),
                    ),
              filled: true,
              fillColor: AppColors.dynamicSurface(context),
              border: outlineBorder(context, hasBorderError: hasBorderError),
              enabledBorder: outlineBorder(context, hasBorderError: hasBorderError),
              focusedBorder: outlineBorder(
                context,
                hasBorderError: hasBorderError,
                focused: true,
              ),
              errorBorder: outlineBorder(context, hasBorderError: hasBorderError),
              focusedErrorBorder: outlineBorder(
                context,
                hasBorderError: hasBorderError,
                focused: true,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: prefixIcon == null ? 14 : 16,
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
          ),
          if (hasBorderError)
            Positioned(
              left: 12,
              top: 0,
              child: Transform.translate(
                offset: const Offset(0, -10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  color: AppColors.dynamicSurface(context),
                  child: Text(
                    borderError!,
                    style: TextStyle(
                      color: AppColors.dynamicError(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (label == null) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}
