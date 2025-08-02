import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../services/data_export_import_service.dart';
import '../services/notification_service.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final DataExportImportService _exportService = DataExportImportService();
  final NotificationService _notificationService = NotificationService();
  bool _isExporting = false;
  String? _exportedFilePath;
  String _selectedFormat = 'CSV'; // Default format

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Export Data',
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
              
              // Export Options Section
              _buildExportOptionsSection(),
              
              const SizedBox(height: 24),
              
              // Export Button
              _buildExportButton(),
              
              const SizedBox(height: 24),
              
              // Help Text
              _buildHelpText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOptionsSection() {
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
          _buildExportOption(
            'CSV Format',
            'Export all data as CSV file',
            CupertinoIcons.doc_text,
            'Most compatible format for spreadsheets',
            true,
            'CSV',
          ),
          _buildExportOption(
            'PDF Report',
            'Generate detailed PDF report',
            CupertinoIcons.doc_richtext,
            'Professional report with charts and summaries',
            false, // Not implemented yet
            'PDF',
          ),
          _buildExportOption(
            'Excel Format',
            'Export as Excel spreadsheet',
            CupertinoIcons.table,
            'Native Excel format with multiple sheets',
            true, // Now implemented
            'Excel',
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(String title, String subtitle, IconData icon, String description, bool available, String format) {
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
            if (available)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFormat = format;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedFormat == format 
                      ? AppColors.dynamicPrimary(context)
                      : AppColors.dynamicPrimary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _selectedFormat == format ? 'Selected' : 'Select',
                    style: AppTheme.getDynamicCaption1(context).copyWith(
                      color: _selectedFormat == format 
                        ? AppColors.dynamicSurface(context)
                        : AppColors.dynamicPrimary(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: AppColors.dynamicPrimary(context),
        borderRadius: BorderRadius.circular(12),
        onPressed: _isExporting ? null : _exportData,
        child: _isExporting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(color: AppColors.dynamicSurface(context)),
                const SizedBox(width: 8),
                Text(
                  'Exporting...',
                  style: AppTheme.getDynamicBody(context).copyWith(
                    color: AppColors.dynamicSurface(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ],
            )
          : Text(
              'Export Data',
              style: AppTheme.getDynamicBody(context).copyWith(
                color: AppColors.dynamicSurface(context),
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
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
              'Your exported data will include all customers, debts, and payment history. The file can be shared via email, AirDrop, or saved to Files app.',
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

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final customers = appState.customers;
      final debts = appState.debts;

      if (customers.isEmpty && debts.isEmpty) {
        await _notificationService.showWarningNotification(
          title: 'No Data',
          body: 'There is no data to export. Add some customers and debts first.',
        );
        return;
      }

      String filePath;
      String formatName;
      
      switch (_selectedFormat) {
        case 'Excel':
          filePath = await _exportService.exportToExcel(customers, debts);
          formatName = 'Excel';
          break;
        case 'CSV':
        default:
          filePath = await _exportService.exportToCSV(customers, debts);
          formatName = 'CSV';
          break;
      }
      
      setState(() {
        _exportedFilePath = filePath;
      });

      await _exportService.shareExportFile(filePath);
      
      await _notificationService.showSuccessNotification(
        title: 'Export Successful',
        body: 'Your data has been exported as $formatName and shared successfully.',
      );

    } catch (e) {
      await _notificationService.showErrorNotification(
        title: 'Export Failed',
        body: 'Failed to export data: $e',
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
} 