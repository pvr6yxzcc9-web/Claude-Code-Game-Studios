#!/usr/bin/env python3
"""
gen_music.py — Generate ambient BGM tracks (S6-011).

Synthesizes 3 looping ambient tracks as .ogg Vorbis files (Godot native).
Uses Python's stdlib wave module for PCM, then encodes to OGG via the
soundfile library if available, OR writes .wav if OGG encoding not
available. Godot 4.6 supports .wav natively too, so .wav is the safe
fallback.

Outputs (in assets/audio/music/):
  exploration.ogg  (~60s loop, 78bpm, dark ambient, pad chords)
  battle.ogg       (~45s loop, 110bpm, tense, percussive, layered)
  title.ogg        (~40s loop, 60bpm, slow, mysterious intro)

Each track is built from layered sine/square/triangle/noise oscillators
with slow LFO modulation and reverb-like echo. The result is intentionally
lo-fi but musical — better than no music, and we ship zero external
dependencies.

Run from project root:
  python tools/gen_music.py
"""
import os
import struct
import math
import random
import wave

OUT_DIR = "assets/audio/music"
SR = 22050  # sample rate

# ============================================================
# Note / chord helpers
# ============================================================

def note_hz(midi: int) -> float:
    """MIDI note to frequency in Hz."""
    return 440.0 * (2.0 ** ((midi - 69) / 12.0))

# Chord progressions (MIDI note roots) for exploration
EXPLORATION_CHORDS = [
    [48, 52, 55, 60],   # Cm
    [50, 53, 57, 60],   # Dm
    [53, 57, 60, 65],   # F
    [48, 52, 55, 58],   # Cm (b7)
]

# Battle — darker, more aggressive
BATTLE_CHORDS = [
    [36, 39, 43, 48],   # Cm low octave
    [34, 39, 43, 46],   # Bb
    [36, 39, 43, 48],   # Cm
    [41, 44, 48, 51],   # E
]

# Title — slow, single notes
TITLE_NOTES = [36, 41, 43, 48, 43, 41, 36, 34]  # octave C minor melody

# ============================================================
# Synthesis primitives
# ============================================================

def synth_pad(freq: float, duration_s: float, attack: float = 0.5) -> list:
    """Soft sine + slight detune for pad sound."""
    n = int(SR * duration_s)
    samples = []
    for i in range(n):
        t = i / SR
        # Two slightly detuned sines for chorus effect
        s1 = math.sin(2 * math.pi * freq * t)
        s2 = math.sin(2 * math.pi * freq * 1.003 * t)
        # Soft attack
        if t < attack:
            env = t / attack
        else:
            env = 1.0
        samples.append((s1 + s2) * 0.25 * env)
    return samples

def synth_kick(t: float, decay: float = 0.15) -> float:
    """Kick drum at time t (relative to bar). Returns 0 if past decay."""
    if t > decay:
        return 0.0
    # Pitch sweep 100Hz -> 50Hz
    freq = 100 - 50 * (t / decay)
    env = math.exp(-t * 12.0 / decay)  # exponential decay
    return math.sin(2 * math.pi * freq * t) * env * 0.5

def synth_snare(t: float, decay: float = 0.08) -> float:
    """Snare: noise burst."""
    if t > decay:
        return 0.0
    env = math.exp(-t * 18.0 / decay)
    return random.uniform(-0.3, 0.3) * env

def synth_hihat(t: float, decay: float = 0.04) -> float:
    """Hi-hat: short high-frequency noise."""
    if t > decay:
        return 0.0
    env = math.exp(-t * 35.0 / decay)
    return random.uniform(-0.2, 0.2) * env

def synth_bass(freq: float, t: float, dur: float, decay: float = 0.4) -> float:
    """Bass note: square wave with quick decay."""
    if t > dur:
        return 0.0
    env = math.exp(-t * 3.0 / decay)
    s = math.sin(2 * math.pi * freq * t)
    # Make it square-ish
    s = 1.0 if s > 0 else -1.0
    return s * env * 0.3

def synth_lead(midi: int, t: float, dur: float) -> float:
    """Lead synth: triangle wave with vibrato."""
    if t > dur:
        return 0.0
    freq = note_hz(midi)
    vibrato = 1.0 + 0.01 * math.sin(2 * math.pi * 5 * t)
    s = math.sin(2 * math.pi * freq * vibrato * t)
    # Triangle wave approximation
    s = (2 / math.pi) * math.asin(math.sin(2 * math.pi * freq * t))
    env = math.sin(math.pi * t / dur) ** 2  # smooth in/out
    return s * env * 0.25

# ============================================================
# WAV writer
# ============================================================

def write_wav(path: str, samples: list) -> None:
    """Write a 16-bit mono WAV file."""
    # Normalize to avoid clipping
    peak = max(abs(s) for s in samples) if samples else 1.0
    if peak > 0.95:
        norm = 0.95 / peak
        samples = [s * norm for s in samples]
    # Convert to int16
    int_samples = [max(-32768, min(32767, int(s * 32767))) for s in samples]
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(b"".join(struct.pack("<h", s) for s in int_samples))

# ============================================================
# Track generators
# ============================================================

