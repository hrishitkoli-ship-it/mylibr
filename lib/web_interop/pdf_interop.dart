// Thin JS-interop layer over pdf.js (Mozilla's PDF renderer), loaded
// as a plain <script> in web/index.html — no network fetch of the
// library at runtime beyond the one-time app asset load; pdf.js itself
// does no networking once the PDF bytes are handed to it locally.
//
// This file only declares the JS bridge functions implemented in
// web/pdf_bridge.js. See that file for the actual pdf.js calls.

@JS()
library pdf_interop;

import 'dart:typed_data';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS('pdfBridge.loadDocument')
external Object _loadDocument(Uint8List bytes);

@JS('pdfBridge.getPageCount')
external Object _getPageCount(Object doc);

@JS('pdfBridge.renderPageToPngBytes')
external Object _renderPageToPngBytes(Object doc, int pageNumber, double targetWidth);

@JS('pdfBridge.extractPageText')
external Object _extractPageText(Object doc, int pageNumber);

/// Opaque handle to a pdf.js document loaded entirely in-memory from
/// bytes the user picked locally — never fetched from a URL.
class PdfJsDocument {
  final Object jsDoc;
  final int pageCount;
  PdfJsDocument(this.jsDoc, this.pageCount);
}

class PdfInterop {
  static Future<PdfJsDocument> open(Uint8List bytes) async {
    final doc = await js_util.promiseToFuture<Object>(_loadDocument(bytes));
    final count = await js_util.promiseToFuture<int>(_getPageCount(doc));
    return PdfJsDocument(doc, count);
  }

  /// Renders [pageNumber] (1-indexed) to PNG bytes at [targetWidth] px
  /// wide, aspect-preserved. Used for cover generation (page 1) and
  /// for potential future page-image caching.
  static Future<Uint8List> renderPageToPng(
    PdfJsDocument doc,
    int pageNumber, {
    double targetWidth = 480,
  }) async {
    final result = await js_util.promiseToFuture<Object>(
      _renderPageToPngBytes(doc.jsDoc, pageNumber, targetWidth),
    );
    return (result as ByteBuffer).asUint8List();
  }

  /// Extracts raw text for [pageNumber] (1-indexed), used for TTS.
  static Future<String> extractPageText(PdfJsDocument doc, int pageNumber) async {
    final result = await js_util.promiseToFuture<Object>(
      _extractPageText(doc.jsDoc, pageNumber),
    );
    return result as String;
  }

  static Future<List<String>> extractAllPages(PdfJsDocument doc) async {
    final pages = <String>[];
    for (var i = 1; i <= doc.pageCount; i++) {
      pages.add(await extractPageText(doc, i));
    }
    return pages;
  }
}
