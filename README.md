# MyLibrary

A 100% offline personal PDF library and reader. Import PDFs, get
auto-generated covers from page 1 (or pick your own), organize with
genre tags, and listen via free on-device text-to-speech. No cloud
backend, no API keys, no network calls.

- [Architecture & schema](docs/ARCHITECTURE.md)
- [Implementation plan](docs/IMPLEMENTATION_PLAN.md)
- [Setup instructions](docs/SETUP.md)

## Stack
Flutter · ObjectBox (local DB) · pdfx (rendering) ·
syncfusion_flutter_pdf (text extraction) · flutter_tts (native TTS) ·
provider (state)

## Status
MVP scaffold — see `docs/IMPLEMENTATION_PLAN.md` for build phases and
the testing checklist.
