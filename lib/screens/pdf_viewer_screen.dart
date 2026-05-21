import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/pdf_document_file.dart';
import '../utils/platform_utils.dart';

class PDFViewerScreen extends StatefulWidget {
  final PdfDocumentFile pdfFile;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.pdfFile,
    required this.title,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  double _viewportWidth = 0;

  void _fitPdfToViewport(PdfDocumentLoadedDetails details) {
    if (!PlatformUtils.isBrowserContext || _viewportWidth <= 0) return;
    try {
      final pageSize = details.document.pages[0].size;
      final fitZoom = (_viewportWidth - 32) / pageSize.width;
      _pdfController.zoomLevel = fitZoom.clamp(0.4, 1.0);
    } catch (_) {
      _pdfController.zoomLevel = 0.85;
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

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
          widget.title,
          style: AppTheme.title3.copyWith(
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        actions: [
          if (PlatformUtils.isBrowserContext) ...[
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: () => widget.pdfFile.printDocument(),
              tooltip: 'Print',
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: () => widget.pdfFile.download(),
              tooltip: 'Download PDF',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _sharePDF(context),
            tooltip: 'Share',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return const SizedBox.shrink();
          }

          final boundedWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final boundedHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height;
          _viewportWidth = boundedWidth;

          return Container(
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
              child: SizedBox(
                width: boundedWidth - 16,
                height: boundedHeight - 16,
                child: SfPdfViewer.memory(
                  widget.pdfFile.bytes,
                  controller: _pdfController,
                  enableDoubleTapZooming: true,
                  enableTextSelection: true,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  pageLayoutMode: PlatformUtils.isBrowserContext
                      ? PdfPageLayoutMode.single
                      : PdfPageLayoutMode.continuous,
                  onDocumentLoaded: _fitPdfToViewport,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sharePDF(BuildContext context) async {
    try {
      await widget.pdfFile.share(
        text: 'Monthly Activity Report from Bechaalany Connect',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
