#!/usr/bin/env python3
"""
Sound effect generator for Loop Connect microgame.
Generates minimalist, Zen-style audio matching the black/white aesthetic.
"""

import numpy as np
from scipy.io import wavfile
import os

# Audio settings
SAMPLE_RATE = 44100  # Hz
BIT_DEPTH = np.int16
MAX_AMPLITUDE = 32767

def generate_tone(frequency, duration, sample_rate=SAMPLE_RATE):
    """Generate a pure sine wave tone."""
    t = np.linspace(0, duration, int(sample_rate * duration))
    return np.sin(2 * np.pi * frequency * t)

def apply_envelope(signal, attack=0.01, decay=0.02, sustain=0.7, release=0.1):
    """Apply ADSR envelope to a signal."""
    length = len(signal)
    envelope = np.ones(length)
    
    # Attack
    attack_samples = int(attack * length)
    if attack_samples > 0:
        envelope[:attack_samples] = np.linspace(0, 1, attack_samples)
    
    # Decay to sustain level
    decay_samples = int(decay * length)
    if decay_samples > 0:
        start_idx = attack_samples
        end_idx = start_idx + decay_samples
        envelope[start_idx:end_idx] = np.linspace(1, sustain, decay_samples)
    
    # Sustain (already set to sustain level)
    sustain_start = attack_samples + decay_samples
    sustain_end = length - int(release * length)
    if sustain_end > sustain_start:
        envelope[sustain_start:sustain_end] = sustain
    
    # Release
    release_samples = int(release * length)
    if release_samples > 0:
        envelope[-release_samples:] = np.linspace(sustain, 0, release_samples)
    
    return signal * envelope

def normalize_and_convert(signal, amplitude=0.7):
    """Normalize signal and convert to 16-bit PCM."""
    # Normalize to -1 to 1
    if np.max(np.abs(signal)) > 0:
        signal = signal / np.max(np.abs(signal))
    # Scale by amplitude factor
    signal = signal * amplitude
    # Convert to 16-bit integer
    return (signal * MAX_AMPLITUDE).astype(BIT_DEPTH)

def generate_rotate_sfx():
    """
    Generate soft mechanical click/snap sound.
    Short, percussive, satisfying but subtle (plays frequently).
    Duration: ~0.15 seconds
    """
    duration = 0.15
    
    # Blend of frequencies for "click" character
    # Higher frequency for the initial "snap"
    click_high = generate_tone(1200, duration) * 0.6
    click_mid = generate_tone(600, duration) * 0.4
    click_low = generate_tone(300, duration) * 0.3
    
    # Combine frequencies
    click = click_high + click_mid + click_low
    
    # Very fast attack and decay for percussive "snap"
    click = apply_envelope(click, attack=0.002, decay=0.05, sustain=0.1, release=0.15)
    
    # Add a tiny bit of white noise for mechanical texture
    noise = np.random.normal(0, 0.03, len(click))
    noise = apply_envelope(noise, attack=0.001, decay=0.1, sustain=0, release=0.05)
    
    signal = click + noise
    return normalize_and_convert(signal, amplitude=0.5)

