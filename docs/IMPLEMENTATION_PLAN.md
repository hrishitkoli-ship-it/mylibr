# MyLibrary (React) — Implementation Plan

## Phase 0 — Project setup
1. `npm install`, `npm run dev`, confirm the default scaffold loads.
2. `npm run build` once up front to confirm the toolchain (TS + Vite)
   is healthy before adding features.

## Phase 1 — Local storage layer (no UI yet)
1. `src/db/database.ts` — Dexie schema (`books`, `bookFiles`, `bookmarks`).
2. `src/db/libraryRepository.ts` — CRUD + search.
3. Sanity check: add a dummy book from the browser console, reload,
   confirm it's still there via DevTools → Application → IndexedDB.

## Phase 2 — PDF import + cover generation
1. `src/lib/pdfService.ts` — pdfjs-dist wrapper (open, render, extract).
2. `src/lib/importPdf.ts` — full pipeline: file → bytes → cover PNG → Dexie write.
3. Test with PDFs of varying page sizes/orientations — cover aspect
   ratio depends on page dimensions.
4. Custom cover override via a plain `<input type="file" accept="image/*">`.

## Phase 3 — Bookshelf UI
1. `src/pages/BookshelfPage.tsx` — grid, search bar, import button.
2. `src/components/BookTile.tsx` / `BookCover.tsx` — cover rendering
   via `useObjectUrl` (Blob → object URL, revoked on unmount).
3. Long-press / right-click menu: custom cover, delete.
4. Genre chips (rendered from `Book.genreNames`).

## Phase 4 — PDF reader
1. `src/pages/ReaderPage.tsx` — canvas-based page rendering via pdf.js.
2. Prev/next page nav bar.
3. Persist `lastReadPage` on unmount; auto-transition `unread -> reading`.

## Phase 5 — On-device (in-browser) TTS
1. `src/lib/ttsController.ts` — wraps `window.speechSynthesis` directly.
2. `src/components/TtsToolbar.tsx` — play/pause, stop, speed + pitch sliders.
3. Test across Chrome, Firefox, Safari — voice availability and
   `SpeechSynthesisUtterance` pause/resume behavior differs between
   browsers; Safari has historically been the trickiest.
4. Skip pages with no extractable text (scanned/image-only PDFs)
   rather than speaking an empty utterance — already handled in
   `TtsController.speakCurrentPage()`.

## Phase 6 — Polish / MVP hardening
1. Empty states, error states (corrupted PDF, 0-page PDF).
2. Confirm-delete before `libraryRepository.deleteBook()`.
3. Settings: default TTS rate/pitch persisted in a small Dexie
   `settings` table or `localStorage`.
4. PWA polish: icons (`public/manifest.json` is scaffolded), "Add to
   Home Screen" support.
5. Storage-usage indicator (sum `fileSizeBytes` across books).

## Phase 7 — Deploy
1. Push to GitHub.
2. Import into Vercel (auto-detects Vite via `vercel.json`).
3. Deploy — confirm the production URL serves correctly and IndexedDB
   persistence works on the deployed origin.

## Phase 8 — Testing checklist
See `docs/SETUP.md` for the full checklist (cross-browser TTS,
IndexedDB persistence, offline verification, Vercel parity).

## Known platform notes
- **Cross-browser TTS differences**: Safari and Firefox have had
  historical quirks with `speechSynthesis.pause()`/`resume()` and
  voice-list load timing (`onvoiceschanged`). Test all three engines
  before relying heavily on pause/resume.
- **IndexedDB storage limits**: browsers may evict data under storage
  pressure. Calling `navigator.storage.persist()` on first load
  reduces (doesn't eliminate) this risk.
- **Large PDFs**: `pdfService.extractAllPages()` parses the whole
  document up front for continuous TTS playback. For very large books,
  consider lazy per-page extraction to avoid a large upfront CPU spike.
- **pdf.worker chunk size**: pdfjs-dist's worker is ~1.3MB
  unminified-equivalent; it's a separate lazy-loaded chunk, not part
  of the initial bundle, so it doesn't block first paint.
