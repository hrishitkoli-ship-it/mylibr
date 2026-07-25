import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts raw text from a PDF entirely on-device using
/// syncfusion_flutter_pdf's local parser — no OCR service, no cloud call.
class PdfTextService {
  /// Extracts text from a single page (1-indexed to match the reader UI).
  String extractPageText({required String pdfPath, required int pageNumber}) {
    final bytes = File(pdfPath).readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText(
        startPageIndex: pageNumber - 1,
        endPageIndex: pageNumber - 1,
      );
      return _cleanForSpeech(text);
    } finally {
      document.dispose();
    }
  }

  /// Extracts the whole document's text, page by page, for
  /// "continuous read" mode. Returns a list so the TTS controller can
  /// track which page is currently being spoken.
  List<String> extractAllPages(String pdfPath) {
    final bytes = File(pdfPath).readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final pages = <String>[];
      for (var i = 0; i < document.pages.count; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        pages.add(_cleanForSpeech(text));
      }
      return pages;
    } finally {
      document.dispose();
    }
  }

  String _cleanForSpeech(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'-\s'), '') // de-hyphenate line-wrapped words
        .trim();
  }
}
