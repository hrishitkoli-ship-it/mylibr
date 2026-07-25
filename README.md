# MyLibrary

A 100% offline personal PDF library and reader. Import PDFs, get
auto-generated covers from page 1 (or pick your own), organize with
genre tags, and listen via free on-device text-to-speech. No cloud
backend, no API keys, no network calls at runtime.

- [Architecture & schema](docs/ARCHITECTURE.md)
- [Implementation plan](docs/IMPLEMENTATION_PLAN.md)
- [Setup & Vercel deployment](docs/SETUP.md)

## Stack
React + Vite + TypeScript · Dexie.js (IndexedDB) · pdfjs-dist
(rendering + text extraction) · Web Speech API (TTS) ·
react-router-dom

## Quick start
```bash
npm install
npm run dev
```

## Deploy
```bash
vercel --prod
```
or import the repo directly in the Vercel dashboard — `vercel.json`
is pre-configured for a static Vite build, no extra setup needed.

## Status
MVP scaffold — see `docs/IMPLEMENTATION_PLAN.md` for build phases and
the testing checklist.
