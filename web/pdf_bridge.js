// pdf_bridge.js
// Wraps pdf.js (loaded as a <script> in index.html) into a small
// promise-based API consumed via Dart JS interop (pdf_interop.dart).
// Every function here operates only on bytes already in memory —
// nothing is fetched over the network by this bridge.

window.pdfBridge = (function () {
  const { pdfjsLib } = globalThis;

  async function loadDocument(bytes) {
    const loadingTask = pdfjsLib.getDocument({ data: bytes });
    return await loadingTask.promise;
  }

  function getPageCount(doc) {
    return Promise.resolve(doc.numPages);
  }

  async function renderPageToPngBytes(doc, pageNumber, targetWidth) {
    const page = await doc.getPage(pageNumber);
    const baseViewport = page.getViewport({ scale: 1 });
    const scale = targetWidth / baseViewport.width;
    const viewport = page.getViewport({ scale });

    const canvas = document.createElement('canvas');
    canvas.width = viewport.width;
    canvas.height = viewport.height;
    const ctx = canvas.getContext('2d');

    await page.render({ canvasContext: ctx, viewport }).promise;

    return await new Promise((resolve) => {
      canvas.toBlob(async (blob) => {
        const buf = await blob.arrayBuffer();
        resolve(buf);
      }, 'image/png');
    });
  }

  async function extractPageText(doc, pageNumber) {
    const page = await doc.getPage(pageNumber);
    const content = await page.getTextContent();
    return content.items.map((item) => item.str).join(' ');
  }

  return { loadDocument, getPageCount, renderPageToPngBytes, extractPageText };
})();
