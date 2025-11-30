import wave
import math
import random
import struct
import os

OUTPUT_DIR = "shared/assets/"
SAMPLE_RATE = 44100

def save_wav(filename, data):
    path = os.path.join(OUTPUT_DIR, filename)
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
    print(f"Generated {path}")

def generate_move():
    # Robotic servo step: Short, quick pitch rise/fall
    duration = 0.15
    data = []
    num_samples = int(duration * SAMPLE_RATE)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Frequency ramp up then down
        freq = 200 + 400 * math.sin(t * math.pi / duration)
        # Sawtooth-like approximation using sine harmonics
        val = 0.6 * math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(4 * math.pi * freq * t)
        
        # Envelope: fast attack, fade out
        env = 1.0
        if t < 0.02:
            env = t / 0.02
        else:
            env = 1.0 - (t - 0.02) / (duration - 0.02)
            
        data.append(val * env)
    save_wav("sfx_move.wav", data)

def generate_push():
    # Heavy metallic scrape: Low frequency modulation + Noise
    duration = 0.4
    data = []
    num_samples = int(duration * SAMPLE_RATE)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        
        # Base low rumble
        freq_rumble = 60 + 10 * math.sin(2 * math.pi * 15 * t)
        rumble = math.sin(2 * math.pi * freq_rumble * t)
        
        # Metallic scraping noise
        noise = random.uniform(-1, 1)
        
        # Combine
        val = 0.4 * rumble + 0.4 * noise
        
        # Envelope
        env = 1.0
        if t < 0.05:
            env = t / 0.05
        else:
            env = 1.0 - (t - 0.05) / (duration - 0.05)
            
        data.append(val * env)
    save_wav("sfx_push.wav", data)

def generate_win():
    # Airlock sealing + Positive chime
    duration = 1.0
    data = []
    num_samples = int(duration * SAMPLE_RATE)
    
    # Chime notes (frequencies in Hz)
    notes = [440, 554, 659] # A Major chord (A4, C#5, E5)
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        
        # Mechanical Lock (first 0.2s)
        if t < 0.2:
            clunk_freq = 100 * (1 - t/0.2)
            val += 0.5 * (random.uniform(-1, 1) * 0.5 + math.sin(2 * math.pi * clunk_freq * t))
            
        # Chime (starts at 0.2s)
        if t > 0.2:
            t_chime = t - 0.2
            for j, freq in enumerate(notes):
                # Staggered entry
                if t_chime > j * 0.1:
                    t_note = t_chime - j * 0.1
                    # Bell-like envelope
                    env = math.exp(-3 * t_note)
                    val += 0.2 * math.sin(2 * math.pi * freq * t_note) * env
        
        data.append(val)
    save_wav("sfx_win.wav", data)

def generate_lose():
    # Alarm / Power down: Descending saw/square
    duration = 0.8
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Descending pitch
        freq = 800 * (1 - t/duration)
        if freq < 50: freq = 50

        # Square wave sound
        val = 0.5 if math.sin(2 * math.pi * freq * t) > 0 else -0.5

        # Intermittent "Alarm" pulsing
        pulse = 1.0 if (int(t * 10) % 2 == 0) else 0.2

        # Envelope
        env = 1.0 - (t / duration)

        data.append(val * pulse * env)
    save_wav("sfx_lose.wav", data)

