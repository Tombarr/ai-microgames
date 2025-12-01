#!/usr/bin/env python3
"""
HIGH-QUALITY SOUND EFFECT GENERATOR FOR WARIOWARE-STYLE MICROGAMES
====================================================================
Generates punchy, energetic sound effects that match the "Digital Marker Chaos" aesthetic.

Key features:
- Multi-layered synthesis (sub-bass, mids, highs, noise)
- Professional ADSR envelopes for punch and clarity
- Soft compression/limiting for loudness and cohesion
- Harmonic richness for "sticker pop" feel
- Optimized for mobile speakers (emphasis on 200-4000Hz range)
"""

import wave
import math
import random
import struct
import os
import argparse

# Audio settings
SAMPLE_RATE = 44100
BIT_DEPTH = 16

def save_wav(filename, data, output_dir="shared/assets/"):
    """Save audio data as WAV file with proper normalization."""
    path = os.path.join(output_dir, filename)
    os.makedirs(output_dir, exist_ok=True)

    # Normalize to prevent clipping
    max_val = max(abs(min(data)), abs(max(data)))
    if max_val > 0.98:
        data = [s * 0.98 / max_val for s in data]

    with wave.open(path, 'w') as f:
        f.setnchannels(1)  # Mono
        f.setsampwidth(2)  # 16-bit
        f.setframerate(SAMPLE_RATE)

        # Convert float -1.0..1.0 to int16
        packed_data = b''
        for sample in data:
            s = int(sample * 32767)
            s = max(-32768, min(32767, s))
            packed_data += struct.pack('<h', s)
        f.writeframes(packed_data)

    print(f"✓ Generated {path} ({len(data)/SAMPLE_RATE:.2f}s, {len(data)} samples)")

def apply_soft_clip(value, threshold=0.7):
    """Soft clipping for analog warmth and loudness maximization."""
    if abs(value) > threshold:
        sign = 1 if value > 0 else -1
        excess = abs(value) - threshold
        clipped = threshold + (1 - threshold) * math.tanh(excess / (1 - threshold))
        return clipped * sign
    return value

def adsr_envelope(t, attack=0.01, decay=0.05, sustain=0.7, release=0.1, duration=0.5):
    """ADSR envelope generator for professional sound shaping."""
    if t < attack:
        return t / attack  # Attack
    elif t < attack + decay:
        # Decay to sustain level
        decay_progress = (t - attack) / decay
        return 1.0 - (1.0 - sustain) * decay_progress
    elif t < duration - release:
        return sustain  # Sustain
    else:
        # Release
        release_progress = (t - (duration - release)) / release
        return sustain * (1.0 - release_progress)

def generate_oscillator(freq, t, waveform='sine'):
    """Generate basic waveform oscillator."""
    phase = 2 * math.pi * freq * t

    if waveform == 'sine':
        return math.sin(phase)
    elif waveform == 'square':
        return 1.0 if math.sin(phase) > 0 else -1.0
    elif waveform == 'saw':
        return 2 * (t * freq - math.floor(t * freq + 0.5))
    elif waveform == 'triangle':
        return 2 * abs(2 * (t * freq - math.floor(t * freq + 0.5))) - 1
    return 0

# ============================================================================
# GAME-SPECIFIC SOUNDS
# ============================================================================

def generate_jump():
    """Jump/flap sound - bright, bouncy, instant feedback."""
    duration = 0.12
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        # Pitch sweep up (gives "spring" feeling)
        freq = 300 + 600 * (t / duration)

        # Layer 1: Main tone (sine for smoothness)
        val += 0.5 * generate_oscillator(freq, t, 'sine')

        # Layer 2: Harmonic richness
        val += 0.25 * generate_oscillator(freq * 2, t, 'sine')
        val += 0.15 * generate_oscillator(freq * 3, t, 'sine')

        # Layer 3: High sparkle for "pop"
        val += 0.1 * generate_oscillator(freq * 5, t, 'sine')

        # Layer 4: Noise burst for attack snap
        val += 0.2 * random.uniform(-1, 1) * math.exp(-40 * t)

        # Fast attack, quick decay envelope
        env = math.exp(-12 * t)
        val *= env

        val = apply_soft_clip(val, 0.75)
        data.append(val)

    return data

