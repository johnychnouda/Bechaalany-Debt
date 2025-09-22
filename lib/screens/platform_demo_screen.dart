import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../constants/platform_theme.dart';
import '../widgets/platform_scaffold.dart';

class PlatformDemoScreen extends StatelessWidget {
  const PlatformDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      title: 'Platform Demo',
      actions: [
        IconButton(
          icon: Icon(
            Platform.isIOS ? CupertinoIcons.info_circle : Icons.info_outline,
            color: PlatformTheme.getPrimary(context),
          ),
          onPressed: () => _showPlatformInfo(context),
        ),
      ],
      children: [
        // Platform Detection Display
        PlatformCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform Detection',
                style: PlatformTheme.getTitleLarge(context),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Platform.isIOS ? CupertinoIcons.device_phone_portrait : Icons.phone_android,
                    color: PlatformTheme.getPrimary(context),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Running on: ${Platform.isIOS ? 'iOS' : 'Android'}',
                    style: PlatformTheme.getBodyLarge(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Platform.isIOS ? CupertinoIcons.paintbrush : Icons.palette,
                    color: PlatformTheme.getSecondary(context),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Theme: ${Platform.isIOS ? 'iOS 18+ Design' : 'Android 16 Material You'}',
                    style: PlatformTheme.getBodyMedium(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Typography Demo
        PlatformCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Typography System',
                style: PlatformTheme.getTitleLarge(context),
              ),
              const SizedBox(height: 16),
              Text(
                'Display Large',
                style: PlatformTheme.getDisplayLarge(context),
              ),
              Text(
                'Display Medium',
                style: PlatformTheme.getDisplayMedium(context),
              ),
              Text(
                'Headline Large',
                style: PlatformTheme.getHeadlineLarge(context),
              ),
              Text(
                'Title Large',
                style: PlatformTheme.getTitleLarge(context),
              ),
              Text(
                'Body Large',
                style: PlatformTheme.getBodyLarge(context),
              ),
              Text(
                'Label Large',
                style: PlatformTheme.getLabelLarge(context),
              ),
            ],
          ),
        ),
        
        // Color Demo
        PlatformCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Color System',
                style: PlatformTheme.getTitleLarge(context),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildColorSwatch(context, 'Primary', PlatformTheme.getPrimary(context)),
                  _buildColorSwatch(context, 'Secondary', PlatformTheme.getSecondary(context)),
                  _buildColorSwatch(context, 'Success', PlatformTheme.getSuccess(context)),
                  _buildColorSwatch(context, 'Warning', PlatformTheme.getWarning(context)),
                  _buildColorSwatch(context, 'Error', PlatformTheme.getError(context)),
                  _buildColorSwatch(context, 'Info', PlatformTheme.getInfo(context)),
                ],
              ),
            ],
          ),
        ),
        
        // Button Demo
        PlatformCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Button Styles',
                style: PlatformTheme.getTitleLarge(context),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  PlatformButton(
                    text: 'Primary',
                    type: ButtonType.primary,
                    onPressed: () => _showSnackBar(context, 'Primary button tapped'),
                  ),
                  PlatformButton(
                    text: 'Secondary',
                    type: ButtonType.secondary,
                    onPressed: () => _showSnackBar(context, 'Secondary button tapped'),
                  ),
                  PlatformButton(
                    text: 'Tertiary',
                    type: ButtonType.tertiary,
                    onPressed: () => _showSnackBar(context, 'Tertiary button tapped'),
                  ),
                  if (Platform.isAndroid)
                    PlatformButton(
                      text: 'Tonal',
                      type: ButtonType.tonal,
                      onPressed: () => _showSnackBar(context, 'Tonal button tapped'),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Input Demo
        PlatformCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Input Fields',
                style: PlatformTheme.getTitleLarge(context),
              ),
              const SizedBox(height: 16),
              PlatformTextField(
                label: 'Sample Input',
                hint: 'Enter some text...',
                helperText: 'This demonstrates platform-specific input styling',
              ),
              const SizedBox(height: 16),
              PlatformTextField(
                label: 'Password Input',
                hint: 'Enter password...',
                obscureText: true,
                helperText: 'Password field with platform-specific styling',
              ),
            ],
          ),
        ),
        
        // Switch Demo
        PlatformCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interactive Elements',
                style: PlatformTheme.getTitleLarge(context),
              ),
              const SizedBox(height: 16),
              PlatformSwitch(
                label: 'Enable notifications',
                value: true,
                onChanged: (value) => _showSnackBar(context, 'Notifications ${value ? 'enabled' : 'disabled'}'),
              ),
              const SizedBox(height: 16),
              PlatformSwitch(
                label: 'Dark mode preference',
                value: false,
                onChanged: (value) => _showSnackBar(context, 'Dark mode ${value ? 'enabled' : 'disabled'}'),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }
  
  Widget _buildColorSwatch(BuildContext context, String name, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Platform.isIOS ? 12 : 8),
        border: Border.all(
          color: PlatformTheme.getOutline(context),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  void _showPlatformInfo(BuildContext context) {
    final platformInfo = Platform.isIOS 
      ? '''
iOS 18+ Design System
• CupertinoPageScaffold navigation
• iOS typography (San Francisco)
• iOS color palette (#007AFF, #34C759)
• iOS spacing and radius values
• iOS-style buttons and inputs
      '''
      : '''
Android 16 Material You Design System
• Material 3 AppBar and Scaffold
• Roboto typography
• Material You color palette (#6750A4, #625B71)
• Material spacing and radius values
• Material Design buttons and inputs
      ''';
    
    showDialog(
      context: context,
      builder: (context) => PlatformDialog(
        title: 'Platform Information',
        content: platformInfo,
        actions: [
          PlatformButton(
            text: 'OK',
            type: ButtonType.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PlatformTheme.getSurface(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Platform.isIOS ? 12 : 8),
        ),
      ),
    );
  }
}
