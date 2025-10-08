import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class PDFViewerScreen extends StatelessWidget {
  final File pdfFile;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.pdfFile,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.dynamicSurface(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: AppTheme.title3.copyWith(
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _savePDF(context),
            tooltip: 'Save PDF',
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SfPdfViewer.file(
            pdfFile,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              // Document loaded successfully
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              // Handle document load failure
            },
            onPageChanged: (PdfPageChangedDetails details) {
              // Handle page change
            },
          ),
        ),
      ),
    );
  }


  Future<void> _savePDF(BuildContext context) async {
    try {
      // Save PDF to iPhone's Documents directory (iOS compatible)
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Monthly_Activity_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = await pdfFile.copy('${directory.path}/$fileName');
      
      if (await savedFile.exists()) {
        // Optionally share the file so user can save to Files app or other locations
        await Share.shareXFiles(
          [XFile(savedFile.path)],
          text: 'Monthly Activity Report from Bechaalany Connect',
        );
      } else {
        throw Exception('Failed to save PDF');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
