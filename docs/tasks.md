# Tasks

How to use: start a Sonnet session (`claude --model sonnet`) and say "Do task T7 from docs/tasks.md". Read `docs/architecture.md` first.
**Agent** tasks: stay in scope, run the listed checks, finish with a short summary of what changed and what the human should verify. Don't commit; the human commits after testing.
**You** tasks: done by the human (new to Flutter) on Windows + a Pixel 6a. Flutter SDK and Android Studio are installed, `flutter doctor` is OK, developer mode is on.
Mark tasks done by changing `[ ]` to `[x]`. When a phase is finished, move it to `docs/done.md`.

---

## Phase 2: voices (system TTS + downloadable Piper voices)

Decision: no voices are bundled in the APK. On first launch the user picks a voice. The system TTS ("Android alapértelmezett") works offline right away; Piper voices are downloaded once. The downloadable voices are listed in a curated catalog JSON in this repo, pointing at sherpa-onnx's `tts-models` release. See `docs/architecture.md` "Voices".

### [x] T7 (Agent): Localization setup
- Add `flutter_localizations` (SDK) and `intl`; set `generate: true` in `pubspec.yaml`; add `l10n.yaml` with `arb-dir: lib/l10n`, `template-arb-file: app_hu.arb`, `output-localization-file: app_localizations.dart`.
- Move every user-visible string of the current screen into `lib/l10n/app_hu.arb` (with `@key` descriptions). Add `app_en.arb` with English translations so the fallback path is exercised.
- `MaterialApp`: `localizationsDelegates`, `supportedLocales`. Hungarian when the phone is Hungarian, English otherwise.
- **Checks:** `flutter analyze`, `flutter test` (update the widget test to pump with the delegates).

### [x] T8 (Agent): Voice abstraction + system TTS
- Add `flutter_tts` and `shared_preferences`.
- `lib/voices/voice.dart`: `Voice` (id, languageCode e.g. `hu`, gender `male|female|unknown`, label, `VoiceKind { system, piper }`).
- `lib/voices/voice_engine.dart`: abstract `VoiceEngine { Future<void> load(); Future<SynthResult> synthesizeToWav(String text); void dispose(); }`. All callers (UI, later tiles) use only this.
- `PiperEngine`: refactor of the current `TtsEngine`. Takes the voice **directory path** and model file name instead of hardcoding imre. For now the path still comes from the bundled-asset copy (`VoiceAssets`); T10 replaces that with downloads. Default `lengthScale` = **1.2** (from `measurements.md`).
- `SystemEngine`: `flutter_tts` with the voice's language. Synthesize to a WAV file (`synthesizeToFile`; check the current package API for writing to a full path and for awaiting completion) so playback, "Ismétlés" and later tile caching work the same way as with Piper.
- Temporary dropdown on the main screen: "Imre" / "Android alapértelmezett". Persist the choice with `shared_preferences` and load it at start.
- Remove the "Hangolás" section (the noise sliders made no audible difference). Keep the timing text.
- **Checks:** `flutter analyze`, `flutter test`. Report what `synthesizeToFile` needed on Android (permissions, path quirks).

