import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../services/data_export_import_service.dart';
import '../services/notification_service.dart';
import '../models/category.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final DataExportImportService _exportService = DataExportImportService();
  final NotificationService _notificationService = NotificationService();
  bool _isExporting = false;
  // String? _exportedFilePath; // Removed unused field

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Export Data'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            _buildExportOptionsSection(),
            const SizedBox(height: 24),
            _buildExportButton(),
            const SizedBox(height: 24),
            _buildInfoSection(),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dynamicTextPrimary(context).withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildExportOption(
            'PDF Report',
            'Generate detailed PDF report',
            CupertinoIcons.doc_richtext,
            'Professional report with charts and summaries',
            true,
            'PDF',
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
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: available 
                  ? AppColors.dynamicPrimary(context).withAlpha(20)
                  : AppColors.dynamicTextSecondary(context).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: available 
                  ? AppColors.dynamicPrimary(context)
                  : AppColors.dynamicTextSecondary(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
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
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTheme.getDynamicFootnote(context).copyWith(
                      color: AppColors.dynamicTextSecondary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.getDynamicCaption1(context).copyWith(
                      color: AppColors.dynamicTextSecondary(context),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (!available)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.dynamicTextSecondary(context).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Coming Soon',
                  style: AppTheme.getDynamicCaption1(context).copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (available)
              GestureDetector(
                onTap: () {
                  // Only PDF option available
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicPrimary(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Selected',
                    style: AppTheme.getDynamicCaption1(context).copyWith(
                      color: AppColors.dynamicSurface(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        color: AppColors.dynamicPrimary(context),
        borderRadius: BorderRadius.circular(16),
        onPressed: _isExporting ? null : _exportData,
        child: _isExporting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(color: AppColors.dynamicSurface(context)),
                const SizedBox(width: 12),
                Text(
                  'Exporting...',
                  style: AppTheme.getDynamicBody(context).copyWith(
                    color: AppColors.dynamicSurface(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.square_arrow_up,
                  color: AppColors.dynamicSurface(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Export Data',
                  style: AppTheme.getDynamicBody(context).copyWith(
                    color: AppColors.dynamicSurface(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicPrimary(context).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicPrimary(context).withAlpha(30),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.dynamicPrimary(context).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.info_circle,
              color: AppColors.dynamicPrimary(context),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your exported data will include all customers, debts, and payment history. The file can be shared via email, AirDrop, or saved to Files app.',
              style: AppTheme.getDynamicCaption1(context).copyWith(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 15,
                height: 1.4,
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

      final filePath = await _exportService.exportToPDF(customers, debts, appState.productPurchases, appState.categories.whereType<ProductCategory>().toList());
      
      await _exportService.shareExportFile(filePath);
      
      await _notificationService.showSuccessNotification(
        title: 'Export Successful',
        body: 'Your data has been exported as PDF and shared successfully.',
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