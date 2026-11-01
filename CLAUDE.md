# Mondom

(Repo and folder name: `beszelo`. App name: **Mondom** ("I say it"), chosen because it has no accents and is pronounceable internationally. Application ID: `io.github.stamasg84.mondom`. Never change it after publishing.)

Free, ad-free, open-source Android speech aid (AAC) for literate adults who lost their speech (ALS, especially bulbar; also stroke, laryngectomy, MS). Hungarian-first.

## Why
Existing apps (Cboard, Speech Assistant AAC, Spoken, Proloquo4Text) rely on the system TTS, and Hungarian only has Google's female voice or robotic eSpeak. A natural male voice is possible (sherpa-onnx + Piper), but setting it up is too hard for families. Most users don't even know that the AAC app and the system TTS engine are separate things, so "it speaks in a female voice" looks like a fact about the app, not a setting anyone could change. Main differentiator: **one install, voice bundled, works offline, Hungarian phrases preloaded, nothing paywalled.** All the TTS complexity is handled at build time; the user only installs the app, opens it, and picks "Férfi hang / Női hang".

## Core features (MVP)
- Configurable big tiles with whole sentences ("Kérek vizet", "Éhes vagyok", "Segíts felállni", "Várj, gépelek")
- Free-text area with a speak button on the main screen (not hidden in a menu), plus repeat last phrase and history
- Offline Hungarian male (`hu_HU-imre`) and female (`anna` / `berta`) Piper voices; other languages later
- Message banking: record your own voice for any tile, played back in place of TTS. With ALS there's often a window between diagnosis and losing speech, and recordings made then are the most personal option. Plain on-device recording, no accounts, nothing paywalled (Cboard puts this behind a sign-in).
- Bell: loud sound, optionally notify a family member
- Emergency: call 112 / SMS family with GPS location and a predefined message

## Later
Word prediction (Hungarian word endings make typing tiring), Bluetooth speaker and volume boost, large "show text" mode, Switch Access / dwell support as hand function declines, voice banking (fine-tune a Piper voice on the patient's own recordings; message-banking recordings could feed this), a better Hungarian male voice (fine-tune Piper on 1–3 h of expressive recordings from a volunteer/actor).

## Constraints / gotchas
- Android apps can't inject audio into a cellular call. For 112, use speakerphone playback or rely on SMS + location (Android sends location to 112 automatically via AML). Check whether Hungary's 112 accepts SMS.
- Voice licenses: `imre` and `berta` are MIT (checked); `anna` still to check. MIT is compatible with GPL-3.0 bundling, but keep the attribution/license text in the app's "About" screen. espeak-ng (used by sherpa-onnx as the phonemizer) is GPL-3.0, so Mondom should be GPL-3.0; sherpa-onnx itself is Apache-2.0.
- No accounts, no network needed, all data stored locally.
- Piper voices have flat intonation. To soften it: tune `length_scale` / `noise_scale` / `noise_w` in sherpa-onnx, and punctuate the preloaded phrases ("Kérek vizet!", "Segítenél?"), since Piper uses punctuation for intonation. Larger expressive models (e.g. XTTS-v2) are too heavy for phones and non-commercially licensed.

## Voice delivery & performance
- **Bundle `imre` and `berta` in the APK** (~60 MB each, ~130 MB total). The app must speak the moment it's opened: setup often happens in hospitals / on poor connections, and families want to hear both voices before choosing. Downloading the chosen voice on selection was considered and rejected for the MVP; revisit only if app size becomes a real complaint.
- **Extra voices are optional downloads**: `anna`, other languages, a future better male voice, the patient's own trained voice. Non-critical, so a failed download is acceptable. Keep F-Droid in mind (Play asset packs only work for Play installs).
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
- `docs/tasks.md`: task breakdown. Agent tasks are run by Sonnet sessions; "You" tasks are manual tests by the human (new to Flutter; tests on a Pixel 6a).

## Status
Validation phase.

Findings so far:
- **Cboard** (tried on Android): closest existing app. Picture + caption tiles, custom tiles and folders, custom text. Gaps: no free-text typing for saying something custom; speaks with the system TTS (female Hungarian voice); recording custom audio for tiles is locked behind a sign-in/"join". Cboard is open source, but targets picture-based communication (largely children); Mondom is typing-first for literate adults, so it's a separate app with Cboard's tile/folder editing as a reference.
- **Voices** (listened to the Piper samples): `berta` is about as good as Google's female voice. `imre` is acceptable but flat, "like an untalented actor reading from paper." Open question for users: is a flat male voice preferable to a lively female one?

Next: ask in a Hungarian ALS Facebook group / speech therapists (logopédusok) what's missing. Play `imre` next to Google's female voice and ask which they'd rather use. Ask "did you know you can change the voice?" (expect mostly no).
