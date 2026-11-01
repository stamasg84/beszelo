# Mondom

(GitHub repo: `stamasg84/mondom`, renamed from `beszelo`; the local folder is still `beszelo`. App name: **Mondom** ("I say it"), chosen because it has no accents and is pronounceable internationally. Application ID: `io.github.stamasg84.mondom`. Never change it after publishing.)

Free, ad-free, open-source Android speech aid (AAC) for literate adults who lost their speech (ALS, especially bulbar; also stroke, laryngectomy, MS). Hungarian-first.

## Why
Existing apps (Cboard, Speech Assistant AAC, Spoken, Proloquo4Text) rely on the system TTS, and Hungarian only has Google's female voice or robotic eSpeak. A natural male voice is possible (sherpa-onnx + Piper), but setting it up is too hard for families. Most users don't even know that the AAC app and the system TTS engine are separate things, so "it speaks in a female voice" looks like a fact about the app, not a setting anyone could change. Main differentiator: **manageable setup: one install, pick a voice in the app, works offline after that, Hungarian phrases preloaded, nothing paywalled.** All the TTS complexity is hidden; the user only installs the app, opens it, and picks a voice from a short list (e.g. Imre / Berta / Android alapértelmezett), with a sample to listen to for each.

## Core features (MVP)
- Configurable big tiles with whole sentences ("Kérek vizet", "Éhes vagyok", "Segíts felállni", "Várj, gépelek")
- Free-text area with a speak button on the main screen (not hidden in a menu), plus repeat last phrase and history
- Offline Hungarian male (`hu_HU-imre`) and female (`berta`, `anna` if licensed) Piper voices, downloaded in-app; system TTS as an always-available option; other languages via the catalog
- Message banking: record your own voice for any tile, played back in place of TTS. With ALS there's often a window between diagnosis and losing speech, and recordings made then are the most personal option. Plain on-device recording, no accounts, nothing paywalled (Cboard puts this behind a sign-in).
- Bell: loud sound, optionally notify a family member
- Emergency: call 112 / SMS family with GPS location and a predefined message

## Later
Word prediction (Hungarian word endings make typing tiring), Bluetooth speaker and volume boost, large "show text" mode, Switch Access / dwell support as hand function declines, voice banking (fine-tune a Piper voice on the patient's own recordings; message-banking recordings could feed this), a better Hungarian male voice (fine-tune Piper on 1–3 h of expressive recordings from a volunteer/actor).

## Constraints / gotchas
- Android apps can't inject audio into a cellular call. For 112, use speakerphone playback or rely on SMS + location (Android sends location to 112 automatically via AML). Check whether Hungary's 112 accepts SMS.
- Voice licenses: `imre` and `berta` are MIT (checked); `anna` still to check. MIT is compatible with GPL-3.0 bundling, but keep the attribution/license text in the app's "About" screen. espeak-ng (used by sherpa-onnx as the phonemizer) is GPL-3.0, so Mondom should be GPL-3.0; sherpa-onnx itself is Apache-2.0.
- No accounts, all data stored locally. Network only for optional downloads (voices, the voice catalog); everything else works offline.
- Piper voices have flat intonation. To soften it: tune `length_scale` / `noise_scale` / `noise_w` in sherpa-onnx, and punctuate the preloaded phrases ("Kérek vizet!", "Segítenél?"), since Piper uses punctuation for intonation. Larger expressive models (e.g. XTTS-v2) are too heavy for phones and non-commercially licensed.

## Voice delivery & performance
- **No voices bundled in the APK** (decided 2026-11-01, replacing the earlier "bundle imre + berta" plan). One small APK serves every market. On first launch a picker offers the curated voices for the UI language plus **"Android alapértelmezett" (system TTS)**, which works offline immediately, so the app is never mute, even on bad hospital wifi. Piper voices (~60 MB each) are downloaded once and work offline afterwards. Each voice has a short sample (streamed) so families can listen before downloading.
- **Voice catalog**: `voices/catalog.json` in this repo, fetched from raw.githubusercontent.com, with a bundled copy as fallback. The repo is public (since 2026-11-01), so the remote fetch works. It is the curated allowlist (only listed voices can be downloaded, so only license-checked voices are offered) and holds URL, size, sha256, license and sample URL per voice. URLs point at sherpa-onnx's `tts-models` GitHub release; we don't host model files. Mirror them in our own releases only if needed (URL breakage, or `.tar.bz2` extraction too slow on cheap phones). Don't rename the GitHub repo once released apps fetch the catalog from it. F-Droid-friendly (no Play asset packs).
- Piper medium runs faster than real time on ordinary phones (estimated RTF ~0.1–0.3 on mid-range; not yet measured), so no strong hardware is needed.
- **Pre-generate tile audio**: synthesize each tile's sentence once (on create/edit or voice change) and cache the WAV, so tapping a tile plays instantly on any phone, the same way message-banking recordings are played.
- Load the TTS model in the background at app start (loading takes ~1–2 s).
- For long typed text, synthesize sentence by sentence and start playing the first one right away.
- **First technical prototype**: minimal app that speaks typed text with `imre`, tested on the cheapest Android phone available, to measure real speed.

## Stack
Flutter (Dart), sherpa-onnx via its official `sherpa_onnx` Flutter package (Piper ONNX models bundled; sherpa-onnx is the on-device runtime, Piper provides the voices, espeak-ng handles text→phonemes), local storage.

Flutter was chosen over Kotlin/Compose to keep iOS open later. Android is still the only target for now: don't spend effort on iOS until it's actually feasible. Platform-specific bits (emergency call/SMS, bell notifications, audio routing) go behind small platform channels/plugins so an iOS version only has to fill those in. Known iOS differences: SMS can't be sent in the background (the user has to confirm each message), and the App Store distribution model doesn't match F-Droid.

## Working docs
- `docs/architecture.md`: code layout, TTS pipeline, Android asset gotcha.
- `docs/TODO.md`: loose ideas and reminders not yet in a task (e.g. APK size / per-ABI builds).
- `docs/tasks.md`: task breakdown. Agent tasks are run by Sonnet sessions; "You" tasks are manual tests by the human (new to Flutter; tests on a Pixel 6a).

## Status
Validation phase.

Findings so far:
- **Cboard** (tried on Android): closest existing app. Picture + caption tiles, custom tiles and folders, custom text. Gaps: no free-text typing for saying something custom; speaks with the system TTS (female Hungarian voice); recording custom audio for tiles is locked behind a sign-in/"join". Cboard is open source, but targets picture-based communication (largely children); Mondom is typing-first for literate adults, so it's a separate app with Cboard's tile/folder editing as a reference.
- **Voices** (listened to the Piper samples): `berta` is about as good as Google's female voice. `imre` is acceptable but flat, "like an untalented actor reading from paper." Open question for users: is a flat male voice preferable to a lively female one?

Next: ask in a Hungarian ALS Facebook group / speech therapists (logopédusok) what's missing. Play `imre` next to Google's female voice and ask which they'd rather use. Ask "did you know you can change the voice?" (expect mostly no).