def generate_countdown():
    # EPIC DUN DUN DUN countdown: 3 POWERFUL impact hits with maximum OOMPH!
    duration = 1.0
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Three beat timings (in seconds) - spaced for dramatic effect
    beat_times = [0.0, 0.33, 0.66]
    beat_duration = 0.15  # Each hit lasts 150ms for more sustain
    whoosh_duration = 0.08  # Whoosh sweep between hits

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        # Check if we're in any beat window
        for beat_idx, beat_start in enumerate(beat_times):
            beat_t = t - beat_start

            # MAIN IMPACT HIT
            if 0 <= beat_t < beat_duration:
                # === LAYER 1: SUB-BASS RUMBLE (60-80Hz) ===
                sub_freq = 70
                sub_bass = 0.45 * math.sin(2 * math.pi * sub_freq * beat_t)
                sub_bass += 0.15 * math.sin(2 * math.pi * sub_freq * 0.5 * beat_t)  # Sub-harmonic

                # === LAYER 2: MID PUNCH (200-400Hz) for BODY ===
                mid_freq = 280
                mid_punch = 0.5 * math.sin(2 * math.pi * mid_freq * beat_t)
                mid_punch += 0.35 * math.sin(2 * math.pi * mid_freq * 1.5 * beat_t)  # Harmonic
                mid_punch += 0.25 * math.sin(2 * math.pi * mid_freq * 2 * beat_t)    # Octave

                # === LAYER 3: HIGH SNAP (2000-4000Hz) for CLARITY ===
                high_freq = 3000
                high_snap = 0.25 * math.sin(2 * math.pi * high_freq * beat_t)
                high_snap += 0.15 * math.sin(2 * math.pi * high_freq * 1.3 * beat_t)

                # === LAYER 4: WHITE NOISE BURST for SNAP ===
                noise_burst = 0.3 * random.uniform(-1, 1) * math.exp(-25 * beat_t)

                # === LAYER 5: FILTERED NOISE for TEXTURE ===
                texture_noise = 0.12 * random.uniform(-1, 1) * math.exp(-8 * beat_t)

                # === ENVELOPE SHAPING: Instant attack (<1ms), punchy decay ===
                if beat_t < 0.001:  # <1ms ultra-fast attack for MAXIMUM PUNCH
                    env = beat_t / 0.001
                elif beat_t < 0.02:  # Sharp initial decay
                    env = 1.0 - 0.4 * ((beat_t - 0.001) / 0.019)
                else:  # Sustained tail with reverb-like decay
                    env = 0.6 * math.exp(-6 * (beat_t - 0.02))

                # === COMBINE ALL LAYERS ===
                val = (sub_bass + mid_punch + high_snap + noise_burst + texture_noise) * env

                # === SLIGHT PITCH DROP for WEIGHT (cinematic effect) ===
                pitch_mod = 1.0 - (beat_t / beat_duration) * 0.15  # Drop 15% over hit duration
                val *= pitch_mod

                break  # Only process one beat at a time

            # WHOOSH SWEEP between hits (starts right after beat ends)
            whoosh_start = beat_start + beat_duration
            whoosh_t = t - whoosh_start
            if 0 <= whoosh_t < whoosh_duration and beat_idx < len(beat_times) - 1:
                # Frequency sweep from high to low
                sweep_progress = whoosh_t / whoosh_duration
                sweep_freq = 4000 - 3000 * sweep_progress  # 4000Hz -> 1000Hz sweep

                # Filtered noise for whoosh
                whoosh_noise = 0.15 * random.uniform(-1, 1)
                whoosh_tone = 0.1 * math.sin(2 * math.pi * sweep_freq * whoosh_t)

                # Whoosh envelope: quick fade in/out
                if whoosh_t < whoosh_duration * 0.3:
                    whoosh_env = whoosh_t / (whoosh_duration * 0.3)
                else:
                    whoosh_env = 1.0 - ((whoosh_t - whoosh_duration * 0.3) / (whoosh_duration * 0.7))

                val += (whoosh_noise + whoosh_tone) * whoosh_env * 0.6

        # === COMPRESSION/MAXIMIZATION for LOUDNESS ===
        # Soft clipping for analog warmth and loudness
        if abs(val) > 0.7:
            val = 0.7 + 0.3 * math.tanh((val - 0.7 * (1 if val > 0 else -1)) / 0.3) * (1 if val > 0 else -1)

        # Scale to maximum safe amplitude (0.98 for headroom)
        data.append(val * 0.98)

    save_wav("sfx_countdown.wav", data)

def generate_game_start():
    # Game start countdown: 3-2-1-GO! with ascending pitch excitement
    duration = 2.0
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Four beat timings: 3, 2, 1, GO!
    beat_times = [0.0, 0.5, 1.0, 1.5]
    beat_duration = 0.15

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        for beat_idx, beat_start in enumerate(beat_times):
            beat_t = t - beat_start

            if 0 <= beat_t < beat_duration:
                # Ascending pitch for excitement (starts low, ends high)
                # 3=150Hz, 2=200Hz, 1=250Hz, GO!=350Hz
                base_freq = 150 + (beat_idx * 67)

                # Layer 1: Bass thump
                bass = 0.4 * math.sin(2 * math.pi * base_freq * beat_t)

                # Layer 2: Mid punch
                mid = 0.3 * math.sin(2 * math.pi * base_freq * 2 * beat_t)

                # Layer 3: High sparkle (more on final beat)
                high_mult = 2.0 if beat_idx == 3 else 1.0
                high = 0.2 * high_mult * math.sin(2 * math.pi * base_freq * 4 * beat_t)

                # Layer 4: Noise snap
                noise = 0.15 * random.uniform(-1, 1) * math.exp(-20 * beat_t)

                # Envelope
                if beat_t < 0.001:
                    env = beat_t / 0.001
                else:
                    env = math.exp(-8 * beat_t)

                val = (bass + mid + high + noise) * env
                break

        # Soft clipping
        if abs(val) > 0.7:
            val = 0.7 + 0.3 * math.tanh((val - 0.7 * (1 if val > 0 else -1)) / 0.3) * (1 if val > 0 else -1)

        data.append(val * 0.95)

    save_wav("sfx_game_start.wav", data)

