# Architecture

Product context, constraints and stack: see `CLAUDE.md`. This file covers only how the code is organized. It's intentionally thin until the prototype (tasks T1–T6 in `docs/tasks.md`) has validated the TTS pipeline. Expect it to change.

## TTS pipeline

```
text ──► espeak-ng (phonemizer, built into sherpa-onnx) ──► IPA phonemes
     ──► tokens.txt (phoneme → integer ID)
     ──► model.onnx (Piper VITS net, run by onnxruntime inside sherpa-onnx)
     ──► Float32 PCM samples (22050 Hz for imre) ──► WAV file ──► audio player
```

App code makes one call: `OfflineTts.generate(text:, sid: 0, speed:)` → `GeneratedAudio{samples, sampleRate}`.
Voice files per voice (from sherpa-onnx's converted Piper releases):

```
vits-piper-hu_HU-imre-medium/
  hu_HU-imre-medium.onnx      # the net (~60 MB)
  tokens.txt
  espeak-ng-data/             # pronunciation rules, many small files
```

### Android gotcha: assets → files
Native code (sherpa-onnx/espeak-ng) needs real filesystem paths and can't read inside the APK. On first launch, copy the voice folder from Flutter assets into `getApplicationSupportDirectory()` and pass those paths to sherpa-onnx. Skip the copy if it's already done (use a marker file containing the app version). The official example `flutter-examples/tts` in https://github.com/k2-fsa/sherpa-onnx does this. **Use that example as the reference for exact API names.** The Dart API has quirks (e.g. the parameter really is spelled `maxNumSenetences`).

### Threading
`generate()` is a synchronous FFI call and blocks the isolate it runs on. The prototype may run it on the UI isolate (the screen freezes during synthesis; acceptable for measuring). Later: a long-lived background isolate that owns its own `OfflineTts` instance (FFI pointers can't be sent between isolates), receiving text and returning WAV paths.

## Code layout (target)

```
lib/
  main.dart               # app entry, MaterialApp
  tts/
    voice_assets.dart     # copy voice files from assets to app storage, return paths
    tts_engine.dart       # load OfflineTts, synthesize(text) → wav path + timings
  audio/player.dart       # thin wrapper over audioplayers
  ui/                     # screens/widgets (prototype: one screen)
  # later: tiles/, history/, recordings/, emergency/ (platform channel), storage/
assets/voices/<voice-dir>/  # gitignored, filled by tool/fetch_voices.ps1
tool/fetch_voices.ps1       # downloads + extracts voice models
```

Rules:
- Android only (`flutter create --platforms android`). No iOS work yet.
- **Voice model files are never committed** (gitignored). `tool/fetch_voices.ps1` downloads them. The app must build after running it.
- Keep dependencies minimal: `sherpa_onnx`, `path_provider`, `audioplayers`. Ask before adding others.
- UI strings in Hungarian. Code, comments and docs in English.
- Hungarian-first, not Hungarian-only. In the prototype, hardcoded strings are fine. After it, all UI strings move to Flutter's standard `gen-l10n` (ARB files, `hu` as the template locale). Never hardcode language-specific assumptions in logic. Language-specific things include preloaded phrases, the voice list and the emergency number, so treat them as per-locale data.

## Decided later (not in prototype)
Storage (JSON files vs sqlite), state management (start with plain `setState`), tile audio cache layout, voice picker, licenses/About screen.
