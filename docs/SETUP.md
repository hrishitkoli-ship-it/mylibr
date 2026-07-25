# MyLibrary (Web) — Setup

## Prerequisites
- Flutter SDK (stable channel) with web support enabled:
  ```bash
  flutter config --enable-web
  ```
- A Chromium-based browser for local dev (`flutter run -d chrome`)

## First-time setup
```bash
flutter pub get
flutter run -d chrome
```
No code generation step is required — sembast is schemaless, so
there's no ObjectBox-style build_runner step in the web build.

## Building for production
```bash
flutter build web --release
```
Output lands in `build/web/` — deploy that directory to any static
host (Vercel, Netlify, GitHub Pages, etc). Since the app is fully
client-side and local-only, no server-side runtime is needed.

## Vendoring pdf.js for a fully offline production build
This scaffold loads pdf.js from cdnjs in `web/index.html` for
development convenience. For a production deploy with zero external
requests at runtime:

1. Download `pdf.min.js` and `pdf.worker.min.js` from the pdf.js
   releases (matching version, currently 4.4.168) into `web/pdfjs/`.
2. Update `web/index.html`:
   ```html
   <script src="pdfjs/pdf.min.js"></script>
   <script>
     pdfjsLib.GlobalWorkerOptions.workerSrc = 'pdfjs/pdf.worker.min.js';
   </script>
   ```
3. Rebuild — `flutter build web` will bundle `web/pdfjs/` as static
   assets automatically.

## Browser storage notes
- All data (PDFs, covers, metadata) lives in IndexedDB, scoped to
  the deployed origin. Different browsers / private-browsing sessions
  will not share the library.
- IndexedDB has no fixed hard cap in most browsers, but is still
  subject to overall device storage and browser eviction policies for
  rarely-used sites — a large PDF library on a phone browser could hit
  practical limits sooner than on desktop.
- There is currently no export/backup feature; clearing site data
  deletes the whole library. Flag this to users in-app.

## Verifying zero runtime network dependency
Load the deployed app once (to cache assets), then go offline
(devtools "Offline" throttling, or airplane mode on mobile) and run
the full import -> read -> TTS flow. Everything should keep working
except any use of the CDN-hosted pdf.js in the dev config above — the
vendored setup removes that last external dependency too.

## Testing checklist (adapted for web)
- [ ] Import PDF works with the browser in offline mode (after first asset load)
- [ ] Library persists across page reloads (IndexedDB)
- [ ] Library persists across full browser restart
- [ ] Cover renders correctly for portrait, landscape, multi-column PDFs
- [ ] Custom cover override persists after reload
- [ ] Search matches partial title, author, and genre substrings
- [ ] TTS play/pause/stop/speed/pitch work in Chrome, Firefox, Safari
- [ ] Deleting a book removes its PDF and cover blobs from IndexedDB
- [ ] Large PDF (100+ pages) import and page-render performance is acceptable