def generate_win_sfx():
    """
    Generate bright, satisfying completion chime.
    Ascending musical tone, Zen-like peaceful celebration.
    Duration: ~0.5 seconds
    """
    duration = 0.5
    sample_rate = SAMPLE_RATE
    
    # Create ascending arpeggio: C major chord (C5, E5, G5, C6)
    # Frequencies: 523.25, 659.25, 783.99, 1046.50 Hz
    notes = [523.25, 659.25, 783.99, 1046.50]
    note_duration = duration / len(notes)
    
    signal = np.array([])
    
    for i, freq in enumerate(notes):
        t = np.linspace(0, note_duration, int(sample_rate * note_duration))
        # Pure sine wave for clean, Zen-like tone
        tone = np.sin(2 * np.pi * freq * t)
        
        # Smooth envelope for each note
        note_envelope = np.ones(len(tone))
        attack = int(0.02 * len(tone))
        release = int(0.1 * len(tone))
        
        note_envelope[:attack] = np.linspace(0, 1, attack)
        note_envelope[-release:] = np.linspace(1, 0.3 if i < len(notes)-1 else 0, release)
        
        tone = tone * note_envelope
        signal = np.concatenate([signal, tone])
    
    # Add subtle harmonic for richness
    t_full = np.linspace(0, duration, len(signal))
    harmonic = np.sin(2 * np.pi * 1046.50 * t_full) * 0.15  # High C held throughout
    harmonic = apply_envelope(harmonic, attack=0.1, decay=0.1, sustain=0.5, release=0.3)
    
    signal = signal + harmonic
    return normalize_and_convert(signal, amplitude=0.7)

def generate_lose_sfx():
    """
    Generate gentle "incomplete" descending tone.
    Not harsh, matches minimalist Zen theme.
    Duration: ~0.35 seconds
    """
    duration = 0.35
    sample_rate = SAMPLE_RATE
    
    # Descending tone from G4 to C4 (392 Hz to 261.63 Hz)
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Smooth frequency sweep (descending)
    freq_start = 392.0
    freq_end = 261.63
    # Exponential frequency sweep for more natural descent
    frequency = freq_start * np.exp(np.log(freq_end / freq_start) * t / duration)
    
    # Generate tone with frequency modulation
    phase = 2 * np.pi * np.cumsum(frequency) / sample_rate
    signal = np.sin(phase)
    
    # Gentle envelope - not too harsh
    signal = apply_envelope(signal, attack=0.05, decay=0.1, sustain=0.6, release=0.35)
    
    # Add second voice for depth (minor third below)
    frequency_low = frequency * (6/5)  # Minor third ratio
    phase_low = 2 * np.pi * np.cumsum(frequency_low) / sample_rate
    signal_low = np.sin(phase_low) * 0.5
    signal_low = apply_envelope(signal_low, attack=0.05, decay=0.1, sustain=0.5, release=0.35)
    
    signal = signal + signal_low
    return normalize_and_convert(signal, amplitude=0.6)

def main():
    """Generate all sound effects for Loop Connect."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    assets_dir = os.path.join(script_dir, 'assets')
    
    # Ensure assets directory exists
    os.makedirs(assets_dir, exist_ok=True)
    
    print("Generating Loop Connect sound effects...")
    print(f"Output directory: {assets_dir}")
    
    # Generate rotate sound
    print("  - Generating sfx_rotate.wav (soft click)...")
    rotate_sfx = generate_rotate_sfx()
    wavfile.write(os.path.join(assets_dir, 'sfx_rotate.wav'), SAMPLE_RATE, rotate_sfx)
    
    # Generate win sound
    print("  - Generating sfx_win.wav (ascending chime)...")
    win_sfx = generate_win_sfx()
    wavfile.write(os.path.join(assets_dir, 'sfx_win.wav'), SAMPLE_RATE, win_sfx)
    
    # Generate lose sound
    print("  - Generating sfx_lose.wav (descending tone)...")
    lose_sfx = generate_lose_sfx()
    wavfile.write(os.path.join(assets_dir, 'sfx_lose.wav'), SAMPLE_RATE, lose_sfx)
    
    print("\n✅ All sound effects generated successfully!")
    print("\nSound effect details:")
    print(f"  sfx_rotate.wav: {len(rotate_sfx) / SAMPLE_RATE:.2f}s - Soft mechanical click")
    print(f"  sfx_win.wav:    {len(win_sfx) / SAMPLE_RATE:.2f}s - Ascending C major arpeggio")
    print(f"  sfx_lose.wav:   {len(lose_sfx) / SAMPLE_RATE:.2f}s - Gentle descending tone")

if __name__ == '__main__':
    main()
