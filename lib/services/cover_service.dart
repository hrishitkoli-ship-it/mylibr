import 'dart:io';
import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';
import 'package:image_picker/image_picker.dart';
import 'local_storage_service.dart';

/// Handles cover generation. Two paths:
///  1. autoGenerate() — rasterizes page 1 of the PDF entirely on-device.
///  2. pickCustomCover() — lets the user override with a gallery photo.
/// No network calls, no cloud rendering services.
class CoverService {
  final LocalStorageService storage;
  CoverService(this.storage);

  /// Renders page 1 of [pdfPath] to a PNG and saves it as the book's
  /// cover under the app sandbox. Returns the saved cover file path.
  Future<String> autoGenerateCover({
    required String pdfPath,
    required String uuid,
    double targetWidth = 480,
  }) async {
    final document = await PdfDocument.openFile(pdfPath);
    try {
      final page = await document.getPage(1);
      try {
        final scale = targetWidth / page.width;
        final pageImage = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        if (pageImage == null) {
          throw Exception('Failed to render page 1 for cover.');
        }
        final saved = await storage.saveCoverBytes(
          pngBytes: pageImage.bytes,
          uuid: uuid,
        );
        return saved.path;
      } finally {
        await page.close();
      }
    } finally {
      await document.close();
    }
  }

  /// Opens the local photo gallery and, if the user picks an image,
  /// saves it as the book's cover — fully replacing the auto cover.
  /// Returns null if the user cancels.
  Future<String?> pickCustomCover({required String uuid}) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200, // downscale on-device, no upload anywhere
      imageQuality: 90,
    );
    if (picked == null) return null;

    final Uint8List bytes = await picked.readAsBytes();
    final saved = await storage.saveCoverBytes(
      pngBytes: bytes,
      uuid: uuid,
    );
    return saved.path;
  }

  /// Also reports total page count while we already have the doc open —
  /// call this once at import time to populate Book.pageCount.
  Future<int> getPageCount(String pdfPath) async {
    final document = await PdfDocument.openFile(pdfPath);
    try {
      return document.pagesCount;
    } finally {
      await document.close();
    }
  }
}
