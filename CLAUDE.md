# Beszélő

Free, ad-free, open-source Android speech aid (AAC) for literate adults who lost their speech (ALS, especially bulbar; also stroke, laryngectomy, MS). Hungarian-first.

## Why
Existing apps (Cboard, Speech Assistant AAC, Spoken, Proloquo4Text) rely on the system TTS, and Hungarian only has Google's female voice or robotic eSpeak. A natural male voice is possible (sherpa-onnx + Piper), but setting it up is too hard for families. Main differentiator: **one install, voice bundled, works offline, Hungarian phrases preloaded, nothing paywalled.**

## Core features (MVP)
- Configurable big tiles with whole sentences ("Kérek vizet", "Éhes vagyok", "Segíts felállni", "Várj, gépelek")
- Quick-access text area with a speak button, plus repeat last phrase and history
- Offline Hungarian male (`hu_HU-imre`) and female (`anna` / `berta`) Piper voices; other languages later
- Bell: loud sound, optionally notify a family member
- Emergency: call 112 / SMS family with GPS location and a predefined message

## Later
Word prediction (Hungarian word endings make typing tiring), Bluetooth speaker and volume boost, large "show text" mode, Switch Access / dwell support as hand function declines, voice banking or cloning.

## Constraints / gotchas
- Android apps can't inject audio into a cellular call. For 112, use speakerphone playback or rely on SMS + location (Android sends location to 112 automatically via AML). Check whether Hungary's 112 accepts SMS.
- Check each Piper voice's license.
- No accounts, no network needed, all data stored locally.

## Stack
Kotlin, Jetpack Compose, sherpa-onnx (Piper ONNX models bundled), local storage.

## Status
Validation phase: listen to the `imre` samples, try existing apps, ask in a Hungarian ALS Facebook group / ask speech therapists (logopédusok) what's missing.
