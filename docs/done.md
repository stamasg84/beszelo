# Done tasks

Completed tasks, moved out of `docs/tasks.md` to keep it short. Kept for reference (results, gotchas found along the way).

---

## Prototype: speak typed text with imre

### [x] T1 (Agent): Scaffold the Flutter app
- Run `flutter create --platforms android --org io.github.stamasg84 --project-name mondom .` in the repo root. Don't touch `CLAUDE.md` or `docs/`.
- Replace the counter demo in `lib/main.dart` with a single screen: title "Mondom", centered text "Szia!". Update `test/widget_test.dart` to match.
- In `android/app/build.gradle(.kts)`: `minSdk = 24`. App label "Mondom" in `AndroidManifest.xml`.
- Append `assets/voices/` to `.gitignore`.
- **Checks:** `flutter analyze` (no issues), `flutter test` (passes). No APK build here: the human builds in T2 via `flutter run`.

### [x] T2 (You): Run the app on the Pixel
1. Phone: Settings → System → Developer options → turn on **USB debugging**.
2. Connect via USB. On the phone, accept "Allow USB debugging?" (tick "Always allow").
3. `flutter devices` should list the Pixel 6a.
4. In the repo root: `flutter run`. The first run takes a few minutes. You should see "Szia!" on the phone.
5. Try hot reload: change "Szia!" in `lib/main.dart`, save, press `r` in the terminal. The phone updates within about 1 s. Press `q` to quit.

If the phone isn't listed: try another cable or USB port; pull down the notification shade → USB → "File transfer"; Android Studio → SDK Manager → SDK Tools → install **Google USB Driver**. If it shows as "unauthorized": Developer options → Revoke USB debugging authorizations, then replug.
Done → commit: `git add -A && git commit -m "Scaffold Flutter app"`.

### [x] T3 (Agent): Speak a hardcoded sentence with imre
- `tool/fetch_voices.ps1`: download `https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-hu_HU-imre-medium.tar.bz2` (check that the URL exists; if it doesn't, find the correct name in the `tts-models` release) and extract it into `assets/voices/` (Windows `tar -xf` handles .bz2). Make it idempotent: skip the download if the folder exists. Run it.
- `pubspec.yaml`: add `sherpa_onnx`, `path_provider`, `audioplayers`. Register the assets. Flutter asset dirs are **not recursive**, so every subfolder of `espeak-ng-data/` needs its own entry. Generate the list from the actual extracted tree.
- `lib/tts/voice_assets.dart`: copy the voice folder to app support storage (see architecture.md "Android gotcha"). The copy list comes from `AssetManifest` (`AssetManifest.loadFromAssetBundle`), filtered by prefix.
- `lib/tts/tts_engine.dart`: `initBindings()`, build `OfflineTts` with `vits: model/tokens/dataDir`, `numThreads: 2`. Expose `Future<void> load()` and `Future<String> synthesizeToWav(String text)`, which writes to the temp dir with sherpa-onnx's `writeWave`.
- UI: a "Beszélj" button that speaks "Szia! Kérek egy pohár vizet." It is disabled until the model is loaded, and the screen shows "Betöltés…" while loading. Use `debugPrint` to log load ms and synthesis ms.
- Mirror the official `flutter-examples/tts` example for API usage.
- **Phonemization gotcha (found in T4):** `sherpa_onnx` 2.x (2.0.0+) removed the built-in espeak-ng phonemizer; `dataDir` is ignored, so Piper fails with "phoneme_codepoints is empty, no lexicon, and no frontend available" (and then `IntegerDivisionByZeroException` in the RTF log). `pubspec.yaml` is therefore pinned to `sherpa_onnx: ^1.13.8`, the last 1.x. **TODO: move to the latest sherpa_onnx** by phonemizing ourselves (e.g. `piper_phonemize` / espeak-ng via our own plugin, passing `OfflineTtsGenerationConfig.phonemeCodepoints`), or with a lexicon. Check licensing (espeak-ng is GPL-3.0, fine for Mondom) and that Hungarian output matches the 1.x output.
- **Checks:** `flutter analyze`, then `flutter build apk --debug 2>&1 | tail -40` (native deps and asset config break here; read only the tail). Report the APK size (`build/app/outputs/flutter-apk/`).

### [x] T4 (You): Hear imre on the phone
1. Run `.\tool\fetch_voices.ps1` once, if `assets\voices\` is empty.
2. `flutter run --profile`. Profile mode gives realistic speed; debug mode is slower.
3. Wait for "Betöltés…" to disappear, then tap **Beszélj**.
4. Note: Did it speak? Is the pronunciation correct? Load time and synthesis time (from the terminal log lines).

If it crashes or stays silent: copy the terminal output from the first red/`E/` line onward and paste it into a Claude session along with "T4 failed".
Result (Pixel 6a): works after the sherpa_onnx 1.x pin; synthesis ~115 ms for the test sentence, load time decent.
Done → commit.

### [x] T5 (Agent): Text field, timings on screen, voice tuning
- Main screen: a large multi-line `TextField` (font ≥ 24), a large "Beszélj" button below it, and an "Ismétlés" button (replays the last WAV without re-synthesizing).
- Show the timings on screen in small text: model load ms; for the last utterance, synthesis ms, audio duration ms and RTF (= synthesis / duration).
- An expandable "Hangolás" section with sliders: `lengthScale` 0.7–1.5 (default 1.0), `noiseScale` 0.3–1.0 (default 0.667), `noiseScaleW` 0.3–1.0 (default 0.8). These values are fixed at model creation, so changing them reloads `OfflineTts` and shows the reload time.
- **Checks:** `flutter analyze`, `flutter test`. No APK build; the human runs it in T6.

### [x] T6 (You): Measure
In `flutter run --profile`, speak:
1. "Kérek vizet!"
2. A 2–3 sentence paragraph.
3. The same short phrase 3 times.

Write down the load ms and the RTF for each in `docs/measurements.md` (just paste the numbers). Try the sliders and note which settings sound least flat.
The Pixel 6a is mid-to-upper range, so cheap phones will be slower. Treat an RTF under 0.3 here as comfortable.
Done → commit. Then ask Opus to plan the next phase using these results.
Result: see `docs/measurements.md` (load ~800 ms, short phrase ~120–140 ms; lengthScale 1.2 sounds best, noise sliders inaudible).

