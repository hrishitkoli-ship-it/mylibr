# MyLibrary — Architecture

100% offline, local-only personal PDF library and reader. No backend,
no API keys, no network calls anywhere in the app.

## Stack

| Concern            | Choice                          | Why |
|---------------------|----------------------------------|-----|
| Framework            | Flutter                         | Single codebase, iOS + Android, mature PDF/TTS plugin ecosystem |
| Local database       | ObjectBox                       | Fast on-device NoSQL, native relations (ToMany/ToOne), zero server component (ObjectBox Sync add-on is not used) |
| File storage          | `path_provider` app documents dir | Sandboxed per-app storage, survives app restarts, private to the app |
| PDF rendering         | `pdfx`                          | Local PdfDocument/PdfPage rendering for cover thumbnails and page view, no cloud rendering |
| PDF text extraction   | `syncfusion_flutter_pdf`        | Pure on-device text extraction (Community License, free for small teams — verify eligibility) |
| TTS                   | `flutter_tts`                   | Bridges to Android `TextToSpeech` / iOS `AVSpeechSynthesizer` — both built into the OS, free, offline |
| State management      | `provider`                      | Lightweight, sufficient for this app's scope |
| File/image picking    | `file_picker`, `image_picker`   | Native OS pickers, no upload step |

## Directory layout on device

```
<AppDocumentsDirectory>/
  objectbox/              # ObjectBox database files
  library/
    pdfs/<uuid>.pdf        # imported PDFs, copied from wherever the user picked them
    covers/<uuid>.png      # auto-extracted page-1 render OR user-picked custom cover
```

Every book gets a UUID at import time; that UUID is the filename for
both its PDF and its cover, so lookups never depend on user-editable
fields like title.

## Data flow: import

```
User taps "Add PDF"
  -> file_picker native chooser (local filesystem / on-device Files app)
  -> LocalStorageService.importPdf(): copy into <sandbox>/library/pdfs/<uuid>.pdf
  -> CoverService.getPageCount(): open with pdfx, read pagesCount
  -> CoverService.autoGenerateCover(): render page 1 -> PNG -> <sandbox>/library/covers/<uuid>.png
  -> Book record built and persisted via LibraryRepository.addBook() (ObjectBox)
  -> UI refreshes bookshelf grid
```

No step in this pipeline leaves the device.

## Data flow: TTS playback

```
User taps Play in reader toolbar
  -> PdfTextService.extractAllPages(): syncfusion parses PDF locally, returns List<String>
  -> TtsService.loadDocumentAndPlay(): flutter_tts.speak() on current page's text
  -> on utterance completion, auto-advance to next page's text
  -> PDF view jumps to match the page currently being spoken
  -> user controls: pause/resume, stop, speech rate slider, pitch slider
```

flutter_tts talks directly to the OS TTS engine; there is no
network round-trip and no per-character cost.

## Local database schema (ObjectBox)

### Book
| Field | Type | Notes |
|---|---|---|
| id | int (auto) | ObjectBox internal id |
| uuid | String | Stable id, used for filenames |
| title, author, description | String | User-editable metadata |
| filePath | String | Absolute path to local PDF |
| coverPath | String | Absolute path to local cover PNG |
| hasCustomCover | bool | True once user overrides auto cover |
| pageCount | int | From pdfx at import time |
| lastReadPage | int | For resume-reading |
| dbStatus | int | Persisted enum index: 0=unread, 1=reading, 2=completed |
| dateAdded, dateLastOpened | int (epoch ms) | |
| fileSizeBytes | int | For storage-usage UI |
| genres | ToMany\<Genre\> | Many-to-many |
| bookmarks | ToMany\<Bookmark\> | One-to-many |

### Genre
| Field | Type | Notes |
|---|---|---|
| id | int (auto) | |
| name | String (unique) | e.g. "Sci-Fi" |
| colorHex | String | For UI chip color |
| books | ToMany\<Book\> (backlink) | |

### Bookmark
| Field | Type | Notes |
|---|---|---|
| id | int (auto) | |
| pageNumber | int | |
| note | String | Optional |
| dateCreated | int (epoch ms) | |
| book | ToOne\<Book\> | |

## State management

`LibraryState` (a `ChangeNotifier`) is the single source of truth for
the bookshelf: it owns the in-memory `books` list, search query, and
import/cover/status mutation methods, and calls `LibraryRepository`
for every persistence operation. Screens `watch<LibraryState>()` via
`provider` and rebuild on `notifyListeners()`.

## Explicitly out of scope / not used

- No REST/GraphQL client of any kind.
- No Firebase, Supabase, or any BaaS.
- No cloud TTS (Google Cloud TTS, ElevenLabs, Amazon Polly, etc.).
- No analytics or crash-reporting SDKs that phone home.
- No ObjectBox Sync (that's ObjectBox's paid cloud-sync product —
  this app only uses the free embedded database).
