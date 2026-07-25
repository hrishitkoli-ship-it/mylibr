# MyLibrary — Implementation Plan

## Phase 0 — Project setup
1. Install Flutter SDK (stable channel), verify with `flutter doctor`.
2. `flutter create mylibr` if starting fresh, or use this repo's scaffold.
3. `flutter pub get`.
4. Generate ObjectBox bindings (required — `objectbox.g.dart` is not
   committed, it's generated from the `@Entity()` models):
   ```
   dart run build_runner build --delete-conflicting-outputs
   ```
5. Confirm build target setup:
   - Android: `minSdkVersion 21+` in `android/app/build.gradle`.
   - iOS: add microphone-free TTS entries are not needed (TTS playback
     doesn't require mic permission); confirm `ios/Podfile` platform
     is `13.0+`.

## Phase 1 — Local storage + database (no UI yet)
1. Implement `LocalStorageService` (done in `lib/services/`).
2. Implement `Book`, `Genre`, `Bookmark` ObjectBox entities.
3. Run build_runner, confirm `objectbox.g.dart` generates without errors.
4. Write a throwaway `main()` that opens the store, inserts a dummy
   `Book`, reads it back, and prints it — verifies the DB layer before
   any UI is built.

## Phase 2 — PDF import + cover generation
1. Wire up `file_picker` for PDF selection.
2. Implement `CoverService.autoGenerateCover()` using `pdfx`.
3. Test with a few real-world PDFs of different page sizes/orientations
   (cover rendering math depends on page aspect ratio).
4. Implement `CoverService.pickCustomCover()` using `image_picker`.
5. Verify both cover types render correctly in a simple `Image.file()`
   test widget before building the full grid.

## Phase 3 — Bookshelf UI
1. Build `BookshelfScreen` grid (`GridView.builder`, 3 columns).
2. Wire `LibraryState.importPdf()` to the FAB.
3. Add search bar wired to `LibraryState.setSearchQuery()` /
   `LibraryRepository.search()`.
4. Add long-press bottom sheet: set custom cover, delete book.
5. Add genre chips to each tile; build a simple "manage genres" dialog
   backed by `LibraryRepository.assignGenres()`.

## Phase 4 — PDF reader
1. Integrate `pdfx`'s `PdfViewPinch` + `PdfControllerPinch` for
   pinch-to-zoom page viewing.
2. Persist `lastReadPage` on screen dispose via
   `LibraryState.updateLastReadPage()`.
3. Auto-transition `ReadingStatus.unread -> reading` on first open;
   add a manual "Mark completed" action for `reading -> completed`.

## Phase 5 — On-device TTS
1. Implement `PdfTextService` (syncfusion text extraction).
2. Implement `TtsService` wrapping `flutter_tts`:
   - `setStartHandler` / `setCompletionHandler` / `setPauseHandler` /
     `setContinueHandler` for state tracking.
   - Auto-advance to next page's text on utterance completion.
3. Build the bottom TTS toolbar: play/pause, stop, speed slider,
   pitch slider, current-page indicator.
4. Test on a **physical device** for both platforms — TTS voice
   availability and behavior differs meaningfully between Android
   emulators and real hardware, and between iOS Simulator and a
   real iPhone.
5. Handle the "no page text" case (scanned/image-only PDFs have no
   extractable text) — TTS should skip such pages, not throw.

## Phase 6 — Polish / MVP hardening
1. Empty states: empty library, empty search results.
2. Error states: corrupted PDF import, PDF with 0 pages.
3. Confirm delete (dialog before `LibraryState.deleteBook()`).
4. Basic settings screen: default TTS speed/pitch persisted as app
   preferences (can reuse ObjectBox with a small `Settings` entity,
   or `shared_preferences` for simplicity — still fully local).
5. App icon, splash screen, basic onboarding copy.

## Phase 7 — Testing checklist
- [ ] Import PDF works with airplane mode on (proves zero network dependency)
- [ ] Cover renders correctly for portrait, landscape, and multi-column PDFs
- [ ] Custom cover override persists across app restarts
- [ ] Search matches partial title, author, and genre tag substrings
- [ ] TTS play/pause/stop/speed/pitch all function on a physical Android device
- [ ] TTS play/pause/stop/speed/pitch all function on a physical iOS device
- [ ] Reading status transitions correctly (unread -> reading -> completed)
- [ ] Deleting a book removes both its PDF and cover files from disk
- [ ] App data survives force-quit and relaunch (ObjectBox persistence)

## Known platform notes
- **flutter_tts pause/resume**: not all platforms support a true native
  "resume from paused position" — this scaffold's `resume()` re-speaks
  the current page from its start, which is the reliable cross-platform
  behavior. Document this in user-facing UI copy if it matters for UX.
- **syncfusion_flutter_pdf licensing**: free Community License has
  eligibility conditions (based on org revenue/team size) — confirm
  current terms at implementation time before shipping.
- **Large PDFs**: `extractAllPages()` parses the whole document
  up-front for continuous playback. For very large books (500+ pages),
  consider lazy per-page extraction instead to reduce memory/CPU spike
  on play.
