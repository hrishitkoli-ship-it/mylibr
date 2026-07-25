// tts_bridge.js
// Wraps window.speechSynthesis (native browser TTS) into a small API
// consumed via Dart JS interop (tts_interop.dart). No network calls —
// voices are provided by the browser/OS itself.

window.ttsBridge = (function () {
  let currentUtterance = null;
  let onEndCallback = null;
  let onStartCallback = null;

  function speak(text, rate, pitch, volume) {
    window.speechSynthesis.cancel(); // stop anything currently queued
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = rate;   // 0.1 - 10, we constrain in Dart to 0.5-2.0
    utterance.pitch = pitch; // 0 - 2
    utterance.volume = volume; // 0 - 1

    utterance.onend = () => {
      if (onEndCallback) onEndCallback();
    };
    utterance.onstart = () => {
      if (onStartCallback) onStartCallback();
    };

    currentUtterance = utterance;
    window.speechSynthesis.speak(utterance);
  }

  function pause() {
    window.speechSynthesis.pause();
  }

  function resume() {
    window.speechSynthesis.resume();
  }

  function cancel() {
    window.speechSynthesis.cancel();
    currentUtterance = null;
  }

  function setOnEnd(callback) {
    onEndCallback = callback;
  }

  function setOnStart(callback) {
    onStartCallback = callback;
  }

  return { speak, pause, resume, cancel, setOnEnd, setOnStart };
})();
