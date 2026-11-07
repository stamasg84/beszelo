"""Generates the built-in alarm sounds into assets/sounds/ (stdlib only).

Run from the repo root:  python tool/make_sounds.py   (or: uv run tool/make_sounds.py)
Own synthesis, so there is no third-party audio license to track.
Mono, 22050 Hz, 16-bit, peak normalized to about -1 dBFS after tanh compression (squash).
"""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
PEAK = 10 ** (-1 / 20)  # -1 dBFS
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def squash(samples, drive):
    """Loudness by compression: peak normalize, push through tanh(drive * x),
    renormalize. Odd symmetric, so a seamless loop stays seamless. Higher
    drive = flatter peaks = higher RMS (towards a square wave)."""
    top = max(abs(x) for x in samples) or 1.0
    return [math.tanh(drive * x / top) for x in samples]


def write(name, samples):
    top = max(abs(x) for x in samples) or 1.0
    data = b"".join(
        struct.pack("<h", round(x / top * PEAK * 32767)) for x in samples
    )
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


def siren():
    # Frequency sweeps 600 -> 1200 -> 600 Hz (mean 900 Hz) in 2 s: the total
    # phase is 1800 whole cycles, so the end meets the start (phase 0, level
    # 0) and the loop is seamless.
    dur = 2.0
    n = int(RATE * dur)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        out.append(math.sin(2 * math.pi * phase))
        f = 900 - 300 * math.cos(2 * math.pi * t / dur)
        phase += f / RATE
    return out


def bell():
    # Two-tone doorbell: "ding" (E5) at 0 s, "dong" (C5) at 1 s, each a sum
    # of inharmonic-ish partials with faster decay for the higher ones.
    dur = 2.0
    n = int(RATE * dur)
    out = [0.0] * n
    partials = [(1.0, 1.0, 3.0), (2.0, 0.5, 5.0), (3.0, 0.25, 8.0), (4.2, 0.12, 12.0)]
    for start, f0 in ((0.0, 659.25), (1.0, 523.25)):
        for i in range(int(start * RATE), n):
            t = i / RATE - start
            attack = min(1.0, t / 0.004)
            v = sum(
                a * math.exp(-t * d) * math.sin(2 * math.pi * f0 * m * t)
                for m, a, d in partials
            )
            out[i] += v * attack
    fade = int(0.05 * RATE)
    for i in range(fade):
        out[n - 1 - i] *= i / fade
    return out


def horn():
    # Two short loud blasts (A3 then F3), square-ish: odd harmonics.
    n = int(RATE * 1.0)
    out = [0.0] * n
    for start, length, f0 in ((0.0, 0.4, 220.0), (0.5, 0.5, 174.6)):
        s0, s1 = int(start * RATE), int((start + length) * RATE)
        for i in range(s0, s1):
            t = i / RATE - start
            env = min(1.0, t / 0.02, (length - t) / 0.03)
            v = sum(math.sin(2 * math.pi * f0 * k * t) / k for k in (1, 3, 5, 7, 9, 11))
            out[i] += v * env
    return out


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    # Drive per sound (see squash): the siren and horn are meant to be harsh
    # and loud; the bell keeps some of its decay but gets much denser.
    write("siren.wav", squash(siren(), 3.0))
    write("bell.wav", squash(bell(), 4.0))
    write("horn.wav", squash(horn(), 2.0))
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.wav"))))
