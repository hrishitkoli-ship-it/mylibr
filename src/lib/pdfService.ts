import * as pdfjsLib from 'pdfjs-dist';
import type { PDFDocumentProxy } from 'pdfjs-dist';
import pdfjsWorker from 'pdfjs-dist/build/pdf.worker.min.mjs?url';

// Worker is bundled by Vite as a static asset — no CDN fetch at
// runtime, works fully offline once the app itself is loaded.
pdfjsLib.GlobalWorkerOptions.workerSrc = pdfjsWorker;

export const pdfService = {
  async open(bytes: ArrayBuffer): Promise<PDFDocumentProxy> {
    const loadingTask = pdfjsLib.getDocument({ data: bytes });
    return loadingTask.promise;
  },

  /** Renders [pageNumber] (1-indexed) to a PNG Blob at [targetWidth]px wide. */
  async renderPageToPng(
    doc: PDFDocumentProxy,
    pageNumber: number,
    targetWidth = 480,
  ): Promise<Blob> {
    const page = await doc.getPage(pageNumber);
    const baseViewport = page.getViewport({ scale: 1 });
    const scale = targetWidth / baseViewport.width;
    const viewport = page.getViewport({ scale });

    const canvas = document.createElement('canvas');
    canvas.width = viewport.width;
    canvas.height = viewport.height;
    const ctx = canvas.getContext('2d');
    if (!ctx) throw new Error('Could not get canvas 2D context');

    await page.render({ canvasContext: ctx, viewport }).promise;

    return new Promise((resolve, reject) => {
      canvas.toBlob((blob) => {
        if (blob) resolve(blob);
        else reject(new Error('Failed to encode page render as PNG'));
      }, 'image/png');
    });
  },

  async extractPageText(doc: PDFDocumentProxy, pageNumber: number): Promise<string> {
    const page = await doc.getPage(pageNumber);
    const content = await page.getTextContent();
    const raw = content.items.map((item) => ('str' in item ? item.str : '')).join(' ');
    return cleanForSpeech(raw);
  },

  async extractAllPages(doc: PDFDocumentProxy): Promise<string[]> {
    const pages: string[] = [];
    for (let i = 1; i <= doc.numPages; i++) {
      pages.push(await this.extractPageText(doc, i));
    }
    return pages;
  },
};

function cleanForSpeech(raw: string): string {
  return raw.replace(/\s+/g, ' ').trim();
}
