import type { TtsController, TtsPlaybackState } from '../lib/ttsController';

interface Props {
  tts: TtsController;
  state: TtsPlaybackState;
  ttsCurrentPage: number;
  fallbackPage: number;
  onPlay: () => void;
  onRateChange: (rate: number) => void;
  onPitchChange: (pitch: number) => void;
  forceUpdate: () => void;
}

export function TtsToolbar({
  tts,
  state,
  ttsCurrentPage,
  fallbackPage,
  onPlay,
  onRateChange,
  onPitchChange,
  forceUpdate,
}: Props) {
  const handlePlayPause = () => {
    if (state === 'playing') {
      tts.pause();
    } else if (state === 'paused') {
      tts.resume();
    } else {
      onPlay();
    }
    forceUpdate();
  };

  const handleStop = () => {
    tts.stop();
    forceUpdate();
  };

  return (
    <div className="tts-toolbar">
      <div className="tts-toolbar__row">
        <button className="tts-toolbar__play" onClick={handlePlayPause} aria-label="Play/Pause">
          {state === 'playing' ? '⏸' : '▶️'}
        </button>
        <button className="tts-toolbar__stop" onClick={handleStop} aria-label="Stop">
          ⏹
        </button>
        <span className="tts-toolbar__page">
          Reading page {ttsCurrentPage > 0 ? ttsCurrentPage : fallbackPage}
        </span>
      </div>
      <div className="tts-toolbar__row">
        <label>
          Speed
          <input
            type="range"
            min={0.5}
            max={2}
            step={0.1}
            value={tts.speechRate}
            onChange={(e) => onRateChange(parseFloat(e.target.value))}
          />
          <span>{tts.speechRate.toFixed(1)}x</span>
        </label>
        <label>
          Pitch
          <input
            type="range"
            min={0.5}
            max={2}
            step={0.1}
            value={tts.pitch}
            onChange={(e) => onPitchChange(parseFloat(e.target.value))}
          />
          <span>{tts.pitch.toFixed(1)}</span>
        </label>
      </div>
    </div>
  );
}
