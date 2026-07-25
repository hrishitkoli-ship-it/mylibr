import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../db/library_repository.dart';
import '../models/book.dart';
import '../services/local_blob_store.dart';
import '../services/cover_service.dart';

class LibraryState extends ChangeNotifier {
  final LibraryRepository repository;
  final LocalBlobStore blobStore;
  final CoverService coverService;
  final _uuid = const Uuid();

  List<Book> books = [];
  String searchQuery = '';
  bool isImporting = false;
  String? lastError;

  LibraryState({
    required this.repository,
    required this.blobStore,
    required this.coverService,
  }) {
    refresh();
  }

  Future<void> refresh() async {
    books = searchQuery.isEmpty ? await repository.allBooks() : await repository.search(searchQuery);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    refresh();
  }

  /// Full import pipeline, entirely in-browser:
  ///  1. Native file input picks a PDF (bytes read directly into memory,
  ///     no upload to any server)
  ///  2. Bytes are base64-persisted into IndexedDB via LocalBlobStore
  ///  3. pdf.js opens the in-memory bytes, renders page 1 -> cover PNG
  ///  4. Book record persisted to sembast (also IndexedDB-backed)
  Future<Book?> importPdf() async {
    isImporting = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // required on web: bytes come back directly, no path
      );
      if (result == null || result.files.single.bytes == null) {
        return null; // user cancelled
      }
      final Uint8List pdfBytes = result.files.single.bytes!;
      final fileName = result.files.single.name.replaceAll('.pdf', '');
      final uuid = _uuid.v4();

      final pdfBlobKey = await blobStore.savePdf(bytes: pdfBytes, uuid: uuid);

      final doc = await coverService.openDocument(pdfBytes);
      final coverBlobKey = await coverService.autoGenerateCover(doc: doc, uuid: uuid);

      final book = Book(
        uuid: uuid,
        title: fileName,
        pdfBlobKey: pdfBlobKey,
        coverBlobKey: coverBlobKey,
        pageCount: doc.pageCount,
        fileSizeBytes: pdfBytes.length,
      );
      await repository.addBook(book);
      await refresh();
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
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final key = await coverService.saveCustomCover(imageBytes: bytes, uuid: book.uuid);
    book.coverBlobKey = key;
    book.hasCustomCover = true;
    await repository.updateBook(book);
    await refresh();
  }

  Future<void> updateStatus(Book book, ReadingStatus status) async {
    book.status = status;
    await repository.updateBook(book);
    await refresh();
  }

  Future<void> updateGenres(Book book, List<String> genreNames) async {
    book.genreNames = genreNames;
    await repository.updateBook(book);
    await refresh();
  }

  Future<void> updateLastReadPage(Book book, int page) async {
    book.lastReadPage = page;
    book.dateLastOpened = DateTime.now().millisecondsSinceEpoch;
    if (book.status == ReadingStatus.unread) {
      book.status = ReadingStatus.reading;
    }
    await repository.updateBook(book);
  }

  Future<void> deleteBook(Book book) async {
    await blobStore.delete(book.pdfBlobKey);
    await blobStore.delete(book.coverBlobKey);
    await repository.deleteBook(book.uuid);
    await refresh();
  }
}
