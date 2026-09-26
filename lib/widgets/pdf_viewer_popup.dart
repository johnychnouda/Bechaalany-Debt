import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:typed_data';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/pdf_document_file.dart';
import '../utils/platform_utils.dart';
// Notification service import removed
class PDFViewerPopup extends StatefulWidget {
  final PdfDocumentFile pdfFile;
  final String customerName;

  const PDFViewerPopup({
    super.key,
    required this.pdfFile,
    required this.customerName,
  });

  @override
  State<PDFViewerPopup> createState() => _PDFViewerPopupState();
}

class _PDFViewerPopupState extends State<PDFViewerPopup> {
  final PdfViewerController _pdfController = PdfViewerController();
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  Uint8List? _pdfBytes;
  bool _hasRenderingError = false;
  double _viewportWidth = 0;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      final bytes = widget.pdfFile.bytes;

      if (bytes.isEmpty) {
        setState(() {
          _errorMessage = 'PDF file is empty (0 bytes)';
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      body: Column(
        children: [
          // iOS Native Header - No grey space, no SafeArea
          Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRtl ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
                        color: CupertinoColors.activeBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.back,
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.receipt,
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (PlatformUtils.isBrowserContext) ...[
                      _headerActionButton(
                        icon: CupertinoIcons.arrow_down_doc,
                        tooltip: 'Download PDF',
                        onPressed: _downloadPDF,
                      ),
                      _headerActionButton(
                        icon: CupertinoIcons.printer,
                        tooltip: 'Print',
                        onPressed: _printPDF,
                      ),
                    ],
                    _headerActionButton(
                      icon: CupertinoIcons.share,
                      tooltip: 'Share',
                      onPressed: _sharePDF,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // PDF Content - Full Screen with no grey spaces
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: _buildPDFContent(),
            ),
          ),
          
          // iOS Native Bottom Bar (only show if multiple pages) - No grey space
          if (_totalPages > 1)
            Container(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: _currentPage > 1
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                    child: Icon(
                      isRtl ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
                      color: _currentPage > 1
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      l10n.pageOf('$_currentPage', '$_totalPages'),
                      style: TextStyle(
                        color: CupertinoColors.label.resolveFrom(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: _currentPage < _totalPages
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                    child: Icon(
                      isRtl ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
                      color: _currentPage < _totalPages
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPDFContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.systemRed,
                size: 60,
              ),
              const SizedBox(height: 24),
              Text(
                'Error loading PDF',
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Unknown error',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: () => _retryLoadPDF(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(
              radius: 30,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading receipt...',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'File: ${widget.pdfFile.name}',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Size: ${(widget.pdfFile.bytes.length / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_pdfBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              color: CupertinoColors.systemOrange,
              size: 60,
            ),
            const SizedBox(height: 24),
            Text(
              'No PDF data available',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading state: $_isLoading\nPDF bytes: ${_pdfBytes?.length ?? 'null'}',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: () => _retryLoadPDF(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Try to display the PDF with a more stable approach
    return _buildStablePdfViewer();
  }

  Widget _headerActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        onPressed: onPressed,
        child: Icon(
          icon,
          color: CupertinoColors.activeBlue,
          size: 20,
        ),
      ),
    );
  }

  void _fitPdfToViewport(PdfDocumentLoadedDetails details) {
    if (!PlatformUtils.isBrowserContext || _viewportWidth <= 0) return;
    try {
      final pageSize = details.document.pages[0].size;
      final horizontalPadding = 32.0;
      final fitZoom = (_viewportWidth - horizontalPadding) / pageSize.width;
      _pdfController.zoomLevel = fitZoom.clamp(0.4, 1.0);
    } catch (_) {
      _pdfController.zoomLevel = 0.85;
    }
  }

  Widget _buildStablePdfViewer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we have valid constraints before rendering
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        
        // Use explicit bounded constraints to prevent layout errors
        final boundedWidth = constraints.maxWidth.isFinite 
            ? constraints.maxWidth 
            : MediaQuery.of(context).size.width;
        final boundedHeight = constraints.maxHeight.isFinite 
            ? constraints.maxHeight 
            : MediaQuery.of(context).size.height;
        _viewportWidth = boundedWidth;
        
        return SizedBox(
          width: boundedWidth,
          height: boundedHeight,
          child: Builder(
            builder: (context) {
              // Use a try-catch wrapper to handle any rendering errors gracefully
              try {
                return SfPdfViewer.memory(
                  _pdfBytes!,
                  controller: _pdfController,
                  enableDoubleTapZooming: true,
                  enableTextSelection: false,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
                  canShowPageLoadingIndicator: false,
                  pageSpacing: PlatformUtils.isBrowserContext ? 12 : 0,
                  enableDocumentLinkAnnotation: false,
                  enableHyperlinkNavigation: false,
                  canShowPaginationDialog: false,
                  pageLayoutMode: _totalPages > 1
                      ? PdfPageLayoutMode.continuous
                      : PdfPageLayoutMode.single,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    if (mounted) {
                      _fitPdfToViewport(details);
                      setState(() {
                        _totalPages = details.document.pages.count;
                      });
                    }
                  },
                  onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                    if (mounted) {
                      setState(() {
                        _errorMessage = _formatPdfLoadError(details.error);
                        _hasRenderingError = true;
                      });
                    }
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    if (mounted) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    }
                  },
                );
              } catch (e) {
                // If rendering fails, show error state
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _errorMessage = 'PDF rendering error: $e';
                        _hasRenderingError = true;
                      });
                    }
                  });
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: CupertinoColors.systemRed,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PDF Rendering Error',
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please try sharing the PDF instead',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFallbackInterface() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              color: CupertinoColors.activeBlue,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Receipt Ready',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PDF receipt has been generated successfully.\nDue to technical limitations, the PDF viewer is temporarily unavailable.',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'File Information',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Customer: ${widget.customerName}',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'File Size: ${(_pdfBytes?.length ?? 0) ~/ 1024} KB',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: () => _sharePDF(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.share, size: 20),
                  const SizedBox(width: 8),
                  const Text('Share PDF'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPdfLoadError(Object? error) {
    final message = error?.toString().trim() ?? '';
    if (message.isEmpty || message == 'Error') {
      return 'PDF viewer could not load this receipt. Try sharing or downloading the PDF instead.';
    }
    return message;
  }

  void _retryLoadPDF() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _pdfBytes = null;
    });
    _loadPDF();
  }

  void _goToPage(int pageNumber) {
    setState(() {
      _currentPage = pageNumber;
    });
  }

  Future<void> _sharePDF() async {
    try {
      await widget.pdfFile.share();
    } catch (_) {}
  }

  Future<void> _downloadPDF() async {
    try {
      await widget.pdfFile.download();
    } catch (_) {}
  }

  Future<void> _printPDF() async {
    try {
      await widget.pdfFile.printDocument();
    } catch (_) {}
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }
}

