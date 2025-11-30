import wave
import math
import random
import struct
import os

SAMPLE_RATE = 44100

def save_wav(filepath, data):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'w') as f:
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
    print(f"Generated {filepath}")

def generate_flap():
    """Quick upward 'boing' for bird jump - short and punchy"""
    duration = 0.12
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Rising pitch sweep (300Hz -> 600Hz)
        freq = 300 + 300 * (t / duration)

        # Sine wave with slight harmonic
        val = 0.6 * math.sin(2 * math.pi * freq * t)
        val += 0.2 * math.sin(4 * math.pi * freq * t)

        # Sharp attack, quick decay
        if t < 0.01:
            env = t / 0.01
        else:
            env = 1.0 - ((t - 0.01) / (duration - 0.01))

        data.append(val * env)

    return data

def generate_pipe_pass():
    """Subtle 'ding' for passing a pipe - rewarding but not distracting"""
    duration = 0.2
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Bell-like tone at higher frequency
    freq = 880  # A5 note

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Bell harmonics
        val = 0.5 * math.sin(2 * math.pi * freq * t)
        val += 0.2 * math.sin(2 * math.pi * freq * 2 * t)
        val += 0.1 * math.sin(2 * math.pi * freq * 3 * t)

        # Bell-like exponential decay
        env = math.exp(-8 * t)

        data.append(val * env)

    return data

def generate_collect_low():
    """Low-value ruby collection - soft 'pop'"""
    duration = 0.15
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Low pop frequency
        freq = 400 + 200 * (1 - t / duration)

        val = 0.5 * math.sin(2 * math.pi * freq * t)
        val += 0.2 * math.sin(4 * math.pi * freq * t)

        # Quick decay
        env = 1.0 - (t / duration)

        data.append(val * env)

    return data

def generate_collect_mid():
    """Mid-value ruby collection - brighter 'ding'"""
    duration = 0.18
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Medium frequency
        freq = 600 + 300 * (1 - t / duration)

        val = 0.6 * math.sin(2 * math.pi * freq * t)
        val += 0.25 * math.sin(4 * math.pi * freq * t)
        val += 0.1 * math.sin(6 * math.pi * freq * t)

        # Slightly longer decay
        env = math.exp(-6 * t)

        data.append(val * env)

    return data

def generate_collect_high():
    """High-value ruby collection - bright 'chime'"""
    duration = 0.25
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    # Major chord for high value (C5, E5, G5)
    freqs = [523, 659, 784]

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        val = 0.0
        for freq in freqs:
            val += 0.3 * math.sin(2 * math.pi * freq * t)

        # Longer, bell-like decay
        env = math.exp(-5 * t)

        data.append(val * env)

    return data

def generate_hit():
    """Impact sound for hitting target - satisfying 'thwack'"""
    duration = 0.15
    data = []
    num_samples = int(duration * SAMPLE_RATE)

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Impact - combination of low punch and high snap
        low_freq = 120
        high_freq = 2000

        # Low punch
        val = 0.4 * math.sin(2 * math.pi * low_freq * t)

        # High snap (decays quickly)
        val += 0.3 * math.sin(2 * math.pi * high_freq * t) * math.exp(-40 * t)

        # Noise burst for impact texture
        val += 0.2 * random.uniform(-1, 1) * math.exp(-20 * t)

        # Sharp envelope
        if t < 0.005:
            env = t / 0.005
        else:
            env = math.exp(-12 * (t - 0.005))

        data.append(val * env)

    return data

def main():
    # Flappy Bird sounds
    print("Generating Flappy Bird sounds...")
    flappy_dir = "games/flappy_bird/assets/"
    os.makedirs(flappy_dir, exist_ok=True)

    save_wav(flappy_dir + "sfx_flap.wav", generate_flap())
    save_wav(flappy_dir + "sfx_pass.wav", generate_pipe_pass())

    # Money Grabber sounds
    print("Generating Money Grabber sounds...")
    money_dir = "games/money_grabber/assets/"
    os.makedirs(money_dir, exist_ok=True)

    save_wav(money_dir + "sfx_collect_low.wav", generate_collect_low())
    save_wav(money_dir + "sfx_collect_mid.wav", generate_collect_mid())
    save_wav(money_dir + "sfx_collect_high.wav", generate_collect_high())

    # Sample AI Game sound
    print("Generating Sample AI Game sounds...")
    sample_dir = "games/sample_ai_game/assets/"
    os.makedirs(sample_dir, exist_ok=True)

    save_wav(sample_dir + "sfx_hit.wav", generate_hit())

    print("\nAll sound effects generated successfully!")
    print("\nSummary:")
    print("- Flappy Bird: sfx_flap.wav, sfx_pass.wav")
    print("- Money Grabber: sfx_collect_low.wav, sfx_collect_mid.wav, sfx_collect_high.wav")
    print("- Sample AI Game: sfx_hit.wav")

if __name__ == "__main__":
    main()
