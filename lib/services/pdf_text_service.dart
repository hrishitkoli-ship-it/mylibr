import '../web_interop/pdf_interop.dart';

/// Extracts text from an already-open pdf.js document. Rendering and
/// parsing both happen inside the browser tab — no server round trip.
class PdfTextService {
  Future<String> extractPageText(PdfJsDocument doc, int pageNumber) async {
    final raw = await PdfInterop.extractPageText(doc, pageNumber);
    return _cleanForSpeech(raw);
  }

  Future<List<String>> extractAllPages(PdfJsDocument doc) async {
    final raw = await PdfInterop.extractAllPages(doc);
    return raw.map(_cleanForSpeech).toList();
  }

  String _cleanForSpeech(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
