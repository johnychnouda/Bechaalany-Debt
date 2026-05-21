import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// In-memory PDF for sharing and viewing on mobile and web.
class PdfDocumentFile {
  final Uint8List bytes;
  final String name;

  const PdfDocumentFile({
    required this.bytes,
    required this.name,
  });

  String get fileName => name.endsWith('.pdf') ? name : '$name.pdf';

  XFile toXFile() => XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'application/pdf',
      );

  Future<void> share({String? text}) async {
    await Share.shareXFiles(
      [toXFile()],
      text: text,
    );
  }

  /// Saves the PDF to the device (browser download on web).
  Future<void> download() async {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// Opens the system print dialog (browser print on web).
  Future<void> printDocument() async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
    );
  }
}
