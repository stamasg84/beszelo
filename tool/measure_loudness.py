"""Prints peak and RMS (dBFS) of WAV files (16-bit PCM, stdlib only).

Run from the repo root:  python tool/measure_loudness.py [files...]
Default: voices/samples/*.wav and assets/sounds/*.wav
"""
import math
import struct
import sys
import wave
from pathlib import Path


def measure(path):
    with wave.open(str(path), "rb") as w:
        assert w.getsampwidth() == 2, "16-bit PCM only"
        n = w.getnframes() * w.getnchannels()
        s = struct.unpack("<%dh" % n, w.readframes(w.getnframes()))
    peak = max(abs(x) for x in s) / 32768
    rms = math.sqrt(sum(x * x for x in s) / len(s)) / 32768
    db = lambda v: 20 * math.log10(v) if v > 0 else float("-inf")
    return db(peak), db(rms)


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    files = [Path(a) for a in sys.argv[1:]] or sorted(
        list((root / "voices/samples").glob("*.wav"))
        + list((root / "assets/sounds").glob("*.wav"))
    )
    for f in files:
        p, r = measure(f)
        print(f"{f.name:28} peak {p:6.1f} dBFS  rms {r:6.1f} dBFS  crest {p - r:5.1f} dB")
