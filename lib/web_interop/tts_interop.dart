// Bridges to the browser's native SpeechSynthesis API
// (window.speechSynthesis) — built into every modern browser, free,
// and requires no network call once voices are loaded locally by the
// browser/OS. This is the direct web equivalent of Android
// TextToSpeech / iOS AVSpeechSynthesizer.

@JS()
library tts_interop;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS('ttsBridge.speak')
external void _speak(String text, double rate, double pitch, double volume);

@JS('ttsBridge.pause')
external void _pause();

@JS('ttsBridge.resume')
external void _resume();

@JS('ttsBridge.cancel')
external void _cancel();

@JS('ttsBridge.setOnEnd')
external void _setOnEnd(void Function() callback);

@JS('ttsBridge.setOnStart')
external void _setOnStart(void Function() callback);

class WebTtsInterop {
  static void speak(String text, {double rate = 1.0, double pitch = 1.0, double volume = 1.0}) {
    _speak(text, rate, pitch, volume);
  }

  static void pause() => _pause();
  static void resume() => _resume();
  static void cancel() => _cancel();

  static void onEnd(void Function() callback) {
    _setOnEnd(js_util.allowInterop(callback));
  }

  static void onStart(void Function() callback) {
    _setOnStart(js_util.allowInterop(callback));
  }
}