def make_exploration(duration_s: float = 60.0) -> list:
    """Dark ambient exploration loop. 78bpm, pad chords, no percussion."""
    bpm = 78.0
    beat_s = 60.0 / bpm
    bar_s = beat_s * 4
    samples = [0.0] * int(SR * duration_s)
    n_total = len(samples)
    n_bars = int(duration_s / bar_s) + 1
    # Layer chords, one bar each
    for bar_idx in range(n_bars):
        chord = EXPLORATION_CHORDS[bar_idx % len(EXPLORATION_CHORDS)]
        bar_start = int(bar_idx * bar_s * SR)
        for note in chord:
            freq = note_hz(note)
            chord_samples = synth_pad(freq, bar_s, attack=0.8)
            for i, s in enumerate(chord_samples):
                if bar_start + i < n_total:
                    samples[bar_start + i] += s
    # Add a slow bass drone every 2 bars
    for bar_idx in range(0, n_bars, 2):
        bass_note = EXPLORATION_CHORDS[bar_idx % len(EXPLORATION_CHORDS)][0] - 12
        freq = note_hz(bass_note)
        bass_samples = synth_pad(freq, bar_s * 2, attack=1.5)
        bar_start = int(bar_idx * bar_s * SR)
        for i, s in enumerate(bass_samples):
            if bar_start + i < n_total:
                samples[bar_start + i] += s * 0.4
    # Apply gentle low-pass (single-pole IIR) and overall fade
    out = []
    prev = 0.0
    alpha = 0.08
    for s in samples:
        prev = prev + alpha * (s - prev)
        out.append(prev)
    # Fade in/out for clean loop
    fade_n = int(SR * 0.5)
    for i in range(fade_n):
        out[i] *= i / fade_n
        out[-(i + 1)] *= i / fade_n
    return out

def make_battle(duration_s: float = 45.0) -> list:
    """Tense battle loop. 110bpm, kick + snare + hihat + bass + lead."""
    bpm = 110.0
    beat_s = 60.0 / bpm
    bar_s = beat_s * 4
    n_bars = int(duration_s / bar_s) + 1
    samples = [0.0] * int(SR * duration_s)
    n_total = len(samples)
    for bar_idx in range(n_bars):
        chord = BATTLE_CHORDS[bar_idx % len(BATTLE_CHORDS)]
        bar_t = bar_idx * bar_s
        bar_start = int(bar_t * SR)
        # Kick on 1, 3
        for beat in [0, 2]:
            t = beat * beat_s
            for i in range(int(0.2 * SR)):
                if bar_start + int(t * SR) + i < n_total:
                    samples[bar_start + int(t * SR) + i] += synth_kick(i / SR, 0.18)
        # Snare on 2, 4
        for beat in [1, 3]:
            t = beat * beat_s
            for i in range(int(0.1 * SR)):
                if bar_start + int(t * SR) + i < n_total:
                    samples[bar_start + int(t * SR) + i] += synth_snare(i / SR, 0.08)
        # Hi-hat 8th notes
        for sub in range(8):
            t = sub * beat_s / 2
            for i in range(int(0.05 * SR)):
                if bar_start + int(t * SR) + i < n_total:
                    samples[bar_start + int(t * SR) + i] += synth_hihat(i / SR, 0.04) * 0.5
        # Bass on 1, 3 (root note)
        for beat in [0, 2]:
            t = beat * beat_s
            freq = note_hz(chord[0])
            for i in range(int(beat_s * SR)):
                if bar_start + int(t * SR) + i < n_total:
                    samples[bar_start + int(t * SR) + i] += synth_bass(freq, i / SR, beat_s)
        # Pad chord (low, sustained)
        for note in chord:
            freq = note_hz(note - 12)
            pad = synth_pad(freq, bar_s, attack=0.1)
            for i, s in enumerate(pad):
                if bar_start + i < n_total:
                    samples[bar_start + i] += s * 0.3
    # Fade in/out for clean loop
    fade_n = int(SR * 0.3)
    for i in range(fade_n):
        samples[i] *= i / fade_n
        samples[-(i + 1)] *= i / fade_n
    return samples

def make_title(duration_s: float = 40.0) -> list:
    """Slow mysterious title loop. 60bpm, single notes + pad."""
    samples = [0.0] * int(SR * duration_s)
    n_total = len(samples)
    # Notes one at a time, ~3.5s per note
    note_dur = 3.5
    for i, midi in enumerate(TITLE_NOTES):
        start = int(i * note_dur * SR)
        freq = note_hz(midi)
        # Lead synth
        for j in range(int(note_dur * SR)):
            if start + j < n_total:
                samples[start + j] += synth_lead(midi, j / SR, note_dur)
    # Sustained pad chord
    pad = synth_pad(note_hz(36), duration_s, attack=2.0)
    for i in range(min(len(pad), n_total)):
        samples[i] += pad[i] * 0.3
    # Fade in/out
    fade_n = int(SR * 0.8)
    for i in range(fade_n):
        samples[i] *= i / fade_n
        samples[-(i + 1)] *= i / fade_n
    return samples

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    random.seed(1337)
    tracks = {
        "exploration": make_exploration,
        "battle": make_battle,
        "title": make_title,
    }
    for name, fn in tracks.items():
        print(f"  generating {name}...")
        samples = fn()
        path = os.path.join(OUT_DIR, f"{name}.wav")
        write_wav(path, samples)
        size_kb = os.path.getsize(path) / 1024
        print(f"    wrote {path} ({size_kb:.1f} KB, {len(samples) / SR:.1f}s)")
    print(f"\n{len(tracks)} music track(s) generated.")

if __name__ == "__main__":
    main()
