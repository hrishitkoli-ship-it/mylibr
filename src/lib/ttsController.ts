import type { PDFDocumentProxy } from 'pdfjs-dist';
import { pdfService } from './pdfService';

export type TtsPlaybackState = 'stopped' | 'playing' | 'paused';

/**
 * Wraps window.speechSynthesis — built into every modern browser,
 * uses the OS/browser's own voices, no API key, no network call at
 * speak-time. This is the direct web equivalent of Android
 * TextToSpeech / iOS AVSpeechSynthesizer.
 */
export class TtsController {
  state: TtsPlaybackState = 'stopped';
  speechRate = 1.0; // UI-constrained to 0.5 - 2.0
  pitch = 1.0; // 0 - 2
  volume = 1.0; // 0 - 1

  private pages: string[] = [];
  private currentPageIndex = 0;

  onPageChanged?: (pageNumber: number) => void;
  onStateChanged?: (state: TtsPlaybackState) => void;
  onFinished?: () => void;

  private setState(s: TtsPlaybackState) {
    this.state = s;
    this.onStateChanged?.(s);
  }

  async loadDocumentAndPlay(doc: PDFDocumentProxy, startPage: number): Promise<void> {
    this.pages = await pdfService.extractAllPages(doc);
    this.currentPageIndex = Math.min(Math.max(startPage - 1, 0), this.pages.length - 1);
    this.speakCurrentPage();
  }

  private speakCurrentPage(): void {
    if (this.currentPageIndex >= this.pages.length) {
      this.setState('stopped');
      this.onFinished?.();
      return;
    }
    this.onPageChanged?.(this.currentPageIndex + 1);
    const text = this.pages[this.currentPageIndex];
    if (!text.trim()) {
      this.currentPageIndex++;
      this.speakCurrentPage();
      return;
    }

    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = this.speechRate;
    utterance.pitch = this.pitch;
    utterance.volume = this.volume;
    utterance.onstart = () => this.setState('playing');
    utterance.onend = () => {
      if (this.state === 'stopped') return; // user stopped manually
      this.currentPageIndex++;
      this.speakCurrentPage();
    };
    window.speechSynthesis.speak(utterance);
  }

  pause(): void {
    window.speechSynthesis.pause();
    this.setState('paused');
  }

  resume(): void {
    window.speechSynthesis.resume();
    this.setState('playing');
  }

  stop(): void {
    window.speechSynthesis.cancel();
    this.setState('stopped');
  }

  setSpeechRate(rate: number): void {
    this.speechRate = Math.min(Math.max(rate, 0.5), 2.0);
  }

  setPitch(value: number): void {
    this.pitch = Math.min(Math.max(value, 0.5), 2.0);
  }

  get currentPage(): number {
    return this.currentPageIndex + 1;
  }

  get totalPages(): number {
    return this.pages.length;
  }

  dispose(): void {
    window.speechSynthesis.cancel();
  }
}
