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
assets/catalog.json         # bundled fallback copy of voices/catalog.json (tool/sync_catalog.ps1)
voices/catalog.json         # curated downloadable voices (see CLAUDE.md "Voice delivery")
# until T10: assets/voices/ + tool/fetch_voices.ps1 bundle imre for development
```

Rules:
- Android only (`flutter create --platforms android`). No iOS work yet.
- **Voice model files are never committed or bundled.** Installed at runtime into `<appSupport>/voices/<id>/`, with one shared `<appSupport>/voices/espeak-ng-data/`.
- Keep dependencies minimal. Approved: `sherpa_onnx`, `path_provider`, `audioplayers`, `flutter_localizations`, `intl`, `flutter_tts`, `shared_preferences`, `http`, `archive`, `crypto`, `package_info_plus`. Ask before adding others.
- UI strings in Hungarian. Code, comments and docs in English.
- Hungarian-first, not Hungarian-only. In the prototype, hardcoded strings are fine. After it, all UI strings move to Flutter's standard `gen-l10n` (ARB files, `hu` as the template locale). Never hardcode language-specific assumptions in logic. Language-specific things include preloaded phrases, the voice list and the emergency number, so treat them as per-locale data.

## Decided later (not in prototype)
Storage (JSON files vs sqlite), state management (start with plain `setState`), tile audio cache layout, licenses/About screen.

## Voices
- `Voice` (id, language, gender, label, kind) + `VoiceEngine` interface (`load`, `synthesizeToWav`, `dispose`). Everything above this layer (UI, tiles, history) only sees `VoiceEngine` and WAV paths.
- `PiperEngine`: sherpa-onnx, loads an installed voice dir. `SystemEngine`: Android TTS via `flutter_tts`, also writes WAV files so playback/caching is uniform.
- `catalog.dart`: remote catalog JSON (one URL constant) → bundled `assets/catalog.json` fallback. Only catalog voices can be downloaded. Skips unknown `schemaVersion` and entries with a newer `minAppVersion`.
- `voice_installer.dart`: download to temp → verify sha256 → extract in a background isolate → move into place. Nothing half-installed ever appears.
