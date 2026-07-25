# MyLibrary (React) — Setup

## Prerequisites
- Node.js 18+ and npm

## First-time setup
```bash
npm install
npm run dev
```
Opens the Vite dev server (default http://localhost:5173).

## Building for production
```bash
npm run build
```
Output lands in `dist/` — a fully static site. Preview it locally with:
```bash
npm run preview
```

## Deploying to Vercel
This repo includes `vercel.json` pre-configured for a static Vite build:
```json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "framework": "vite"
}
```

**Via the Vercel dashboard:** import the GitHub repo, Vercel
auto-detects the Vite framework preset and the settings above — no
extra configuration needed. Click Deploy.

**Via the Vercel CLI:**
```bash
npm i -g vercel
vercel
vercel --prod
```

No environment variables, no server functions, no database
provisioning — the entire app is static files plus browser-local
storage.

## Why HashRouter
The app uses `react-router-dom`'s `HashRouter` (URLs like
`/#/read/<uuid>`) instead of `BrowserRouter`. This means client-side
routes never 404 on a full page reload or direct link, with zero
Vercel rewrite-rule configuration required. If you'd rather have clean
URLs (`/read/<uuid>`), switch to `BrowserRouter` and add a
`vercel.json` rewrite:
```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

## Browser storage notes
- All data (PDFs, covers, metadata) lives in IndexedDB, scoped to the
  deployed origin. Different browsers / private-browsing sessions
  will not share the library.
- There is currently no export/backup feature; clearing site data
  deletes the whole library. Flag this to users in-app as a future
  improvement.
- Consider calling `navigator.storage.persist()` on first load to
  reduce the odds of the browser evicting data under storage pressure.

## Verifying zero runtime network dependency
Load the deployed app once (to cache assets), then go offline
(DevTools "Offline" throttling, or airplane mode on mobile) and run
the full import → read → TTS flow. Everything should keep working —
pdfjs-dist's worker is bundled as a local asset, not CDN-loaded.

## Testing checklist
- [ ] Import PDF works in offline mode (after first load)
- [ ] Library persists across page reloads and full browser restarts (IndexedDB)
- [ ] Cover renders correctly for portrait, landscape, multi-column PDFs
- [ ] Custom cover override persists after reload
- [ ] Search matches partial title, author, and genre substrings
- [ ] TTS play/pause/stop/speed/pitch work in Chrome, Firefox, Safari
- [ ] Deleting a book removes its PDF/cover blobs and bookmarks from IndexedDB
- [ ] Large PDF (100+ pages) import and page-render performance is acceptable
- [ ] Deployed Vercel build works identically to local `npm run preview`
