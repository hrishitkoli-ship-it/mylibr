import 'package:sembast/sembast.dart';
import '../models/book.dart';
import '../models/bookmark.dart';
import 'sembast_db.dart';

class LibraryRepository {
  Future<void> addBook(Book book) async {
    final db = await SembastDb.instance();
    await SembastDb.booksStore.record(book.uuid).put(db, book.toMap());
  }

  Future<void> updateBook(Book book) async {
    final db = await SembastDb.instance();
    await SembastDb.booksStore.record(book.uuid).put(db, book.toMap());
  }

  Future<void> deleteBook(String uuid) async {
    final db = await SembastDb.instance();
    await SembastDb.booksStore.record(uuid).delete(db);
  }

  Future<Book?> getBook(String uuid) async {
    final db = await SembastDb.instance();
    final record = await SembastDb.booksStore.record(uuid).get(db);
    return record == null ? null : Book.fromMap(record);
  }

  Future<List<Book>> allBooks() async {
    final db = await SembastDb.instance();
    final records = await SembastDb.booksStore.find(
      db,
      finder: Finder(sortOrders: [SortOrder('dateAdded', false)]),
    );
    return records.map((r) => Book.fromMap(r.value)).toList();
  }

  Future<List<Book>> booksByStatus(ReadingStatus status) async {
    final db = await SembastDb.instance();
    final records = await SembastDb.booksStore.find(
      db,
      finder: Finder(
        filter: Filter.equals('status', status.index),
        sortOrders: [SortOrder('title')],
      ),
    );
    return records.map((r) => Book.fromMap(r.value)).toList();
  }

  /// Real-time instant search across title, author, and genre tags —
  /// runs in-memory over the (small, personal-library-sized) book set.
  Future<List<Book>> search(String queryText) async {
    final all = await allBooks();
    if (queryText.trim().isEmpty) return all;
    final q = queryText.toLowerCase();
    return all.where((b) {
      if (b.title.toLowerCase().contains(q)) return true;
      if (b.author.toLowerCase().contains(q)) return true;
      if (b.genreNames.any((g) => g.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }

  Future<List<String>> allGenreNames() async {
    final all = await allBooks();
    final set = <String>{};
    for (final b in all) {
      set.addAll(b.genreNames);
    }
    return set.toList()..sort();
  }

  // ---- Bookmarks ----

  Future<void> addBookmark(Bookmark bookmark) async {
    final db = await SembastDb.instance();
    await SembastDb.bookmarksStore.record(bookmark.id).put(db, bookmark.toMap());
  }

  Future<List<Bookmark>> bookmarksForBook(String bookUuid) async {
    final db = await SembastDb.instance();
    final records = await SembastDb.bookmarksStore.find(
      db,
      finder: Finder(filter: Filter.equals('bookUuid', bookUuid)),
    );
    return records.map((r) => Bookmark.fromMap(r.value)).toList();
  }

  Future<void> deleteBookmark(String id) async {
    final db = await SembastDb.instance();
    await SembastDb.bookmarksStore.record(id).delete(db);
  }
}
