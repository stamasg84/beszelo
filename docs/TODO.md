# TODO

Loose ideas and reminders that don't belong to a task in `docs/tasks.md` yet.

## APK size: ABIs
The debug APK is ~293 MB because it includes sherpa-onnx's native libraries for all four ABIs (CPU types): `arm64-v8a` (64-bit ARM, nearly all modern phones), `armeabi-v7a` (32-bit ARM, old/cheap phones), `x86_64` and `x86` (emulators, rare devices). Before releasing, build with `flutter build apk --split-per-abi` (or use an app bundle for Play) so each phone only gets its own ABI. Decide whether to still support `armeabi-v7a` (very old phones), and keep F-Droid in mind: it can build and serve per-ABI APKs too. Bundled voices (~130 MB for `imre` + `berta`) are not affected by this; they are the same in every split.

## Upgrade sherpa_onnx to 2.x (own phonemization)
`pubspec.yaml` is pinned to `sherpa_onnx: ^1.13.8` because 2.0.0+ removed the built-in espeak-ng phonemizer (`dataDir` is ignored), so Piper fails with "phoneme_codepoints is empty, no lexicon, and no frontend available". To use the latest version, phonemize the text ourselves (e.g. `piper_phonemize` or espeak-ng through our own plugin) and pass `OfflineTtsGenerationConfig.phonemeCodepoints`, or use a lexicon. Check that the Hungarian output matches the 1.x output. See the note under T3 in `docs/tasks.md`.