def generate_collect(pitch='mid'):
    """Collection sound - rewarding, musical, satisfying."""
    duration = 0.15
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Different pitches for different values
    base_freqs = {
        'low': [220, 277],      # A3 -> C#4 (minor third)
        'mid': [330, 415],      # E4 -> G#4 (major third)
        'high': [440, 554, 659] # A4 -> C#5 -> E5 (major chord)
    }

    notes = base_freqs.get(pitch, base_freqs['mid'])

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        # Play notes simultaneously for chord effect
        for idx, freq in enumerate(notes):
            # Slightly stagger note attacks for richness
            note_start = idx * 0.01
            if t >= note_start:
                note_t = t - note_start

                # Main tone
                val += 0.3 * generate_oscillator(freq, note_t, 'sine')

                # Harmonics for bell-like quality
                val += 0.15 * generate_oscillator(freq * 2, note_t, 'sine')
                val += 0.08 * generate_oscillator(freq * 3, note_t, 'sine')

        # Bell envelope - fast attack, exponential decay
        env = math.exp(-10 * t)
        val *= env

        # Gentle clipping
        val = apply_soft_clip(val, 0.8)
        data.append(val)

    return data

def generate_hit():
    """Hit/impact sound - punchy, satisfying, tactile."""
    duration = 0.08
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        # Layer 1: Low thump (body of the hit)
        thump_freq = 150 - 100 * (t / duration)  # Pitch drop
        val += 0.5 * generate_oscillator(thump_freq, t, 'sine')

        # Layer 2: Mid punch
        val += 0.3 * generate_oscillator(thump_freq * 2, t, 'sine')

        # Layer 3: High click for attack definition
        val += 0.15 * generate_oscillator(2000, t, 'sine') * math.exp(-50 * t)

        # Layer 4: Noise burst for snap
        val += 0.4 * random.uniform(-1, 1) * math.exp(-60 * t)

        # Very fast decay for "tight" punch
        env = math.exp(-30 * t)
        val *= env

        val = apply_soft_clip(val, 0.7)
        data.append(val)

    return data

def generate_win():
    """Win sound - triumphant, celebratory, satisfying resolution."""
    duration = 1.2
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Victory fanfare: Ascending major arpeggio (C-E-G-C)
    notes = [
        (262, 0.0),   # C4 at 0.0s
        (330, 0.2),   # E4 at 0.2s
        (392, 0.4),   # G4 at 0.4s
        (523, 0.6)    # C5 at 0.6s (octave up for climax)
    ]

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        for freq, start_time in notes:
            if t >= start_time:
                note_t = t - start_time
                note_duration = 0.4  # Each note rings for 400ms

                if note_t < note_duration:
                    # Main tone
                    val += 0.25 * generate_oscillator(freq, note_t, 'sine')

                    # Rich harmonics for "sparkle"
                    val += 0.15 * generate_oscillator(freq * 2, note_t, 'sine')
                    val += 0.10 * generate_oscillator(freq * 3, note_t, 'sine')
                    val += 0.05 * generate_oscillator(freq * 4, note_t, 'sine')

                    # Bell envelope
                    env = math.exp(-4 * note_t)
                    val *= env

        # Extra sparkle on final note (after 0.6s)
        if t > 0.6:
            sparkle_t = t - 0.6
            # High frequency shimmer
            val += 0.15 * generate_oscillator(2000, sparkle_t, 'sine') * math.exp(-5 * sparkle_t)
            val += 0.10 * generate_oscillator(2500, sparkle_t, 'sine') * math.exp(-6 * sparkle_t)

        val = apply_soft_clip(val, 0.8)
        data.append(val)

    return data

