import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Owns all on-device directory structure. Nothing here ever touches
/// the network — every path resolves inside the app's sandboxed
/// documents directory.
class LocalStorageService {
  static const _libraryDirName = 'library';
  static const _pdfsDirName = 'pdfs';
  static const _coversDirName = 'covers';

  Directory? _appDocsDir;

  Future<Directory> get appDocsDir async {
    _appDocsDir ??= await getApplicationDocumentsDirectory();
    return _appDocsDir!;
  }

  Future<Directory> get pdfsDir async {
    final base = await appDocsDir;
    final dir = Directory(p.join(base.path, _libraryDirName, _pdfsDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get coversDir async {
    final base = await appDocsDir;
    final dir = Directory(p.join(base.path, _libraryDirName, _coversDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies a user-picked PDF (from file_picker's temp path) into the
  /// app sandbox, named by its uuid so re-imports never collide.
  Future<File> importPdf({
    required String sourcePath,
    required String uuid,
  }) async {
    final dir = await pdfsDir;
    final destPath = p.join(dir.path, '$uuid.pdf');
    final sourceFile = File(sourcePath);
    return sourceFile.copy(destPath);
  }

  /// Saves raw PNG bytes (either a rendered PDF page-1 or a picked
  /// gallery image, already re-encoded to PNG by the caller) as the
  /// book's cover.
  Future<File> saveCoverBytes({
    required List<int> pngBytes,
    required String uuid,
  }) async {
    final dir = await coversDir;
    final destPath = p.join(dir.path, '$uuid.png');
    final file = File(destPath);
    return file.writeAsBytes(pngBytes, flush: true);
  }

  Future<void> deleteBookFiles({
    required String pdfPath,
    required String coverPath,
  }) async {
    final pdf = File(pdfPath);
    final cover = File(coverPath);
    if (await pdf.exists()) await pdf.delete();
    if (await cover.exists()) await cover.delete();
  }

  Future<int> fileSize(String path) async {
    final f = File(path);
    if (!await f.exists()) return 0;
    return f.length();
  }
}
