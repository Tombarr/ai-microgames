# Loop Connect - Audio Assets

All sound effects generated procedurally using Python (numpy/scipy).

## Sound Effects

### sfx_rotate.wav

- **Duration**: 0.15 seconds
- **Description**: Soft mechanical click/snap sound
- **Usage**: Plays each time a pipe tile is rotated
- **Style**: Percussive, satisfying but subtle (designed for frequent playback)
- **Technique**: Blend of 300Hz, 600Hz, and 1200Hz tones with fast attack/decay envelope, plus
  subtle white noise for mechanical texture

### sfx_win.wav

- **Duration**: 0.50 seconds
- **Description**: Bright, satisfying completion chime
- **Usage**: Plays when the puzzle is successfully solved
- **Style**: Ascending C major arpeggio (C5-E5-G5-C6), Zen-like peaceful celebration
- **Technique**: Pure sine waves at 523.25, 659.25, 783.99, 1046.50 Hz with smooth envelopes and
  subtle sustained harmonic

### sfx_lose.wav

- **Duration**: 0.35 seconds
- **Description**: Gentle "incomplete" descending tone
- **Usage**: Plays when time runs out with unsolved puzzle
- **Style**: Not harsh, matches minimalist Zen theme
- **Technique**: Smooth frequency sweep from G4 (392 Hz) to C4 (261.63 Hz) with minor third harmony

## Technical Specifications

- **Format**: WAV (RIFF)
- **Sample Rate**: 44,100 Hz
- **Bit Depth**: 16-bit PCM
- **Channels**: Mono
- **Generated**: 2025-11-30

## Generation

Run `generate_sfx.py` in the game directory to regenerate these files.

Requirements:

```bash
pip install numpy scipy
```