def generate_lose():
    """Lose sound - disappointing but not harsh, clear failure signal."""
    duration = 0.9
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Descending minor scale fragment for "sad" feel
    notes = [
        (330, 0.0),   # E4
        (294, 0.2),   # D4
        (262, 0.4)    # C4
    ]

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        for freq, start_time in notes:
            if t >= start_time:
                note_t = t - start_time
                note_duration = 0.3

                if note_t < note_duration:
                    # Square wave for "buzzer" quality
                    val += 0.3 * generate_oscillator(freq, note_t, 'square')

                    # Subharmonic for depth
                    val += 0.2 * generate_oscillator(freq * 0.5, note_t, 'sine')

                    # Envelope
                    env = math.exp(-5 * note_t)
                    val *= env

        # Add slight noise texture for "disappointment"
        if t < 0.1:
            val += 0.1 * random.uniform(-1, 1) * (1 - t / 0.1)

        val = apply_soft_clip(val, 0.75)
        data.append(val)

    return data

def generate_move():
    """Move/step sound - subtle, quick confirmation."""
    duration = 0.08
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Quick pitch rise for "step" feel
        freq = 400 + 200 * (t / duration)

        # Main tone (sine for softness)
        val = 0.4 * generate_oscillator(freq, t, 'sine')

        # Subtle harmonic
        val += 0.2 * generate_oscillator(freq * 2, t, 'sine')

        # Tiny noise click for attack
        val += 0.15 * random.uniform(-1, 1) * math.exp(-80 * t)

        # Fast envelope
        env = math.exp(-25 * t)
        val *= env

        data.append(val)

    return data

def generate_pass():
    """Pass/checkpoint sound - light, encouraging, progress indicator."""
    duration = 0.2
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Two-note ascending perfect fifth (C-G)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        # First note (C5)
        if t < 0.1:
            freq1 = 523
            val += 0.3 * generate_oscillator(freq1, t, 'sine')
            val += 0.15 * generate_oscillator(freq1 * 2, t, 'sine')
            env1 = math.exp(-15 * t)
            val *= env1

        # Second note (G5) - starts at 0.08s for slight overlap
        if t >= 0.08:
            t2 = t - 0.08
            freq2 = 784
            tone2 = 0.35 * generate_oscillator(freq2, t2, 'sine')
            tone2 += 0.15 * generate_oscillator(freq2 * 2, t2, 'sine')
            env2 = math.exp(-12 * t2)
            val += tone2 * env2

        val = apply_soft_clip(val, 0.8)
        data.append(val)

    return data

