import 'package:flutter_tts/flutter_tts.dart';
import 'pdf_text_service.dart';

enum TtsPlaybackState { stopped, playing, paused }

/// Thin wrapper around flutter_tts, which itself bridges to:
///  - Android: android.speech.tts.TextToSpeech (built-in, free)
///  - iOS: AVSpeechSynthesizer (built-in, free)
/// No API keys, no network requests, no per-character billing.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  final PdfTextService _textService;

  TtsPlaybackState state = TtsPlaybackState.stopped;
  double speechRate = 0.5; // 0.0 - 1.0 (flutter_tts normalized range)
  double pitch = 1.0; // 0.5 - 2.0
  double volume = 1.0; // 0.0 - 1.0

  List<String> _pages = [];
  int _currentPageIndex = 0;
  void Function(int pageIndex)? onPageChanged;
  void Function()? onFinished;

  TtsService(this._textService) {
    _tts.setStartHandler(() => state = TtsPlaybackState.playing);
    _tts.setCancelHandler(() => state = TtsPlaybackState.stopped);
    _tts.setPauseHandler(() => state = TtsPlaybackState.paused);
    _tts.setContinueHandler(() => state = TtsPlaybackState.playing);

    // When one page's utterance finishes, auto-advance to the next
    // page for continuous "read the book aloud" playback.
    _tts.setCompletionHandler(_onUtteranceComplete);
  }

  Future<void> init() async {
    await _tts.setSpeechRate(speechRate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(volume);
    await _tts.awaitSpeakCompletion(true);
  }

  /// Loads the full document text (page-by-page) so playback can
  /// auto-advance, and begins speaking from [startPage] (1-indexed).
  Future<void> loadDocumentAndPlay({
    required String pdfPath,
    required int startPage,
  }) async {
    _pages = _textService.extractAllPages(pdfPath);
    _currentPageIndex = (startPage - 1).clamp(0, _pages.length - 1);
    await _speakCurrentPage();
  }

  Future<void> _speakCurrentPage() async {
    if (_currentPageIndex >= _pages.length) {
      state = TtsPlaybackState.stopped;
      onFinished?.call();
      return;
    }
    onPageChanged?.call(_currentPageIndex + 1);
    final text = _pages[_currentPageIndex];
    if (text.trim().isEmpty) {
      _currentPageIndex++;
      return _speakCurrentPage();
    }
    await _tts.speak(text);
  }

  Future<void> _onUtteranceComplete() async {
    if (state == TtsPlaybackState.stopped) return; // user stopped manually
    _currentPageIndex++;
    await _speakCurrentPage();
  }

  Future<void> pause() async {
    await _tts.pause();
  }

  Future<void> resume() async {
    // flutter_tts has no true "resume" on all platforms; re-speak the
    // current page from its start is the reliable cross-platform approach.
    await _speakCurrentPage();
  }

  Future<void> stop() async {
    await _tts.stop();
    state = TtsPlaybackState.stopped;
  }

  Future<void> setSpeechRate(double rate) async {
    speechRate = rate.clamp(0.1, 1.0);
    await _tts.setSpeechRate(speechRate);
  }

  Future<void> setPitch(double value) async {
    pitch = value.clamp(0.5, 2.0);
    await _tts.setPitch(pitch);
  }

  Future<void> setVolume(double value) async {
    volume = value.clamp(0.0, 1.0);
    await _tts.setVolume(volume);
  }

  int get currentPage => _currentPageIndex + 1;
  int get totalPages => _pages.length;

  void dispose() {
    _tts.stop();
  }
}