def generate_game_over():
    # Epic game over: DUN DUN DEN DUN DEEEN (5 dramatic beats with final sustain)
    duration = 3.5
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Five beat timings with dramatic spacing
    # DUN (0.0), DUN (0.5), DEN (1.0), DUN (1.7), DEEEN (2.4-3.5 sustained)
    beat_times = [0.0, 0.5, 1.0, 1.7, 2.4]
    beat_durations = [0.15, 0.15, 0.12, 0.15, 1.1]  # Last beat is LONG

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0

        for beat_idx, beat_start in enumerate(beat_times):
            beat_t = t - beat_start
            beat_dur = beat_durations[beat_idx]

            if 0 <= beat_t < beat_dur:
                # Descending pitch progression for tragic feel
                # Beat 1-2: Low (80Hz), Beat 3: Higher (150Hz), Beat 4: Low (70Hz), Beat 5: VERY low (50Hz)
                if beat_idx < 2:
                    base_freq = 80
                elif beat_idx == 2:
                    base_freq = 150  # DEN is higher pitch
                elif beat_idx == 3:
                    base_freq = 70
                else:
                    base_freq = 50  # Final DEEEN is deepest

                # Layer 1: Deep sub-bass
                sub_bass = 0.5 * math.sin(2 * math.pi * base_freq * beat_t)
                sub_bass += 0.2 * math.sin(2 * math.pi * base_freq * 0.5 * beat_t)

                # Layer 2: Mid body
                mid = 0.4 * math.sin(2 * math.pi * base_freq * 2 * beat_t)
                mid += 0.3 * math.sin(2 * math.pi * base_freq * 3 * beat_t)

                # Layer 3: Upper harmonics
                high = 0.2 * math.sin(2 * math.pi * base_freq * 5 * beat_t)

                # Layer 4: Noise texture (more on final beat)
                noise_mult = 1.5 if beat_idx == 4 else 1.0
                noise = 0.15 * noise_mult * random.uniform(-1, 1) * math.exp(-10 * beat_t)

                # Envelope - final beat sustains longer
                if beat_idx == 4:
                    # Long sustained envelope for DEEEN
                    if beat_t < 0.001:
                        env = beat_t / 0.001
                    elif beat_t < 0.3:
                        env = 1.0
                    else:
                        # Slow fade over remaining 0.8 seconds
                        env = 1.0 - ((beat_t - 0.3) / 0.8)
                else:
                    # Normal punchy envelope
                    if beat_t < 0.001:
                        env = beat_t / 0.001
                    elif beat_t < 0.02:
                        env = 1.0 - 0.3 * ((beat_t - 0.001) / 0.019)
                    else:
                        env = 0.7 * math.exp(-6 * (beat_t - 0.02))

                val = (sub_bass + mid + high + noise) * env

                # Add reverb-like tail for final note
                if beat_idx == 4 and beat_t > 0.5:
                    reverb_t = beat_t - 0.5
                    reverb = 0.1 * math.sin(2 * math.pi * base_freq * reverb_t) * math.exp(-3 * reverb_t)
                    val += reverb

                break

        # Compression
        if abs(val) > 0.7:
            val = 0.7 + 0.3 * math.tanh((val - 0.7 * (1 if val > 0 else -1)) / 0.3) * (1 if val > 0 else -1)

        data.append(val * 0.98)

    save_wav("sfx_game_over.wav", data)

if __name__ == "__main__":
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
    generate_game_start()
    generate_game_over()
    generate_countdown()
    print("Generated all sound effects!")
