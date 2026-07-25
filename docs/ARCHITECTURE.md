# MyLibrary (React) — Architecture

100% offline-capable, browser-local personal PDF library and reader,
built as a static React app deployable to Vercel. No backend, no API
keys, no network calls except the one-time load of the app's own
static assets.

## Stack

| Concern            | Choice                    | Why |
|---------------------|----------------------------|-----|
| Framework            | React + Vite + TypeScript | Standard, fast dev/build, deploys to Vercel as a zero-config static site |
| Local database       | Dexie.js (IndexedDB)      | Well-typed wrapper over native IndexedDB, no server, no sync |
| Blob storage          | IndexedDB (native Blob values, via Dexie) | PDFs and cover images stored as real Blobs — cheaper than base64 |
| PDF rendering & text  | pdfjs-dist (npm package)  | Mozilla's PDF engine, runs client-side; ships as a normal dependency, no manual interop layer |
| TTS                   | Web Speech API (`speechSynthesis`) | Native browser TTS, free, no network call at speak-time |
| Routing               | react-router-dom (`HashRouter`) | Hash-based routing needs no server rewrite rules on Vercel |
| State                 | Local component state + Dexie as source of truth | No global store needed at this scope |

## Why this replaced the Flutter Web attempt

Flutter Web has no native PDF renderer, no native TTS bridge, and no
IndexedDB-native database — every one of those required a hand-written
JS interop layer. React talks to `pdfjs-dist`, `Dexie`, and
`speechSynthesis` directly as normal library calls, with full
TypeScript types, no interop boilerplate, and a smaller/faster
production bundle.

## Directory / storage layout (browser)

Everything lives in IndexedDB, scoped to the deployed origin:

```
IndexedDB: mylibrary (Dexie)
  table: books      -> { uuid, title, author, ..., pageCount, status, genreNames[] }
  table: bookFiles  -> { uuid, pdfBlob: Blob, coverBlob: Blob }
  table: bookmarks  -> { id, bookUuid, pageNumber, note, dateCreated }
```

Book metadata and file blobs are split into separate tables so
listing/searching the bookshelf never has to touch full PDF bytes.

## Data flow: import

```
User clicks "Add PDF" -> native <input type="file"> (src/pages/BookshelfPage.tsx)
  -> file.arrayBuffer() reads bytes directly in-memory, no upload
  -> pdfService.open() hands bytes to pdfjs-dist
  -> pdfService.renderPageToPng() renders page 1 to a <canvas>, exported as a PNG Blob
  -> libraryRepository.addBook() writes Book + BookFile (pdfBlob, coverBlob) to Dexie
  -> bookshelf grid re-queries and re-renders
```

## Data flow: TTS playback

```
User taps Play in the reader toolbar
  -> pdfService.extractAllPages() calls page.getTextContent() per page
  -> TtsController wraps window.speechSynthesis directly (src/lib/ttsController.ts)
  -> utterance.onend -> auto-advance to next page's text + re-render that page's canvas
  -> user controls: pause/resume, stop, speed slider, pitch slider
```

## Local database schema

### Book
`uuid, title, author, description, pageCount, lastReadPage,
status ('unread'|'reading'|'completed'), hasCustomCover, dateAdded,
dateLastOpened, fileSizeBytes, genreNames: string[]`

### BookFile
`uuid, pdfBlob: Blob, coverBlob: Blob`

### Bookmark
`id, bookUuid, pageNumber, note, dateCreated`

Genres are a plain string array on `Book` — no join table. A personal
library's tag set is small enough that in-memory filtering
(`libraryRepository.search`) is fast without an index.

## Explicitly out of scope / not used

- No REST/GraphQL client, no BaaS (Firebase/Supabase/etc).
- No cloud TTS (Google Cloud TTS, ElevenLabs, Amazon Polly).
- No analytics/crash-reporting SDKs.
- pdfjs-dist's worker is bundled locally by Vite (`?url` import) —
  not fetched from a CDN, so the production build has zero runtime
  network dependency beyond the initial page load.
