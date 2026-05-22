import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_layout.dart';

/// Barcode text field with find and optional camera scan (mobile).
class BarcodeEntryRow extends StatelessWidget {
  const BarcodeEntryRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.notFound,
    required this.onFind,
    this.onScan,
    this.onChanged,
    this.showWebScannerHint = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool notFound;
  final VoidCallback onFind;
  final VoidCallback? onScan;
  final VoidCallback? onChanged;
  final bool showWebScannerHint;

  static const double _actionSize = 56;
  static const double _actionIconSize = 26;

  OutlineInputBorder _outlineBorder(BuildContext context, {bool focused = false}) {
    final errorColor = AppColors.error;
    final normalColor = AppColors.dynamicBorder(context);
    final color = notFound
        ? errorColor
        : (focused ? AppColors.dynamicPrimary(context) : normalColor);
    final width = notFound || focused ? 2.0 : 1.0;

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon, size: _actionIconSize),
      tooltip: tooltip,
      padding: const EdgeInsets.all(14),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.dynamicPrimary(context),
        foregroundColor: Colors.white,
        minimumSize: const Size(_actionSize, _actionSize),
        fixedSize: const Size(_actionSize, _actionSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWeb = ResponsiveLayout.isWeb;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.barcodeLabel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        const SizedBox(height: 10),
        if (isWeb && showWebScannerHint)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.useBarcodeScannerOrType,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.dynamicTextSecondary(context),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: notFound ? 8 : 0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: l10n.barcodeHint,
                        enabledBorder: _outlineBorder(context),
                        focusedBorder: _outlineBorder(context, focused: true),
                        errorBorder: _outlineBorder(context),
                        focusedErrorBorder:
                            _outlineBorder(context, focused: true),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.search,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => onChanged?.call(),
                      onSubmitted: (_) => onFind(),
                    ),
                    if (notFound)
                      Positioned(
                        left: 12,
                        top: 0,
                        child: Transform.translate(
                          offset: const Offset(0, -10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            color: AppColors.dynamicSurface(context),
                            child: Text(
                              l10n.productNotFoundForBarcode,
                              style: TextStyle(
                                color: AppColors.error,
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
              ),
            ),
            const SizedBox(width: 12),
            _actionButton(
              context: context,
              icon: Icons.search,
              tooltip: l10n.findProductByBarcode,
              onPressed: onFind,
            ),
            if (onScan != null) ...[
              const SizedBox(width: 12),
              _actionButton(
                context: context,
                icon: Icons.qr_code_scanner,
                tooltip: l10n.scanBarcode,
                onPressed: onScan!,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
