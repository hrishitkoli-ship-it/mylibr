import 'dart:typed_data';
import '../web_interop/pdf_interop.dart';
import 'local_blob_store.dart';

/// Handles cover generation entirely client-side via pdf.js
/// (see web/pdf_bridge.js). No image ever goes to a server.
class CoverService {
  final LocalBlobStore blobStore;
  CoverService(this.blobStore);

  Future<PdfJsDocument> openDocument(Uint8List pdfBytes) => PdfInterop.open(pdfBytes);

  /// Renders page 1 to PNG and saves it in the local blob store.
  /// Returns the blob store key for the cover.
  Future<String> autoGenerateCover({
    required PdfJsDocument doc,
    required String uuid,
    double targetWidth = 480,
  }) async {
    final pngBytes = await PdfInterop.renderPageToPng(doc, 1, targetWidth: targetWidth);
    return blobStore.saveCover(bytes: pngBytes, uuid: uuid);
  }

  /// Saves a user-picked image (already read as bytes by the browser
  /// file input) as the book's cover, replacing the auto-generated one.
  Future<String> saveCustomCover({
    required Uint8List imageBytes,
    required String uuid,
  }) async {
    return blobStore.saveCover(bytes: imageBytes, uuid: uuid);
  }
}
