# MyLibrary (Web) — Architecture

100% offline-capable, browser-local personal PDF library and reader.
No backend, no API keys, no network calls except the one-time load of
the app's own static assets (and pdf.js from a CDN in dev — see
SETUP.md for pinning it locally for production).

## Stack

| Concern            | Choice                          | Why |
|---------------------|----------------------------------|-----|
| Framework            | Flutter Web                     | Reuses the same Dart UI code across the previous mobile scaffold |
| Local database       | sembast_web (IndexedDB)          | Schemaless, JSON-safe, browser-native persistent storage — survives reloads |
| Blob storage          | IndexedDB via sembast (base64)   | PDFs and cover PNGs stored as browser-local records, never uploaded |
| PDF rendering & text  | pdf.js via JS interop            | Mozilla's PDF engine, runs entirely client-side in the tab |
| TTS                   | Web Speech API (`speechSynthesis`) | Native browser TTS, free, no network call at speak-time |
| State management      | `provider`                      | Same as mobile scaffold |
| File/image picking    | `file_picker`, `image_picker`   | Both have web implementations backed by the native browser file input |

## Why not reuse the mobile-native packages directly

| Mobile package | Web replacement | Reason |
|---|---|---|
| ObjectBox | sembast_web | ObjectBox has no web/WASM target |
| `path_provider` sandbox dir | IndexedDB (via sembast/blob store) | No filesystem access in the browser sandbox |
| `pdfx` (native render) | pdf.js JS interop | No native PDF renderer available on web |
| `syncfusion_flutter_pdf` (native text extraction) | pdf.js `getTextContent()` | Syncfusion's Flutter text extraction targets native platforms |
| `flutter_tts` | Web Speech API interop | flutter_tts's web support is limited; calling `speechSynthesis` directly is more reliable |

## Directory / storage layout (browser)

Everything lives in IndexedDB, scoped to the site's origin:

```
IndexedDB: mylibrary.db
  store: books      -> { uuid, title, author, ..., pdfBlobKey, coverBlobKey }
  store: bookmarks  -> { id, bookUuid, pageNumber, note, ... }
  store: blobs       -> { "pdf:<uuid>": {data: base64}, "cover:<uuid>": {data: base64} }
```

Clearing browser site data removes the entire library — this is
expected for a local-only app and should be called out in the UI
(e.g. an "export/backup" feature is a natural Phase 2 addition, since
there is no cloud copy).

## Data flow: import

```
User taps "Add PDF"
  -> file_picker web file input, bytes read directly into memory (withData: true)
  -> LocalBlobStore.savePdf(): base64-encode, write to IndexedDB via sembast
  -> pdf.js opens the in-memory bytes (pdfBridge.loadDocument)
  -> pdf.js renders page 1 to a <canvas>, exported as PNG bytes
  -> LocalBlobStore.saveCover(): base64-encode, write to IndexedDB
  -> Book record written to sembast 'books' store
  -> UI refreshes bookshelf grid (Image.memory from blob bytes)
```

## Data flow: TTS playback

```
User taps Play in reader toolbar
  -> pdf.js getTextContent() per page (PdfTextService.extractAllPages)
  -> ttsBridge.speak(text, rate, pitch, volume) -> window.speechSynthesis
  -> utterance.onend -> auto-advance to next page's text + re-render that page
  -> user controls: pause/resume, stop, speech rate slider, pitch slider
```

## Local database schema

Same logical shape as the mobile scaffold, adapted to plain
JSON-serializable Dart classes (sembast has no code-generated schema):

### Book
`uuid, title, author, description, pdfBlobKey, coverBlobKey,
hasCustomCover, pageCount, lastReadPage, status (0/1/2), dateAdded,
dateLastOpened, fileSizeBytes, genreNames: List<String>`

Genres are stored as a plain string list on `Book` rather than a
separate join table — sembast has no native relations, and a personal
library's tag set is small enough that in-memory filtering (see
`LibraryRepository.search`) is fast without an index.

### Bookmark
`id, bookUuid, pageNumber, note, dateCreated`

## Explicitly out of scope / not used

- No REST/GraphQL client, no BaaS (Firebase/Supabase/etc).
- No cloud TTS (Google Cloud TTS, ElevenLabs, Amazon Polly).
- No analytics/crash-reporting SDKs.
- pdf.js is loaded from a CDN in this scaffold for development
  convenience; for a genuinely zero-network production deploy, vendor
  it into `web/pdfjs/` and update the `<script>` src in
  `web/index.html` (see SETUP.md).
