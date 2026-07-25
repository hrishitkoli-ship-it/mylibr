import Dexie, { type Table } from 'dexie';
import type { Book, BookFile, Bookmark } from '../types';

/**
 * The entire persistence layer for MyLibrary. Dexie is a thin,
 * well-typed wrapper over the browser's native IndexedDB — there is
 * no server, no sync adapter, no network call anywhere in this file.
 * Blobs (PDF bytes, cover images) are stored natively as IndexedDB
 * Blob values, not base64 — cheaper to store and read than the
 * previous Flutter/sembast approach.
 */
class MyLibraryDB extends Dexie {
  books!: Table<Book, string>;
  bookFiles!: Table<BookFile, string>;
  bookmarks!: Table<Bookmark, string>;

  constructor() {
    super('mylibrary');
    this.version(1).stores({
      books: 'uuid, title, author, status, dateAdded, dateLastOpened',
      bookFiles: 'uuid',
      bookmarks: 'id, bookUuid',
    });
  }
}

export const db = new MyLibraryDB();
