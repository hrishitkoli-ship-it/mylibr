import { db } from './database';
import type { Book, BookFile, Bookmark, ReadingStatus } from '../types';

/**
 * Single point of access for all local persistence. Every method
 * here reads/writes IndexedDB (via Dexie) only.
 */
export const libraryRepository = {
  async addBook(book: Book, file: BookFile): Promise<void> {
    await db.transaction('rw', db.books, db.bookFiles, async () => {
      await db.books.put(book);
      await db.bookFiles.put(file);
    });
  },

  async updateBook(book: Book): Promise<void> {
    await db.books.put(book);
  },

  async deleteBook(uuid: string): Promise<void> {
    await db.transaction('rw', db.books, db.bookFiles, db.bookmarks, async () => {
      await db.books.delete(uuid);
      await db.bookFiles.delete(uuid);
      await db.bookmarks.where('bookUuid').equals(uuid).delete();
    });
  },

  async getBook(uuid: string): Promise<Book | undefined> {
    return db.books.get(uuid);
  },

  async getBookFile(uuid: string): Promise<BookFile | undefined> {
    return db.bookFiles.get(uuid);
  },

  async allBooks(): Promise<Book[]> {
    return db.books.orderBy('dateAdded').reverse().toArray();
  },

  async booksByStatus(status: ReadingStatus): Promise<Book[]> {
    return db.books.where('status').equals(status).sortBy('title');
  },

  /** Real-time instant search across title, author, and genre tags. */
  async search(queryText: string): Promise<Book[]> {
    const all = await this.allBooks();
    const q = queryText.trim().toLowerCase();
    if (!q) return all;
    return all.filter(
      (b) =>
        b.title.toLowerCase().includes(q) ||
        b.author.toLowerCase().includes(q) ||
        b.genreNames.some((g) => g.toLowerCase().includes(q)),
    );
  },

  async allGenreNames(): Promise<string[]> {
    const all = await this.allBooks();
    const set = new Set<string>();
    for (const b of all) b.genreNames.forEach((g) => set.add(g));
    return [...set].sort();
  },

  // ---- Bookmarks ----

  async addBookmark(bookmark: Bookmark): Promise<void> {
    await db.bookmarks.put(bookmark);
  },

  async bookmarksForBook(bookUuid: string): Promise<Bookmark[]> {
    return db.bookmarks.where('bookUuid').equals(bookUuid).toArray();
  },

  async deleteBookmark(id: string): Promise<void> {
    await db.bookmarks.delete(id);
  },
};
