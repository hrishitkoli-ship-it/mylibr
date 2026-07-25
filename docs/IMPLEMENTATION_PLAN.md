# MyLibrary (Web) — Implementation Plan

## Phase 0 — Project setup
1. `flutter config --enable-web`, `flutter pub get`.
2. Confirm `flutter run -d chrome` launches the default scaffold.
3. Verify `web/pdf_bridge.js` and `web/tts_bridge.js` are wired into
   `web/index.html` and that `pdfjsLib` is defined at load time
   (check browser console for errors).

## Phase 1 — Local storage layer (no UI yet)
1. Implement `SembastDb` (IndexedDB bootstrap via sembast_web).
2. Implement `LocalBlobStore` (base64 blob persistence for PDFs/covers).
3. Implement `Book`, `Bookmark` plain-Dart models + `LibraryRepository`.
4. Sanity-check: write a dummy Book, reload the page, read it back —
   confirms IndexedDB persistence survives a reload before any UI exists.

## Phase 2 — PDF import + cover generation
1. Wire `file_picker` with `withData: true` for web byte access.
2. Implement the pdf.js JS interop (`pdf_interop.dart` + `pdf_bridge.js`).
3. Implement `CoverService.autoGenerateCover()` (page-1 canvas render -> PNG).
4. Test with PDFs of varying page sizes/orientations.
5. Implement `CoverService.saveCustomCover()` via `image_picker` (web
   gallery/file picker).

## Phase 3 — Bookshelf UI
1. Build `BookshelfScreen` grid, rendering covers with `Image.memory`
   from blob-store bytes (no `File` access on web).
2. Wire search to `LibraryRepository.search()` (in-memory filter).
3. Long-press bottom sheet: custom cover, delete.
4. Genre chips + a simple "manage genres" editor writing to
   `Book.genreNames`.

## Phase 4 — PDF reader
1. Render each page via `pdf.js` canvas -> PNG -> `Image.memory`,
   wrapped in `InteractiveViewer` for pinch/scroll zoom.
2. Page nav bar (prev/next) since there's no native paginated PDF
   widget on web.
3. Persist `lastReadPage` on screen dispose.
4. Auto-transition `unread -> reading` on first open.

## Phase 5 — On-device (in-browser) TTS
1. Implement `PdfTextService` via `pdf.js getTextContent()`.
2. Implement `TtsService` wrapping `window.speechSynthesis` via
   `tts_interop.dart` / `tts_bridge.js`.
3. Build the bottom TTS toolbar: play/pause, stop, speed + pitch sliders.
4. Test across Chrome, Firefox, and Safari — voice availability and
   `SpeechSynthesisUtterance` behavior differs meaningfully between
   browsers (Safari in particular has historically had quirks with
   `pause()`/`resume()`).
5. Handle pages with no extractable text (scanned/image-only PDFs) —
   skip silently rather than speaking an empty utterance.

## Phase 6 — Polish / MVP hardening
1. Empty states: empty library, empty search results.
2. Error states: corrupted PDF, 0-page PDF, blob read failures.
3. Confirm-delete dialog before `LibraryState.deleteBook()`.
4. Basic settings: default TTS rate/pitch, persisted via a small
   sembast `settings` store.
5. PWA polish: app icon, `manifest.json` (already scaffolded),
   "Add to Home Screen" support.
6. Storage-usage indicator, since there's no OS-level "app storage"
   view for a web app the way there is on mobile.

## Phase 7 — Testing checklist
See `docs/SETUP.md` — web-specific checklist (cross-browser TTS,
IndexedDB persistence across reload/restart, offline verification).

## Known platform notes
- **Cross-browser TTS differences**: Safari and Firefox have had
  historical quirks with `speechSynthesis.pause()`/`resume()` and
  voice-list loading timing (`onvoiceschanged`). Test on all three
  major engines before relying on pause/resume specifically.
- **IndexedDB storage limits**: browsers may prompt for persistent
  storage permission or evict data under storage pressure — consider
  calling `navigator.storage.persist()` (would need a small additional
  interop call) so the library isn't silently evicted.
- **Large PDFs**: `extractAllPages()` parses the whole document
  up-front for continuous TTS playback; for very large books consider
  lazy per-page extraction to avoid a large upfront CPU spike, same
  caveat as the mobile build.
- **pdf.js CDN dependency in dev**: see SETUP.md's vendoring section
  before treating a build as genuinely zero-network.
