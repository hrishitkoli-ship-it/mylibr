import '../models/book.dart';
import '../models/genre.dart';
import '../models/bookmark.dart';
import '../objectbox.g.dart';
import 'objectbox_store.dart';

/// Single point of access for all local persistence. Every method here
/// reads/writes ObjectBox only — no network layer exists in this class.
class LibraryRepository {
  final ObjectBoxStore _obStore;
  late final Box<Book> _bookBox;
  late final Box<Genre> _genreBox;
  late final Box<Bookmark> _bookmarkBox;

  LibraryRepository(this._obStore) {
    _bookBox = _obStore.store.box<Book>();
    _genreBox = _obStore.store.box<Genre>();
    _bookmarkBox = _obStore.store.box<Bookmark>();
  }

  // ---- Books ----

  int addBook(Book book) => _bookBox.put(book);

  void updateBook(Book book) => _bookBox.put(book);

  void deleteBook(int id) => _bookBox.remove(id);

  Book? getBook(int id) => _bookBox.get(id);

  List<Book> allBooks() =>
      _bookBox.query().order(Book_.dateAdded, flags: Order.descending).build().find();

  List<Book> booksByStatus(ReadingStatus status) {
    final query = _bookBox
        .query(Book_.dbStatus.equals(status.index))
        .order(Book_.title)
        .build();
    final result = query.find();
    query.close();
    return result;
  }

  /// Real-time instant search across title, author, and genre tag names.
  List<Book> search(String queryText) {
    if (queryText.trim().isEmpty) return allBooks();
    final q = queryText.toLowerCase();

    final byTitleOrAuthor = _bookBox
        .query(Book_.title.contains(q, caseSensitive: false) |
            Book_.author.contains(q, caseSensitive: false))
        .build()
        .find();

    final matchingGenres = _genreBox
        .query(Genre_.name.contains(q, caseSensitive: false))
        .build()
        .find();
    final byGenre = <Book>{};
    for (final genre in matchingGenres) {
      byGenre.addAll(genre.books);
    }

    final combined = <int, Book>{};
    for (final b in [...byTitleOrAuthor, ...byGenre]) {
      combined[b.id] = b;
    }
    return combined.values.toList()..sort((a, b) => a.title.compareTo(b.title));
  }

  // ---- Genres ----

  Genre getOrCreateGenre(String name) {
    final existing =
        _genreBox.query(Genre_.name.equals(name, caseSensitive: false)).build().findFirst();
    if (existing != null) return existing;
    final genre = Genre.create(name: name);
    genre.id = _genreBox.put(genre);
    return genre;
  }

  List<Genre> allGenres() => _genreBox.getAll();

  void assignGenres(Book book, List<String> genreNames) {
    book.genres.clear();
    for (final name in genreNames) {
      book.genres.add(getOrCreateGenre(name));
    }
    _bookBox.put(book);
  }

  // ---- Bookmarks ----

  int addBookmark(Book book, Bookmark bookmark) {
    bookmark.book.target = book;
    return _bookmarkBox.put(bookmark);
  }

  List<Bookmark> bookmarksForBook(Book book) => book.bookmarks;

  void deleteBookmark(int id) => _bookmarkBox.remove(id);
}
