import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../db/library_repository.dart';
import '../models/book.dart';
import '../services/local_storage_service.dart';
import '../services/cover_service.dart';

class LibraryState extends ChangeNotifier {
  final LibraryRepository repository;
  final LocalStorageService storage;
  final CoverService coverService;
  final _uuid = const Uuid();

  List<Book> books = [];
  String searchQuery = '';
  bool isImporting = false;
  String? lastError;

  LibraryState({
    required this.repository,
    required this.storage,
    required this.coverService,
  }) {
    refresh();
  }

  void refresh() {
    books = searchQuery.isEmpty ? repository.allBooks() : repository.search(searchQuery);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    refresh();
  }

  /// Full import pipeline, entirely local:
  ///  1. User picks a PDF via file_picker (native file chooser, no upload)
  ///  2. Copy it into the app sandbox directory
  ///  3. Render page 1 -> cover PNG, saved locally
  ///  4. Persist Book record to ObjectBox
  Future<Book?> importPdf() async {
    isImporting = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.single.path == null) {
        return null; // user cancelled
      }
      final pickedPath = result.files.single.path!;
      final fileName = result.files.single.name.replaceAll('.pdf', '');
      final uuid = _uuid.v4();

      final localPdf = await storage.importPdf(sourcePath: pickedPath, uuid: uuid);
      final pageCount = await coverService.getPageCount(localPdf.path);
      final coverPath = await coverService.autoGenerateCover(
        pdfPath: localPdf.path,
        uuid: uuid,
      );
      final fileSize = await storage.fileSize(localPdf.path);

      final book = Book.create(
        uuid: uuid,
        title: fileName,
        filePath: localPdf.path,
        coverPath: coverPath,
        pageCount: pageCount,
        fileSizeBytes: fileSize,
      );
      repository.addBook(book);
      refresh();
      return book;
    } catch (e) {
      lastError = 'Import failed: $e';
      notifyListeners();
      return null;
    } finally {
      isImporting = false;
      notifyListeners();
    }
  }

  Future<void> setCustomCover(Book book) async {
    final path = await coverService.pickCustomCover(uuid: book.uuid);
    if (path == null) return;
    book.coverPath = path;
    book.hasCustomCover = true;
    repository.updateBook(book);
    refresh();
  }

  void updateStatus(Book book, ReadingStatus status) {
    book.status = status;
    repository.updateBook(book);
    refresh();
  }

  void updateGenres(Book book, List<String> genreNames) {
    repository.assignGenres(book, genreNames);
    refresh();
  }

  void updateLastReadPage(Book book, int page) {
    book.lastReadPage = page;
    book.dateLastOpened = DateTime.now().millisecondsSinceEpoch;
    if (book.status == ReadingStatus.unread) {
      book.status = ReadingStatus.reading;
    }
    repository.updateBook(book);
  }

  void deleteBook(Book book) {
    storage.deleteBookFiles(pdfPath: book.filePath, coverPath: book.coverPath);
    repository.deleteBook(book.id);
    refresh();
  }
}