### [x] T9 (You): Compare system voice and imre
1. `flutter run --profile`. Switch between the two voices and speak the same sentences.
2. Check that the system voice works with airplane mode on (Google's Hungarian voice may need a one-time download in Android Settings → System → Languages → Text-to-speech).
3. Note in `measurements.md`: system TTS synthesis time, and how imre at length 1.2 compares.
Done → commit.

### [ ] T10 (Agent): Voice catalog + Piper downloads
- `voices/catalog.json` in the repo. The remote URL is a single constant in `catalog.dart` (`https://raw.githubusercontent.com/stamasg84/mondom/main/voices/catalog.json`). If the remote fetch fails (offline, URL broken), the app must silently use the bundled copy. Format:
  ```json
  { "schemaVersion": 1,
    "voices": [ { "id": "hu_HU-imre-medium", "language": "hu", "gender": "male", "label": "Imre",
                  "url": "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-hu_HU-imre-medium.tar.bz2",
                  "sizeBytes": 0, "sha256": "...", "modelFile": "hu_HU-imre-medium.onnx",
                  "sampleUrl": "https://raw.githubusercontent.com/stamasg84/mondom/main/voices/samples/hu_HU-imre-medium.wav",
                  "license": "MIT", "minAppVersion": "1.0.0" } ],
    "sampleText": { "hu": "Szia! Kérek egy pohár vizet. Segítenél felállni?",
                    "en": "Hi! Could I have a glass of water, please? Can you help me stand up?" } }
  ```
  Entries: `imre`, `berta`, and `anna` **only if** its license is verified (check the Piper model card on HuggingFace `rhasspy/piper-voices`, `hu/hu_HU/anna/`, and report what it says). Get `sizeBytes`/`sha256` by downloading each file (`Get-FileHash`). The app also uses `sampleText` for the system voice preview (spoken live).
- **Samples:** `tool/make_samples.ps1` generates `voices/samples/<voice-id>.wav` for every catalog voice, so previews sound exactly like the app:
  - Uses the Python `sherpa-onnx` package **pinned to the same 1.x version as the app** (2.x dropped espeak-ng), installed into a venv under `tool/.venv` (gitignored). The Python part goes in `tool/make_samples.py`; the `.ps1` only sets up the venv and calls it.
  - For each voice: download/extract its archive (cache under `tool/.cache/`, gitignored; verify sha256), synthesize the catalog's `sampleText` for the voice's language with `lengthScale` 1.2 (same as the app), write a mono 16-bit WAV.
  - Idempotent: skip voices whose sample exists unless `-Force`.
  - Run it and commit the WAVs (expect ~200 KB each; report the sizes). Verify each `sampleUrl` path matches a generated file. (The raw URLs only work once the repo is public; until then previews fail gracefully in the picker.)
- Copy the same file to `assets/catalog.json` as the bundled fallback (add a tiny `tool/sync_catalog.ps1` that does the copy, and note it in architecture.md).
- `lib/voices/catalog.dart`: fetch the remote catalog (short timeout), fall back to the bundled one. Ignore unknown `schemaVersion`s and entries whose `minAppVersion` is newer than the app.
- `lib/voices/voice_installer.dart`: download to a temp file with progress (stream, bytes received / `sizeBytes`), verify the sha256, extract the `.tar.bz2` **in a background isolate** (`archive` package), and move it into `<appSupport>/voices/<id>/` only when complete. Keep **one shared** `<appSupport>/voices/espeak-ng-data/` (extract it from the first voice, skip it for later ones). Support cancel; a failed or cancelled download leaves nothing behind. Provide `isInstalled(id)` and `delete(id)`.
- Add deps: `http`, `archive`, `crypto`, `package_info_plus`.
- Remove the bundled voice: the asset entries in `pubspec.yaml`, `VoiceAssets`, `tool/fetch_voices.ps1`. `PiperEngine` now loads from the installed directory.
- Add the `INTERNET` permission to the main `AndroidManifest.xml`.
- **Checks:** `flutter analyze`, `flutter test` (unit-test catalog parsing/filtering and sha mismatch handling with a fake file), `flutter build apk --debug 2>&1 | tail -40`; report the new APK size. Log download and extraction ms with `debugPrint`.

### [ ] T11 (Agent): First-run voice picker
- Shown on first launch (no saved voice) and from a settings icon on the main screen.
- Lists catalog voices for the UI language first, then "Más nyelvek" (expandable), and always "Android alapértelmezett". Each row: label, gender, size ("63 MB"), ▶ sample (streams `sampleUrl`; if it fails, show a short "A minta nem érhető el" message; the system voice previews by speaking the catalog's `sampleText` for its language), and a state: *Letöltés* / progress bar + *Mégse* / *Kiválasztva*. Installed voices can be deleted.
- "Kihagyás" selects the system voice. If the catalog can't be fetched and there's no network, the system voice is still selectable and the screen says downloads need internet.
- Replaces T8's temporary dropdown. All strings via ARB (hu + en).
- **Checks:** `flutter analyze`, `flutter test` (widget test: the picker renders with a fake catalog; skip selects the system voice).

### [ ] T12 (You): Test the first run
1. Uninstall the app from the phone, then `flutter run --profile`.
2. Airplane mode on: the picker appears, the system voice works, downloads say they need internet.
3. Network on: preview the samples, download imre (note download + extraction time from the log), select it, speak.
4. Start downloading berta and cancel halfway. Start again and turn off wifi midway. The app must stay usable and no broken voice may appear.
5. Close and reopen: the chosen voice is remembered.
Done → commit.

### [ ] T13 (Agent): Background synthesis + sentence streaming
- A long-lived background isolate owns the `PiperEngine` (FFI pointers can't cross isolates). The UI sends text and gets WAV paths back. Load the saved voice at app start.
- Long text: split into sentences (`.`, `!`, `?`, `…`, newlines; keep the punctuation, Piper uses it for intonation), play the first as soon as it's ready, queue the rest.
- **Checks:** `flutter analyze`, `flutter test`.

---

## Later (rough)
- Tile grid with preloaded Hungarian phrases (per-locale data); pre-generated, cached WAV per tile, regenerated on voice change.
- History of spoken phrases.
- Message banking (record your own audio for a tile).
- Bell; emergency SMS with GPS (platform channel).
- Speech speed setting (lengthScale) in settings.
- About screen with licenses (GPL-3.0 app; per-voice licenses from the catalog; Apache-2.0 sherpa-onnx).
