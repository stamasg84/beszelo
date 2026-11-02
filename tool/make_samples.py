"""Generate voices/samples/<voice-id>.wav for every catalog voice.

Uses the same sherpa-onnx version and lengthScale as the app, so previews
sound exactly like the app. Called by make_samples.ps1.
"""
import hashlib
import json
import sys
import tarfile
import urllib.request
import wave
from pathlib import Path

import numpy as np
import sherpa_onnx

LENGTH_SCALE = 1.2  # keep in sync with PiperEngine


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main(root: Path, force: bool) -> None:
    catalog = json.loads((root / "voices/catalog.json").read_text(encoding="utf-8"))
    cache = root / "tool/.cache"
    out_dir = root / "voices/samples"
    cache.mkdir(parents=True, exist_ok=True)
    out_dir.mkdir(parents=True, exist_ok=True)

    for v in catalog["voices"]:
        out = out_dir / f"{v['id']}.wav"
        if out.exists() and not force:
            print(f"{v['id']}: sample exists, skipping")
            continue
        archive = cache / v["url"].rsplit("/", 1)[1]
        if not archive.exists():
            print(f"{v['id']}: downloading {v['url']}")
            urllib.request.urlretrieve(v["url"], archive)
        if sha256(archive) != v["sha256"]:
            archive.unlink()
            sys.exit(f"{v['id']}: sha256 mismatch (deleted cached archive)")
        folder = cache / archive.name.removesuffix(".tar.bz2")
        if not folder.exists():
            with tarfile.open(archive, "r:bz2") as t:
                t.extractall(cache, filter="data")
        text = catalog["sampleText"][v["language"]]
        config = sherpa_onnx.OfflineTtsConfig(
            model=sherpa_onnx.OfflineTtsModelConfig(
                vits=sherpa_onnx.OfflineTtsVitsModelConfig(
                    model=str(folder / v["modelFile"]),
                    tokens=str(folder / "tokens.txt"),
                    data_dir=str(folder / "espeak-ng-data"),
                    length_scale=LENGTH_SCALE,
                ),
                num_threads=2,
            )
        )
        audio = sherpa_onnx.OfflineTts(config).generate(text, sid=0, speed=1.0)
        pcm = (np.clip(np.array(audio.samples), -1, 1) * 32767).astype(np.int16)
        with wave.open(str(out), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(audio.sample_rate)
            w.writeframes(pcm.tobytes())
        print(f"{v['id']}: wrote {out} ({out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main(Path(sys.argv[1]), "--force" in sys.argv)
