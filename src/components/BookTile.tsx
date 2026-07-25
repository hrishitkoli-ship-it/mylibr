import { useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import type { Book } from '../types';
import { BookCover } from './BookCover';
import { setCustomCover } from '../lib/importPdf';
import { libraryRepository } from '../db/libraryRepository';

interface Props {
  book: Book;
  onChanged: () => void;
}

export function BookTile({ book, onChanged }: Props) {
  const navigate = useNavigate();
  const [menuOpen, setMenuOpen] = useState(false);
  const coverInputRef = useRef<HTMLInputElement>(null);
  const pressTimer = useRef<number | undefined>(undefined);

  const openMenu = () => setMenuOpen(true);
  const closeMenu = () => setMenuOpen(false);

  const handlePointerDown = () => {
    pressTimer.current = window.setTimeout(openMenu, 500);
  };
  const cancelPress = () => {
    if (pressTimer.current) window.clearTimeout(pressTimer.current);
  };

  const handleCoverPick = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    await setCustomCover(book, file);
    onChanged();
  };

  const handleDelete = async () => {
    await libraryRepository.deleteBook(book.uuid);
    onChanged();
  };

  return (
    <div className="book-tile">
      <button
        className="book-tile__cover-btn"
        onClick={() => navigate(`/read/${book.uuid}`)}
        onContextMenu={(e) => {
          e.preventDefault();
          openMenu();
        }}
        onPointerDown={handlePointerDown}
        onPointerUp={cancelPress}
        onPointerLeave={cancelPress}
      >
        <BookCover uuid={book.uuid} title={book.title} />
      </button>

      <div className="book-tile__title" title={book.title}>
        {book.title}
      </div>
      {book.author && <div className="book-tile__author">{book.author}</div>}
      {book.genreNames.length > 0 && (
        <div className="book-tile__genres">
          {book.genreNames.slice(0, 2).map((g) => (
            <span key={g} className="chip">
              {g}
            </span>
          ))}
        </div>
      )}

      {menuOpen && (
        <div className="book-menu-overlay" onClick={closeMenu}>
          <div className="book-menu" onClick={(e) => e.stopPropagation()}>
            <button
              onClick={() => {
                closeMenu();
                coverInputRef.current?.click();
              }}
            >
              🖼️ Set custom cover
            </button>
            <button className="book-menu__danger" onClick={() => { closeMenu(); handleDelete(); }}>
              🗑️ Delete book
            </button>
            <button onClick={closeMenu}>Cancel</button>
          </div>
        </div>
      )}

      <input
        ref={coverInputRef}
        type="file"
        accept="image/*"
        className="visually-hidden"
        onChange={handleCoverPick}
      />
    </div>
  );
}