def generate_countdown():
    """
    DIRECTOR COUNTDOWN - "DUN DUN DUN!"
    Chaotic, fast, arcade-style countdown before each microgame.
    Ultra-punchy with massive sub-bass and sharp high-frequency snaps.
    """
    duration = 1.0
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Three ultra-fast beats - WarioWare tempo!
    beat_times = [0.0, 0.3, 0.6]
    beat_duration = 0.12

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        for beat_idx, beat_start in enumerate(beat_times):
            beat_t = t - beat_start

            if 0 <= beat_t < beat_duration:
                # Progressive pitch rise for building tension
                # Beat 1: 80Hz, Beat 2: 100Hz, Beat 3: 120Hz
                base_freq = 80 + (beat_idx * 20)

                # === LAYER 1: MASSIVE SUB-BASS (Arcade Cabinet Rumble) ===
                sub_bass = 0.6 * generate_oscillator(base_freq, beat_t, 'sine')
                # Sub-harmonic for extra depth
                sub_bass += 0.3 * generate_oscillator(base_freq * 0.5, beat_t, 'sine')

                # === LAYER 2: MID PUNCH (Body/Weight) ===
                mid_freq = base_freq * 2
                mid_punch = 0.5 * generate_oscillator(mid_freq, beat_t, 'sine')
                mid_punch += 0.3 * generate_oscillator(mid_freq * 1.5, beat_t, 'sine')
                mid_punch += 0.2 * generate_oscillator(mid_freq * 2, beat_t, 'sine')

                # === LAYER 3: HIGH SNAP (Attack Definition) ===
                high_freq = 3000 + (beat_idx * 500)
                high_snap = 0.4 * generate_oscillator(high_freq, beat_t, 'sine')
                high_snap += 0.25 * generate_oscillator(high_freq * 1.3, beat_t, 'sine')

                # === LAYER 4: CHAOTIC NOISE BURST ===
                noise_burst = 0.5 * random.uniform(-1, 1) * math.exp(-50 * beat_t)
                texture_noise = 0.2 * random.uniform(-1, 1) * math.exp(-10 * beat_t)

                # === LAYER 5: DIGITAL GLITCH (Extra Chaos) ===
                glitch = 0.0
                if random.random() > 0.7:
                    glitch_freq = random.uniform(2000, 5000)
                    glitch = 0.15 * generate_oscillator(glitch_freq, beat_t, 'sine')

                # === ULTRA-FAST ENVELOPE (Maximum Punch) ===
                if beat_t < 0.001:
                    env = beat_t / 0.001
                elif beat_t < 0.015:
                    env = 1.0 - 0.3 * ((beat_t - 0.001) / 0.014)
                else:
                    env = 0.7 * math.exp(-12 * (beat_t - 0.015))

                # Combine all layers
                val = (sub_bass + mid_punch + high_snap + noise_burst + texture_noise + glitch) * env

                # Pitch drop for weight
                pitch_drop = 1.0 - (beat_t / beat_duration) * 0.12
                val *= pitch_drop

                # Harder clipping on final beat
                clip_threshold = 0.65 if beat_idx == 2 else 0.7
                val = apply_soft_clip(val, clip_threshold)
                break

        # Between-beat "whoosh" energy
        for beat_idx in range(len(beat_times) - 1):
            whoosh_start = beat_times[beat_idx] + beat_duration
            whoosh_end = beat_times[beat_idx + 1]
            whoosh_t = t - whoosh_start

            if 0 <= whoosh_t < (whoosh_end - whoosh_start):
                sweep_progress = whoosh_t / (whoosh_end - whoosh_start)
                sweep_freq = 1000 + 2000 * sweep_progress
                whoosh = 0.08 * random.uniform(-1, 1) * math.sin(2 * math.pi * sweep_freq * whoosh_t)

                if sweep_progress < 0.3:
                    whoosh_env = sweep_progress / 0.3
                else:
                    whoosh_env = 1.0 - ((sweep_progress - 0.3) / 0.7)

                val += whoosh * whoosh_env

        # Final compression for maximum impact
        val = apply_soft_clip(val, 0.6)
        data.append(val * 0.98)

    return data

def generate_shoot():
    """Shoot/fire sound - punchy, directional, satisfying."""
    duration = 0.12
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        # Pitch sweep down for "projectile launch" feel
        freq = 600 - 400 * (t / duration)

        # Layer 1: Main body (square for "laser" quality)
        val += 0.4 * generate_oscillator(freq, t, 'square')

        # Layer 2: Harmonics
        val += 0.2 * generate_oscillator(freq * 1.5, t, 'sine')

        # Layer 3: High frequency "crack"
        val += 0.2 * generate_oscillator(3000, t, 'sine') * math.exp(-50 * t)

        # Layer 4: Noise burst for attack
        val += 0.3 * random.uniform(-1, 1) * math.exp(-40 * t)

        # Envelope
        env = math.exp(-15 * t)
        val *= env

        val = apply_soft_clip(val, 0.7)
        data.append(val)

    return data

def generate_explosion():
    """Explosion/destroy sound - dramatic, punchy, satisfying destruction."""
    duration = 0.4
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        # Layer 1: Low frequency rumble
        rumble_freq = 80 - 30 * (t / duration)
        val += 0.4 * generate_oscillator(rumble_freq, t, 'sine')

        # Layer 2: Mid punch
        val += 0.3 * generate_oscillator(rumble_freq * 2, t, 'square')

        # Layer 3: White noise burst (main explosion texture)
        noise_amount = 0.6 if t < 0.05 else 0.3
        val += noise_amount * random.uniform(-1, 1)

        # Layer 4: High frequency crackle
        if t < 0.1:
            val += 0.2 * generate_oscillator(4000 + random.uniform(-500, 500), t, 'sine')

        # Explosion envelope - fast attack, medium decay
        if t < 0.01:
            env = t / 0.01
        elif t < 0.05:
            env = 1.0
        else:
            env = 1.0 - ((t - 0.05) / (duration - 0.05))

        val *= env
        val = apply_soft_clip(val, 0.65)
        data.append(val)

    return data

