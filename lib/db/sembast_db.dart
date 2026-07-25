import 'package:sembast_web/sembast_web.dart';
import 'package:sembast/sembast.dart';

/// Opens the browser-local sembast database, backed by IndexedDB.
/// This is the only "database" in the web build — everything lives
/// in the browser's own storage, scoped to this site's origin.
class SembastDb {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    _db = await databaseFactoryWeb.openDatabase('mylibrary.db');
    return _db!;
  }

  static final booksStore = stringMapStoreFactory.store('books');
  static final bookmarksStore = stringMapStoreFactory.store('bookmarks');
}
