#!/usr/bin/env python3
"""Generates the app's short sound effects (correct / retry / finish) as 16-bit mono WAV files.

Usage: python3 Scripts/make_sounds.py Fruits/Resources/Audio
Pure standard library, so the output is reproducible on any Mac.
"""
import math
import struct
import sys
import wave
from pathlib import Path

RATE = 44_100


def tone(freq, duration, volume=0.5, decay=6.0):
    """A soft bell: fundamental plus two gentle harmonics with an exponential decay."""
    samples = []
    count = int(RATE * duration)
    attack = int(RATE * 0.008)
    for i in range(count):
        t = i / RATE
        envelope = math.exp(-decay * t) * (min(1.0, i / attack) if attack else 1.0)
        value = (math.sin(2 * math.pi * freq * t)
                 + 0.35 * math.sin(2 * math.pi * freq * 2 * t)
                 + 0.12 * math.sin(2 * math.pi * freq * 3 * t)) / 1.47
        samples.append(value * envelope * volume)
    return samples


def mix(*parts):
    """parts: (start_seconds, samples)."""
    length = max(int(start * RATE) + len(s) for start, s in parts)
    out = [0.0] * length
    for start, samples in parts:
        offset = int(start * RATE)
        for i, value in enumerate(samples):
            out[offset + i] += value
    peak = max(1e-9, max(abs(v) for v in out))
    scale = min(1.0, 0.9 / peak)
    return [v * scale for v in out]


def write(path, samples):
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v)) * 32767)) for v in samples))


def main():
    out = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    out.mkdir(parents=True, exist_ok=True)
    # Bright two-note "ding-ding" going up (E5 → A5).
    write(out / "correct.wav", mix((0.0, tone(659.25, 0.35)), (0.09, tone(880.0, 0.45))))
    # Gentle, low two-note "boop-boop" going down: encouraging, never harsh.
    write(out / "retry.wav", mix((0.0, tone(392.0, 0.25, volume=0.35, decay=10)),
                                 (0.12, tone(329.63, 0.3, volume=0.35, decay=10))))
    # Happy arpeggio C5 E5 G5 C6.
    notes = [523.25, 659.25, 783.99, 1046.5]
    write(out / "finish.wav", mix(*[(i * 0.11, tone(f, 0.6 if i == 3 else 0.35)) for i, f in enumerate(notes)]))


if __name__ == "__main__":
    main()
