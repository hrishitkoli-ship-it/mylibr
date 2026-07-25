import { useEffect, useRef, useState, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { PDFDocumentProxy } from 'pdfjs-dist';
import { pdfService } from '../lib/pdfService';
import { libraryRepository } from '../db/libraryRepository';
import { TtsController, type TtsPlaybackState } from '../lib/ttsController';
import { TtsToolbar } from '../components/TtsToolbar';
import type { Book } from '../types';

export function ReaderPage() {
  const { uuid } = useParams<{ uuid: string }>();
  const navigate = useNavigate();

  const [book, setBook] = useState<Book | null>(null);
  const [doc, setDoc] = useState<PDFDocumentProxy | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [, forceRender] = useState(0);

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const ttsRef = useRef<TtsController>(new TtsController());
  const [ttsState, setTtsState] = useState<TtsPlaybackState>('stopped');
  const [ttsPage, setTtsPage] = useState(0);

  // Load the book + PDF once.
  useEffect(() => {
    if (!uuid) return;
    let cancelled = false;

    (async () => {
      const b = await libraryRepository.getBook(uuid);
      const file = await libraryRepository.getBookFile(uuid);
      if (!b || !file || cancelled) {
        setLoading(false);
        return;
      }
      setBook(b);
      const startPage = b.lastReadPage > 0 ? b.lastReadPage : 1;
      setCurrentPage(startPage);

      const bytes = await file.pdfBlob.arrayBuffer();
      const pdfDoc = await pdfService.open(bytes);
      if (cancelled) return;
      setDoc(pdfDoc);
      setLoading(false);
    })();

    return () => {
      cancelled = true;
    };
  }, [uuid]);

  // TTS controller wiring.
  useEffect(() => {
    const tts = ttsRef.current;
    tts.onStateChanged = (s) => setTtsState(s);
    tts.onPageChanged = (p) => setTtsPage(p);
    tts.onFinished = () => forceRender((n) => n + 1);
    return () => tts.dispose();
  }, []);

  // Render current page to canvas whenever it changes.
  const renderPage = useCallback(
    async (pageNum: number) => {
      if (!doc || !canvasRef.current) return;
      const page = await doc.getPage(pageNum);
      const viewport = page.getViewport({ scale: 1.5 });
      const canvas = canvasRef.current;
      const ctx = canvas.getContext('2d');
      if (!ctx) return;
      canvas.width = viewport.width;
      canvas.height = viewport.height;
      await page.render({ canvasContext: ctx, viewport }).promise;
    },
    [doc],
  );

  useEffect(() => {
    renderPage(currentPage);
  }, [currentPage, renderPage]);

  // Keep TTS page in sync with the visible page while TTS drives navigation.
  useEffect(() => {
    if (ttsPage > 0 && ttsPage !== currentPage) {
      setCurrentPage(ttsPage);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ttsPage]);

  // Persist last-read page on unmount.
  useEffect(() => {
    return () => {
      if (!book || !uuid) return;
      const updated: Book = {
        ...book,
        lastReadPage: currentPage,
        dateLastOpened: Date.now(),
        status: book.status === 'unread' ? 'reading' : book.status,
      };
      libraryRepository.updateBook(updated);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPage]);

  const goToPage = (page: number) => {
    if (!doc) return;
    const clamped = Math.min(Math.max(page, 1), doc.numPages);
    setCurrentPage(clamped);
  };

  const totalPages = doc?.numPages ?? book?.pageCount ?? 0;

  if (loading) {
    return <div className="reader-loading">Loading…</div>;
  }
  if (!book || !doc) {
    return <div className="reader-loading">Book not found.</div>;
  }

  return (
    <div className="reader-page">
      <header className="reader-header">
        <button onClick={() => navigate('/')} aria-label="Back">
          ← Back
        </button>
        <h2 className="reader-header__title">{book.title}</h2>
      </header>

      <div className="reader-canvas-wrap">
        <canvas ref={canvasRef} className="reader-canvas" />
      </div>

      <div className="page-nav">
        <button onClick={() => goToPage(currentPage - 1)} disabled={currentPage <= 1}>
          ‹
        </button>
        <span>
          Page {currentPage} / {totalPages}
        </span>
        <button onClick={() => goToPage(currentPage + 1)} disabled={currentPage >= totalPages}>
          ›
        </button>
      </div>

      <TtsToolbar
        tts={ttsRef.current}
        state={ttsState}
        ttsCurrentPage={ttsRef.current.currentPage}
        fallbackPage={currentPage}
        onPlay={() => doc && ttsRef.current.loadDocumentAndPlay(doc, currentPage)}
        onRateChange={(rate) => {
          ttsRef.current.setSpeechRate(rate);
          forceRender((n) => n + 1);
        }}
        onPitchChange={(pitch) => {
          ttsRef.current.setPitch(pitch);
          forceRender((n) => n + 1);
        }}
        forceUpdate={() => forceRender((n) => n + 1)}
      />
    </div>
  );
}
