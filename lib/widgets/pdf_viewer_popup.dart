import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import '../constants/app_colors.dart';
import '../services/notification_service.dart';
import '../models/customer.dart'; // Added import for Customer model
import '../screens/customer_details_screen.dart'; // Added import for CustomerDetailsScreen

class PDFViewerPopup extends StatefulWidget {
  final File pdfFile;
  final String customerName;
  final VoidCallback? onClose;
  final Customer? customer; // Add customer parameter

  const PDFViewerPopup({
    super.key,
    required this.pdfFile,
    required this.customerName,
    this.onClose,
    this.customer, // Add customer parameter
  });

  @override
  State<PDFViewerPopup> createState() => _PDFViewerPopupState();
}

class _PDFViewerPopupState extends State<PDFViewerPopup> {
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  Uint8List? _pdfBytes;
  bool _hasRenderingError = false;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      if (!widget.pdfFile.existsSync()) {
        setState(() {
          _errorMessage = 'PDF file not found';
          _isLoading = false;
        });
        return;
      }

      final fileSize = widget.pdfFile.lengthSync();
      
      if (fileSize == 0) {
        setState(() {
          _errorMessage = 'PDF file is empty (0 bytes)';
          _isLoading = false;
        });
        return;
      }

      // Read PDF bytes
      final bytes = await widget.pdfFile.readAsBytes();
      
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
                    // Close the PDF viewer
                    Navigator.of(context).pop();
                    widget.onClose?.call();
                    
                    // Navigate directly to customer details page if customer info is available
                    if (widget.customer != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // Use push instead of pushReplacement to preserve navigation stack
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CustomerDetailsScreen(
                              customer: widget.customer!,
                              showDebtsSection: true,
                            ),
                          ),
                        );
                      });
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.chevron_left,
                        color: CupertinoColors.activeBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Back',
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
                  'Receipt',
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _sharePDF(),
                  child: Icon(
                    CupertinoIcons.share,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
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
                      CupertinoIcons.chevron_left,
                      color: _currentPage > 1
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '$_currentPage of $_totalPages',
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
                      CupertinoIcons.chevron_right,
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
              'File: ${widget.pdfFile.path.split('/').last}',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Size: ${(widget.pdfFile.lengthSync() / 1024).toStringAsFixed(1)} KB',
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

  Widget _buildStablePdfViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: SfPdfViewer.memory(
        _pdfBytes!,
        enableDoubleTapZooming: true,
        enableTextSelection: false,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        pageSpacing: 0,
        enableDocumentLinkAnnotation: false,
        enableHyperlinkNavigation: false,
        canShowPaginationDialog: false,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          if (mounted) {
            setState(() {
              _totalPages = details.document.pages.count;
            });
          }
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          if (mounted) {
            setState(() {
              _errorMessage = details.error.toString();
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
      ),
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
      await Share.shareXFiles([XFile(widget.pdfFile.path)]);
      
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showSuccessNotification(
          title: 'PDF Shared',
          body: 'Receipt has been shared successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Share Error',
          body: 'Failed to share PDF: $e',
        );
      }
    }
  }
}

