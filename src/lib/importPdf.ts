import { v4 as uuidv4 } from 'uuid';
import { pdfService } from './pdfService';
import { libraryRepository } from '../db/libraryRepository';
import { db } from '../db/database';
import type { Book, BookFile } from '../types';

/**
 * Full import pipeline, entirely in-browser:
 *  1. <input type="file"> gives us the PDF as bytes directly — no upload.
 *  2. pdf.js opens the in-memory bytes and renders page 1 to a cover PNG.
 *  3. Book metadata + PDF/cover blobs are written to IndexedDB.
 */
export async function importPdf(file: File): Promise<Book> {
  const bytes = await file.arrayBuffer();

  // pdf.js's getDocument() takes ownership of (detaches) the
  // ArrayBuffer it's given for zero-copy performance. We must open a
  // *copy* and keep the original bytes intact for storage, or the
  // Blob written to IndexedDB ends up empty and the reader fails
  // later with "the PDF file is empty, i.e. its size is zero bytes".
  const doc = await pdfService.open(bytes.slice(0));
  const coverBlob = await pdfService.renderPageToPng(doc, 1);

  const uuid = uuidv4();
  const title = file.name.replace(/\.pdf$/i, '');

  const book: Book = {
    uuid,
    title,
    author: '',
    description: '',
    pageCount: doc.numPages,
    lastReadPage: 0,
    status: 'unread',
    hasCustomCover: false,
    dateAdded: Date.now(),
    dateLastOpened: Date.now(),
    fileSizeBytes: file.size,
    genreNames: [],
  };

  const bookFile: BookFile = {
    uuid,
    pdfBlob: new Blob([bytes], { type: 'application/pdf' }),
    coverBlob,
  };

  await libraryRepository.addBook(book, bookFile);
  return book;
}

export async function setCustomCover(book: Book, imageFile: File): Promise<void> {
  const existing = await libraryRepository.getBookFile(book.uuid);
  if (!existing) throw new Error('Book file record not found');

  existing.coverBlob = imageFile;
  book.hasCustomCover = true;

  await db.transaction('rw', db.books, db.bookFiles, async () => {
    await db.books.put(book);
    await db.bookFiles.put(existing);
  });
}
