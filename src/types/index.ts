export type ReadingStatus = 'unread' | 'reading' | 'completed';

export interface Book {
  uuid: string;
  title: string;
  author: string;
  description: string;
  pageCount: number;
  lastReadPage: number;
  status: ReadingStatus;
  hasCustomCover: boolean;
  dateAdded: number;
  dateLastOpened: number;
  fileSizeBytes: number;
  genreNames: string[];
}

/** Raw file bytes, stored separately from Book metadata (own table,
 *  so the bookshelf list query never has to load full PDF blobs). */
export interface BookFile {
  uuid: string; // matches Book.uuid
  pdfBlob: Blob;
  coverBlob: Blob;
}

export interface Bookmark {
  id: string;
  bookUuid: string;
  pageNumber: number;
  note: string;
  dateCreated: number;
}
