import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/platform_theme.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class PlatformScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  
  const PlatformScaffold({
    super.key,
    required this.title,
    required this.children,
    this.floatingActionButton,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor ?? AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          title,
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
        leading: leading,
        trailing: actions != null 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            )
          : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (bottom != null) bottom!,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlatformAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  
  const PlatformAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });
  
  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      middle: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? AppColors.dynamicTextPrimary(context),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
      ),
      backgroundColor: backgroundColor ?? AppColors.dynamicSurface(context),
      border: null,
      leading: leading,
      trailing: actions != null 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: actions!,
          )
        : null,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class PlatformCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  
  const PlatformCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: color ?? AppColors.dynamicSurface(context),
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radius16),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radius16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class PlatformButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  
  const PlatformButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return _buildIOSButton(context);
  }
  
  Widget _buildIOSButton(BuildContext context) {
    final buttonStyle = _getIOSButtonStyle(context);
    
    return CupertinoButton(
      onPressed: isLoading ? null : onPressed,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: buttonStyle.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: buttonStyle.borderColor != null 
            ? Border.all(color: buttonStyle.borderColor!)
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CupertinoActivityIndicator(),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 16,
                color: buttonStyle.textColor,
              ),
            if (isLoading || icon != null) const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: buttonStyle.textColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.41,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CupertinoActivityIndicator(),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16),
          const SizedBox(width: 8),
        ],
        Text(text),
      ],
    );
  }
  
  _IOSButtonStyle _getIOSButtonStyle(BuildContext context) {
    switch (type) {
      case ButtonType.primary:
        return _IOSButtonStyle(
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
        );
      case ButtonType.secondary:
        return _IOSButtonStyle(
          backgroundColor: Colors.transparent,
          textColor: AppColors.primary,
          borderColor: AppColors.primary,
        );
      case ButtonType.tertiary:
        return _IOSButtonStyle(
          backgroundColor: Colors.transparent,
          textColor: AppColors.primary,
        );
      case ButtonType.tonal:
        return _IOSButtonStyle(
          backgroundColor: AppColors.primaryLight,
          textColor: AppColors.primaryDark,
        );
    }
  }
}

enum ButtonType {
  primary,
  secondary,
  tertiary,
  tonal,
}

class _IOSButtonStyle {
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  
  _IOSButtonStyle({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });
}

class PlatformTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  
  const PlatformTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.41,
            ),
          ),
          const SizedBox(height: 8),
        ],
        CupertinoTextField(
          controller: controller,
          placeholder: hint,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            border: Border.all(
              color: errorText != null 
                ? AppColors.error 
                : AppColors.dynamicBorder(context),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radius12),
          ),
          prefix: prefixIcon,
          suffix: suffixIcon,
        ),
        if (helperText != null || errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText ?? helperText!,
            style: TextStyle(
              color: errorText != null 
                ? AppColors.error 
                : AppColors.dynamicTextSecondary(context),
              fontSize: 13,
              fontWeight: FontWeight.normal,
              letterSpacing: -0.08,
            ),
          ),
        ],
      ],
    );
  }
}

class PlatformSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  
  const PlatformSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (label != null) ...[
          Expanded(
            child: Text(
              label!,
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 17,
                fontWeight: FontWeight.normal,
                letterSpacing: -0.41,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}

class PlatformDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget> actions;
  final Widget? icon;
  
  const PlatformDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: actions,
    );
  }
}