def generate_button_press():
    """Button press - satisfying click, clear feedback."""
    duration = 0.05
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Two-part click: down + up
        if t < 0.02:
            # Down click - higher pitch
            freq = 800
            val = 0.5 * generate_oscillator(freq, t, 'sine')
            val += 0.3 * random.uniform(-1, 1) * math.exp(-100 * t)
        else:
            # Up click - lower pitch
            t2 = t - 0.02
            freq = 400
            val = 0.4 * generate_oscillator(freq, t2, 'sine')
            val += 0.2 * random.uniform(-1, 1) * math.exp(-100 * t2)

        # Very tight envelope
        env = math.exp(-50 * t)
        val *= env

        data.append(val)

    return data

# ============================================================================
# MAIN GENERATION FUNCTIONS
# ============================================================================

def generate_all_sounds(output_dir="shared/assets/"):
    """Generate all sound effects."""
    print("=" * 60)
    print("HIGH-QUALITY SOUND EFFECT GENERATOR")
    print("WarioWare-Style Microgames")
    print("=" * 60)

    sounds = {
        # Core game sounds
        'sfx_win.wav': generate_win(),
        'sfx_lose.wav': generate_lose(),

        # Action sounds
        'sfx_jump.wav': generate_jump(),
        'sfx_hit.wav': generate_hit(),
        'sfx_move.wav': generate_move(),
        'sfx_pass.wav': generate_pass(),
        'sfx_countdown.wav': generate_countdown(),
        'sfx_shoot.wav': generate_shoot(),
        'sfx_explosion.wav': generate_explosion(),
        'sfx_button.wav': generate_button_press(),

        # Collection sounds (different pitches for different values)
        'sfx_collect_low.wav': generate_collect('low'),
        'sfx_collect_mid.wav': generate_collect('mid'),
        'sfx_collect_high.wav': generate_collect('high'),
    }

    for filename, audio_data in sounds.items():
        save_wav(filename, audio_data, output_dir)

    print("=" * 60)
    print(f"✓ Generated {len(sounds)} sound effects!")
    print(f"✓ Output directory: {output_dir}")
    print("=" * 60)

def generate_game_sounds(game_name, sound_types, output_dir=None):
    """Generate specific sounds for a game."""
    if output_dir is None:
        output_dir = f"games/{game_name}/assets/"

    print(f"\nGenerating sounds for: {game_name}")
    print("-" * 40)

    sound_generators = {
        'jump': generate_jump,
        'flap': generate_jump,  # Alias
        'hit': generate_hit,
        'move': generate_move,
        'pass': generate_pass,
        'collect_low': lambda: generate_collect('low'),
        'collect_mid': lambda: generate_collect('mid'),
        'collect_high': lambda: generate_collect('high'),
        'shoot': generate_shoot,
        'explosion': generate_explosion,
        'button': generate_button_press,
        'win': generate_win,
        'lose': generate_lose,
    }

    for sound_type in sound_types:
        if sound_type in sound_generators:
            filename = f"sfx_{sound_type}.wav"
            audio_data = sound_generators[sound_type]()
            save_wav(filename, audio_data, output_dir)
        else:
            print(f"⚠ Unknown sound type: {sound_type}")

# ============================================================================
# CLI INTERFACE
# ============================================================================

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate high-quality sound effects for WarioWare-style microgames"
    )
    parser.add_argument(
        '--all',
        action='store_true',
        help='Generate all standard sound effects'
    )
    parser.add_argument(
        '--game',
        type=str,
        help='Game name (e.g., "flappy_bird")'
    )
    parser.add_argument(
        '--sounds',
        type=str,
        nargs='+',
        help='Sound types to generate (e.g., jump hit move)'
    )
    parser.add_argument(
        '--output',
        type=str,
        help='Output directory (defaults to shared/assets/ or games/GAME/assets/)'
    )

    args = parser.parse_args()

    if args.all:
        output_dir = args.output or "shared/assets/"
        generate_all_sounds(output_dir)
    elif args.game and args.sounds:
        output_dir = args.output or f"games/{args.game}/assets/"
        generate_game_sounds(args.game, args.sounds, output_dir)
    else:
        # Default: generate all shared sounds
        generate_all_sounds()
