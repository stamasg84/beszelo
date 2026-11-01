# TODO

Loose ideas and reminders that don't belong to a task in `docs/tasks.md` yet.

## APK size: ABIs
The debug APK is ~293 MB because it includes sherpa-onnx's native libraries for all four ABIs (CPU types): `arm64-v8a` (64-bit ARM, nearly all modern phones), `armeabi-v7a` (32-bit ARM, old/cheap phones), `x86_64` and `x86` (emulators, rare devices). Before releasing, build with `flutter build apk --split-per-abi` (or use an app bundle for Play) so each phone only gets its own ABI. Decide whether to still support `armeabi-v7a` (very old phones), and keep F-Droid in mind: it can build and serve per-ABI APKs too. Voices are downloaded at runtime, so they don't add to the APK.

## Upgrade sherpa_onnx to 2.x (own phonemization)
`pubspec.yaml` is pinned to `sherpa_onnx: ^1.13.8` because 2.0.0+ removed the built-in espeak-ng phonemizer (`dataDir` is ignored), so Piper fails with "phoneme_codepoints is empty, no lexicon, and no frontend available". To use the latest version, phonemize the text ourselves (e.g. `piper_phonemize` or espeak-ng through our own plugin) and pass `OfflineTtsGenerationConfig.phonemeCodepoints`, or use a lexicon. Check that the Hungarian output matches the 1.x output. See the note under T3 in `docs/done.md`.

## Mirror voice files if needed
The catalog points at sherpa-onnx's `tts-models` release (`.tar.bz2`, each with its own espeak-ng-data copy). If extraction is too slow on a cheap phone or a URL breaks, repackage (zip, shared espeak archive, maybe int8 models) into our own GitHub release and update the catalog URLs.

## int8 voice models
Check whether sherpa-onnx has int8 variants of the Hungarian Piper voices (~1/3 size). If they sound the same, use them in the catalog (faster download).

## flutter_tts applies the Kotlin Gradle Plugin (build warning)
Builds warn: "Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): flutter_tts. Future versions of Flutter will fail to build if your app uses plugins that apply KGP." `flutter_tts` 4.2.5 (latest as of 2026-11-01) hasn't migrated to Built-in Kotlin. Harmless for now. When upgrading Flutter, check for a newer `flutter_tts`; if there is none, replace it with our own small platform channel around Android's `TextToSpeech.synthesizeToFile` (used by `SystemEngine`).
