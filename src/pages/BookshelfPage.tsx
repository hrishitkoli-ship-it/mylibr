import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { libraryRepository } from '../db/libraryRepository';
import { importPdf } from '../lib/importPdf';
import type { Book } from '../types';
import { BookTile } from '../components/BookTile';

export function BookshelfPage() {
  const [books, setBooks] = useState<Book[]>([]);
  const [query, setQuery] = useState('');
  const [importing, setImporting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const navigate = useNavigate();

  const refresh = async (q = query) => {
    const results = q ? await libraryRepository.search(q) : await libraryRepository.allBooks();
    setBooks(results);
  };

  useEffect(() => {
    refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleQueryChange = async (value: string) => {
    setQuery(value);
    await refresh(value);
  };

  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = ''; // allow re-picking the same file later
    if (!file) return;
    setImporting(true);
    setError(null);
    try {
      const book = await importPdf(file);
      await refresh();
      navigate(`/read/${book.uuid}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Import failed');
    } finally {
      setImporting(false);
    }
  };

  return (
    <div className="bookshelf-page">
      <header className="bookshelf-header">
        <h1>MyLibrary</h1>
      </header>

      <div className="search-bar">
        <input
          type="search"
          placeholder="Search title, author, or genre…"
          value={query}
          onChange={(e) => handleQueryChange(e.target.value)}
        />
      </div>

      {error && <div className="error-banner">{error}</div>}

      {books.length === 0 ? (
        <div className="empty-state">No books yet — import a PDF to get started.</div>
      ) : (
        <div className="book-grid">
          {books.map((b) => (
            <BookTile key={b.uuid} book={b} onChanged={refresh} />
          ))}
        </div>
      )}

      <button
        className="fab"
        onClick={() => fileInputRef.current?.click()}
        disabled={importing}
      >
        {importing ? 'Importing…' : '+ Add PDF'}
      </button>
      <input
        ref={fileInputRef}
        type="file"
        accept="application/pdf"
        className="visually-hidden"
        onChange={handleImport}
      />
    </div>
  );
}
