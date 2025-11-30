import wave
import math
import random
import struct
import os

OUTPUT_DIR = "games/micro_sokoban/assets/"
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

if __name__ == "__main__":
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
    generate_move()
    generate_push()
    generate_win()
    generate_lose()
