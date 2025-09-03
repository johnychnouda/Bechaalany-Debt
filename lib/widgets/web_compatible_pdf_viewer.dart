import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../constants/app_colors.dart';

// HTML utilities with conditional imports
import 'html_utils_web.dart' as html_utils
    if (dart.library.io) 'html_utils_mobile.dart';

class WebCompatiblePDFViewer extends StatefulWidget {
  final Uint8List pdfBytes;
  final String customerName;
  final VoidCallback? onClose;
  final Customer? customer;

  const WebCompatiblePDFViewer({
    super.key,
    required this.pdfBytes,
    required this.customerName,
    this.onClose,
    this.customer,
  });

  @override
  State<WebCompatiblePDFViewer> createState() => _WebCompatiblePDFViewerState();
}

class _WebCompatiblePDFViewerState extends State<WebCompatiblePDFViewer> {
  bool _isLoading = true;
  PdfViewerController? _pdfViewerController;
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      if (widget.pdfBytes.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _downloadPDF() {
    if (kIsWeb) {
      // Create a blob URL for download
      final blob = html_utils.HTMLUtils.createBlob(widget.pdfBytes, 'application/pdf');
      final url = html_utils.HTMLUtils.createObjectUrl(blob);
      final anchor = html_utils.HTMLUtils.createAnchor(url);
      anchor.setAttribute('download', '${widget.customerName}_Receipt.pdf');
      anchor.click();
      html_utils.HTMLUtils.revokeObjectUrl(url);
    }
  }

  void _openInNewTab() {
    if (kIsWeb) {
      // Create a blob URL for new tab
      final blob = html_utils.HTMLUtils.createBlob(widget.pdfBytes, 'application/pdf');
      final url = html_utils.HTMLUtils.createObjectUrl(blob);
      html_utils.HTMLUtils.openInNewTab(url);
      html_utils.HTMLUtils.revokeObjectUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      appBar: AppBar(
        title: Text(
          'Receipt - ${widget.customerName}',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 16,
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.dynamicTextPrimary(context),
          ),
          onPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          // Download button
          IconButton(
            icon: Icon(
              Icons.download,
              color: AppColors.dynamicTextPrimary(context),
            ),
            onPressed: _downloadPDF,
            tooltip: 'Download PDF',
          ),
          // Open in new tab button
          IconButton(
            icon: Icon(
              Icons.open_in_new,
              color: AppColors.dynamicTextPrimary(context),
            ),
            onPressed: _openInNewTab,
            tooltip: 'Open in new tab',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomControls(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.dynamicPrimary(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.pdfBytes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.dynamicError(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load PDF',
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The PDF file appears to be empty or corrupted.',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SfPdfViewer.memory(
      widget.pdfBytes,
      controller: _pdfViewerController,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
    );
  }



  Widget _buildBottomControls() {
    if (_isLoading || widget.pdfBytes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        border: Border(
          top: BorderSide(
            color: AppColors.dynamicBorder(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Text(
            'Page $_currentPage of $_totalPages',
            style: TextStyle(
              color: AppColors.dynamicTextSecondary(context),
              fontSize: 14,
            ),
          ),
          
          // Zoom controls
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.zoom_out,
                  color: AppColors.dynamicTextPrimary(context),
                ),
                onPressed: () {
                  if (_zoomLevel > 0.5) {
                    setState(() {
                      _zoomLevel -= 0.25;
                    });
                    _pdfViewerController?.zoomLevel = _zoomLevel;
                  }
                },
              ),
              Text(
                '${(_zoomLevel * 100).round()}%',
                style: TextStyle(
                  color: AppColors.dynamicTextPrimary(context),
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.zoom_in,
                  color: AppColors.dynamicTextPrimary(context),
                ),
                onPressed: () {
                  if (_zoomLevel < 3.0) {
                    setState(() {
                      _zoomLevel += 0.25;
                    });
                    _pdfViewerController?.zoomLevel = _zoomLevel;
                  }
                },
              ),
            ],
          ),
          
          // Navigation controls
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.navigate_before,
                  color: AppColors.dynamicTextPrimary(context),
                ),
                onPressed: _currentPage > 1
                    ? () => _pdfViewerController?.previousPage()
                    : null,
              ),
              IconButton(
                icon: Icon(
                  Icons.navigate_next,
                  color: AppColors.dynamicTextPrimary(context),
                ),
                onPressed: _currentPage < _totalPages
                    ? () => _pdfViewerController?.nextPage()
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}