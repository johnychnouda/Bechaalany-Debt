import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
// import '../services/data_export_import_service.dart'; // Removed unused import
import '../services/notification_service.dart';
import '../models/customer.dart';
import '../models/debt.dart';

class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> {
  // final DataExportImportService _importService = DataExportImportService(); // Removed unused field
  final NotificationService _notificationService = NotificationService();
  bool _isImporting = false;
  Map<String, dynamic>? _importPreview;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Import Data',
          style: AppTheme.getDynamicTitle3(context).copyWith(
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 16),
              
              // Import Options Section
              _buildImportOptionsSection(),
              
              const SizedBox(height: 24),
              
              // Import Button
              _buildImportButton(),
              
              const SizedBox(height: 24),
              
              // Preview Section (if data is loaded)
              if (_importPreview != null) _buildPreviewSection(),
              
              const SizedBox(height: 24),
              
              // Help Text
              _buildHelpText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportOptionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _buildImportOption(
            'Excel Format',
            'Import from Excel spreadsheet',
            CupertinoIcons.table,
            'Native Excel format support',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildImportOption(String title, String subtitle, IconData icon, String description, bool available) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dynamicBorder(context),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: available 
                  ? AppColors.dynamicPrimary(context).withAlpha(26)
                  : AppColors.dynamicTextSecondary(context).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon, 
                color: available 
                  ? AppColors.dynamicPrimary(context)
                  : AppColors.dynamicTextSecondary(context),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.getDynamicBody(context).copyWith(
                      color: available 
                        ? AppColors.dynamicTextPrimary(context)
                        : AppColors.dynamicTextSecondary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.getDynamicFootnote(context).copyWith(
                      color: AppColors.dynamicTextSecondary(context),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.getDynamicCaption1(context).copyWith(
                      color: AppColors.dynamicTextSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (!available)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dynamicTextSecondary(context).withAlpha(26),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Coming Soon',
                  style: AppTheme.getDynamicCaption1(context).copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    return Container(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: AppColors.dynamicPrimary(context),
        borderRadius: BorderRadius.circular(12),
        onPressed: _isImporting ? null : _importData,
        child: _isImporting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(color: AppColors.dynamicSurface(context)),
                const SizedBox(width: 8),
                Text(
                  'Importing...',
                  style: AppTheme.getDynamicBody(context).copyWith(
                    color: AppColors.dynamicSurface(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ],
            )
          : Text(
              'Select Excel File to Import',
              style: AppTheme.getDynamicBody(context).copyWith(
                color: AppColors.dynamicSurface(context),
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    // final customers = _importPreview!['customers'] as List<Customer>; // Removed unused variable
    // final debts = _importPreview!['debts'] as List<Debt>; // Removed unused variable
    final totalCustomers = _importPreview!['totalCustomers'] as int;
    final totalDebts = _importPreview!['totalDebts'] as int;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _buildPreviewRow(
            'Customers',
            '$totalCustomers customers found',
            CupertinoIcons.person_2,
            AppColors.dynamicSuccess(context),
          ),
          _buildPreviewRow(
            'Debts',
            '$totalDebts debts found',
            CupertinoIcons.money_dollar,
            AppColors.dynamicPrimary(context),
            showBorder: false,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: AppColors.dynamicSuccess(context),
              borderRadius: BorderRadius.circular(8),
              onPressed: _confirmImport,
              child: Text(
                'Confirm Import',
                style: AppTheme.getDynamicBody(context).copyWith(
                  color: AppColors.dynamicSurface(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String title, String subtitle, IconData icon, Color iconColor, {bool showBorder = true}) {
    return Container(
      decoration: showBorder ? BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dynamicBorder(context),
            width: 0.5,
          ),
        ),
      ) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.getDynamicBody(context).copyWith(
                      color: AppColors.dynamicTextPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.getDynamicFootnote(context).copyWith(
                      color: AppColors.dynamicTextSecondary(context),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dynamicPrimary(context).withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            color: AppColors.dynamicPrimary(context),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Import will add new customers and debts to your existing data. Duplicate entries will be skipped. Make sure your Excel file has the correct format.',
              style: AppTheme.getDynamicCaption1(context).copyWith(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
    });

    try {
      // For now, show a message that import is not fully implemented
      await _notificationService.showInfoNotification(
        title: 'Import Feature',
        body: 'Import functionality is coming soon. For now, you can export your data and manually import it using the Files app.',
      );
      
      // TODO: Implement actual file picker and import functionality
      // Import functionality will be implemented in future updates

    } catch (e) {
      await _notificationService.showErrorNotification(
        title: 'Import Failed',
        body: 'Failed to import data: $e',
      );
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _confirmImport() async {
    if (_importPreview == null) return;

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final customers = _importPreview!['customers'] as List<Customer>;
      final debts = _importPreview!['debts'] as List<Debt>;

      // Add customers
      for (final customer in customers) {
        await appState.addCustomer(customer);
      }

      // Add debts
      for (final debt in debts) {
        await appState.addDebt(debt);
      }

      await _notificationService.showSuccessNotification(
        title: 'Import Successful',
        body: 'Data has been imported successfully.',
      );

      Navigator.of(context).pop();

    } catch (e) {
      await _notificationService.showErrorNotification(
        title: 'Import Failed',
        body: 'Failed to import data: $e',
      );
    }
  }
} 