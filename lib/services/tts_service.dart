import '../web_interop/tts_interop.dart';
import '../web_interop/pdf_interop.dart';
import 'pdf_text_service.dart';

enum TtsPlaybackState { stopped, playing, paused }

/// Wraps window.speechSynthesis (native browser TTS). No API keys, no
/// network call — the browser/OS provides the voice locally, same
/// mechanism as e.g. VoiceOver or built-in screen readers.
class TtsService {
  final PdfTextService _textService;

  TtsPlaybackState state = TtsPlaybackState.stopped;
  double speechRate = 1.0; // Web Speech API range: 0.1 - 10, UI constrains to 0.5-2.0
  double pitch = 1.0; // 0 - 2
  double volume = 1.0; // 0 - 1

  List<String> _pages = [];
  int _currentPageIndex = 0;
  void Function(int pageIndex)? onPageChanged;
  void Function()? onFinished;

  TtsService(this._textService) {
    WebTtsInterop.onStart(() => state = TtsPlaybackState.playing);
    WebTtsInterop.onEnd(_onUtteranceComplete);
  }

  Future<void> loadDocumentAndPlay({
    required PdfJsDocument doc,
    required int startPage,
  }) async {
    _pages = await _textService.extractAllPages(doc);
    _currentPageIndex = (startPage - 1).clamp(0, _pages.length - 1);
    _speakCurrentPage();
  }

  void _speakCurrentPage() {
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
    WebTtsInterop.speak(text, rate: speechRate, pitch: pitch, volume: volume);
  }

  void _onUtteranceComplete() {
    if (state == TtsPlaybackState.stopped) return; // user stopped manually
    _currentPageIndex++;
    _speakCurrentPage();
  }

  void pause() {
    WebTtsInterop.pause();
    state = TtsPlaybackState.paused;
  }

  void resume() {
    WebTtsInterop.resume();
    state = TtsPlaybackState.playing;
  }

  void stop() {
    WebTtsInterop.cancel();
    state = TtsPlaybackState.stopped;
  }

  void setSpeechRate(double rate) => speechRate = rate.clamp(0.5, 2.0);
  void setPitch(double value) => pitch = value.clamp(0.5, 2.0);
  void setVolume(double value) => volume = value.clamp(0.0, 1.0);

  int get currentPage => _currentPageIndex + 1;
  int get totalPages => _pages.length;

  void dispose() => WebTtsInterop.cancel();
}
