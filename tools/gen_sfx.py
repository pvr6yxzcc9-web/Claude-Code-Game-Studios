#!/usr/bin/env python3
"""
gen_sfx.py — Generate SFX .wav files (S6-010).

Replaces the procedural beeps with real on-disk .wav files.
All SFX are synthesized (no external samples) so the project ships
zero binary dependencies, but they sound like real weapon fire/hits
instead of pure sine tones.

Outputs (in assets/audio/sfx/):
  attack_blaster.wav     short square+noise shot, ~0.15s
  attack_railgun.wav     descending sine punch + crack, ~0.2s
  attack_plasma.wav      rising sweep + zap, ~0.25s
  hit_enemy.wav          impact thud + noise, ~0.12s
  ui_click.wav           short blip, ~0.04s

Each is 22050Hz, 16-bit mono (Godot 4.6 native format).

Run from project root:
  python tools/gen_sfx.py
"""
import os
import struct
import math
import random

OUT_DIR = "assets/audio/sfx"
SR = 22050

def _write_wav(path: str, samples: list) -> None:
    """Write a 16-bit mono WAV file."""
    n = len(samples)
    # Clamp
    samples = [max(-1.0, min(1.0, s)) for s in samples]
    # Convert to int16
    int_samples = [int(s * 32767) for s in samples]
    # Build RIFF header
    data_bytes = b"".join(struct.pack("<h", s) for s in int_samples)
    file_size = 36 + len(data_bytes)
    header = b"RIFF"
    header += struct.pack("<I", file_size)
    header += b"WAVE"
    header += b"fmt "
    header += struct.pack("<I", 16)  # PCM chunk size
    header += struct.pack("<H", 1)   # PCM format
    header += struct.pack("<H", 1)   # mono
    header += struct.pack("<I", SR)  # sample rate
    header += struct.pack("<I", SR * 2)  # byte rate
    header += struct.pack("<H", 2)   # block align
    header += struct.pack("<H", 16)  # bits per sample
    header += b"data"
    header += struct.pack("<I", len(data_bytes))
    with open(path, "wb") as f:
        f.write(header + data_bytes)

def _env_adsr(n: int, attack: float, decay: float, sustain: float, release: float) -> list:
    """Apply ADSR envelope to n samples (fractions of total)."""
    a = int(n * attack)
    d = int(n * decay)
    r = int(n * release)
    s = n - a - d - r
    if s < 0:
        s = 0
        a, d, r = a // 3, a // 3, n - 2 * (a // 3)
    env = []
    for i in range(n):
        if i < a:
            env.append(i / max(a, 1))
        elif i < a + d:
            t = (i - a) / max(d, 1)
            env.append(1.0 + t * (sustain - 1.0))
        elif i < a + d + s:
            env.append(sustain)
        else:
            t = (i - a - d - s) / max(r, 1)
            env.append(sustain * (1.0 - t))
    return env

def make_attack_blaster() -> None:
    """Sharp blaster shot: square wave + noise burst, fast decay."""
    duration = 0.15
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        # Square wave at 600Hz with downward pitch sweep
        freq = 600 - 300 * (t / duration)  # 600 -> 300
        phase = (t * freq) % 1.0
        square = 1.0 if phase < 0.5 else -1.0
        # Add noise burst
        noise = random.uniform(-0.3, 0.3)
        s = 0.5 * square + 0.5 * noise
        samples.append(s)
    # Apply envelope (sharp attack, quick decay)
    env = _env_adsr(n, 0.02, 0.1, 0.3, 0.6)
    samples = [s * e for s, e in zip(samples, env)]
    _write_wav(os.path.join(OUT_DIR, "attack_blaster.wav"), samples)

def make_attack_railgun() -> None:
    """Railgun: low descending sine punch + crack."""
    duration = 0.2
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        # Descending sine from 200Hz to 60Hz
        freq = 200 - 140 * (t / duration)
        s = math.sin(2 * math.pi * freq * t)
        # Add crack noise at the start
        if t < 0.02:
            s += random.uniform(-0.5, 0.5) * (1.0 - t / 0.02)
        samples.append(s)
    env = _env_adsr(n, 0.005, 0.15, 0.4, 0.6)
    samples = [s * e * 0.7 for s, e in zip(samples, env)]
    _write_wav(os.path.join(OUT_DIR, "attack_railgun.wav"), samples)

def make_attack_plasma() -> None:
    """Plasma: rising sine sweep + high zap."""
    duration = 0.25
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        # Rising sweep from 400Hz to 1500Hz
        freq = 400 + 1100 * (t / duration)
        # Modulated by 8Hz tremolo
        s = math.sin(2 * math.pi * freq * t) * (0.7 + 0.3 * math.sin(2 * math.pi * 8 * t))
        samples.append(s)
    env = _env_adsr(n, 0.05, 0.2, 0.4, 0.5)
    samples = [s * e * 0.5 for s, e in zip(samples, env)]
    _write_wav(os.path.join(OUT_DIR, "attack_plasma.wav"), samples)

def make_hit_enemy() -> None:
    """Enemy hit: low thud + noise burst."""
    duration = 0.12
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        # Low frequency sine (80Hz) with quick decay
        s = math.sin(2 * math.pi * 80 * t) * 0.7
        # Add noise
        s += random.uniform(-0.3, 0.3)
        samples.append(s)
    env = _env_adsr(n, 0.005, 0.3, 0.0, 0.7)
    samples = [s * e for s, e in zip(samples, env)]
    _write_wav(os.path.join(OUT_DIR, "hit_enemy.wav"), samples)

def make_ui_click() -> None:
    """UI click: short blip at 880Hz."""
    duration = 0.04
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        s = math.sin(2 * math.pi * 880 * t)
        samples.append(s)
    env = _env_adsr(n, 0.1, 0.3, 0.0, 0.6)
    samples = [s * e * 0.5 for s, e in zip(samples, env)]
    _write_wav(os.path.join(OUT_DIR, "ui_click.wav"), samples)

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    random.seed(42)  # deterministic
    make_attack_blaster()
    make_attack_railgun()
    make_attack_plasma()
    make_hit_enemy()
    make_ui_click()
    for name in os.listdir(OUT_DIR):
        path = os.path.join(OUT_DIR, name)
        size_kb = os.path.getsize(path) / 1024
        print(f"  wrote {path} ({size_kb:.1f} KB)")
    print(f"\n5 SFX file(s) generated.")

if __name__ == "__main__":
    main()
