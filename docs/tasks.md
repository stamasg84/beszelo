# Tasks

How to use: start a Sonnet session (`claude --model sonnet`) and say "Do task T14 from docs/tasks.md". Read `docs/architecture.md` first.
**Agent** tasks: stay in scope, run the listed checks, finish with a short summary of what changed and what the human should verify. Don't commit; the human commits after testing.
**You** tasks: done by the human (new to Flutter) on Windows + a Pixel 6a. Flutter SDK and Android Studio are installed, `flutter doctor` is OK, developer mode is on.
Mark tasks done by changing `[ ]` to `[x]`. When a phase is finished, move it to `docs/done.md`.

---

## Phase 4: Riasztás (alarm)

Goal: a loud alarm without a new button: a seeded, pinned "Riasztás" list whose rows are sentences with a built-in sound, and an `alarm` flag on any row. Read `docs/architecture.md` "Alarm" first (and "Storage", "Sentence lists"). 112 / emergency SMS is dropped (`docs/TODO.md` "Emergency").

### [x] T21 (Agent): Built-in sounds, schema v4, Riasztás seed
- New `tool/make_sounds.py` (Python stdlib only: `wave`, `math`, `struct`; run with `uv run` or plain `python`) generating `assets/sounds/siren.wav` (rising/falling sweep, ~2 s, loops seamlessly: start and end at zero phase/amplitude), `bell.wav` (two-tone doorbell-like chime with decaying harmonics, ~2 s), `horn.wav` (short loud two-tone horn, ~1 s). Mono, 22050 Hz, 16-bit, normalized to about -1 dBFS. Commit the script and the WAVs; register `assets/sounds/` in `pubspec.yaml`.
- New `lib/speech/sounds.dart`: `const builtInSounds = {'siren': BuiltInSound(asset: 'sounds/siren.wav', loops: true), 'bell': …, 'horn': …}` and `const alarmLoopLimit = Duration(minutes: 2)`.
- Schema v4: `sentences.soundKey` (text, nullable) and `sentences.alarm` (bool, default false), with a migration from v3. Regenerate `database.g.dart`.
- Repository: copy/move keep `soundKey`, `alarm` (and `recordingPath`). Seed parsing reads optional `"sound"` and `"alarm"` per sentence.
- New palette color `red` in `lib/ui/list_colors.dart` (light and dark, WCAG AA for row text like the others). Not picked automatically for new user lists ahead of the existing colors (keep the current "next unused" order, `red` last).
- Seed files `hu`, `en`, `sv`: a new last list `{ "seedKey": "alarm", "kind": "everyday", "pinned": true, "color": "red" }`, titles "Riasztás" / "Alarm" / "Larm", rows: "Vészhelyzet!" (siren), "Gyere ide!" (bell), "Figyelj rám!" (horn), all `"alarm": true`; en: "Emergency!", "Come here!", "Listen to me!"; sv: "Nödläge!", "Kom hit!", "Lyssna på mig!". Keep the test fixture seed in sync where tests need it (T19c).
- Tests: migration v3→v4 keeps data; seed rows get `soundKey`/`alarm`; copy/move keep them; restore-defaults re-adds the Riasztás list.
- **Checks:** `flutter analyze`, `flutter test`.

### [x] T22 (Agent): Alarm playback on the speaking screen
- `Speaker` gets a row-level entry, e.g. `play(SentenceRowData)` (text, soundKey, alarm), used by row taps and Következő; `speak(text)` stays for free text. What plays: known `soundKey` → its asset; otherwise TTS of the text (unknown key = TTS). Last-utterance reuse stays for TTS.
- Alarm rows play on a **separate** `AudioPlayer` with an alarm `AudioContext` (Android usage `alarm`, content type `sonification`, transient audio focus), so the speech player's context is never changed. Non-alarm sound rows play on the normal player. Looping sounds use `ReleaseMode.loop` and are stopped by a timer after `alarmLoopLimit`.
- Only one thing plays at a time: any row tap, Mondom, Következő or Leállítás stops what's playing (alarm or speech) first. Tapping the same alarm row again restarts it.
- `Speaker` exposes `alarmPlaying` (it's a `ChangeNotifier`). While true, the speaking screen shows a large **"Leállítás"** button in the Következő spot (any list kind; in a conversation list it replaces Következő until stopped).
- Alarm rows are not added to history (both row taps and Következő). `said` and builder load behave as for any row.
- Row look (speaking screen): alarm rows only get a leading badge: `Icons.campaign` (megaphone), white in a filled red circle; nothing for non-alarm rows, whether or not they have a sound. List editor rows: a leading icon for a built-in sound (bell → `Icons.notifications_active`, horn → e.g. `Icons.surround_sound`, siren → e.g. `Icons.crisis_alert`) plus the same alarm badge. (A mic icon for recordings comes with message banking.)
- Playback uses the alarm stream's current volume in this task (the setting is T24).
- ARB: "Leállítás" (+ en "Stop").
- Tests: alarm row tap doesn't touch history; Leállítás appears while an alarm plays and stops it (fake player); loop stops after the limit (fake timer / injectable duration).
- **Checks:** `flutter analyze`, `flutter test`.

### [x] T23 (Agent): Alarm toggle in the list editor
- In the per-row ⋮ sheet of the list editor: a switch "Riasztásként szóljon (hangosan)" that sets `alarm`. Short help text under it: "Riasztás hangerején szól, és nem kerül az előzmények közé."
- Not offered on the history list's rows (history rows are never alarms; copying one into a list and flagging it there is fine).
- Choosing a row's sound is not part of this task (later, with message banking).
- **Checks:** `flutter analyze`, `flutter test`.

### [x] T24 (Agent): Alarm volume setting (raise and restore)
- Native: in `MainActivity.kt`, a small channel (e.g. `mondom/alarm_volume`): `get` (current/max of `STREAM_ALARM`), `set(level)`. No new permission. Dart wrapper `lib/speech/alarm_volume.dart`.
- Setting in `shared_preferences`: `alarmVolumeMode` = `system` | `custom` (default `custom`), `alarmVolumeLevel` 0.0–1.0 (default 1.0).
- Drawer row "Riasztás hangereje" → small screen: two large radio rows "A telefon ébresztési hangereje" / "Saját hangerő", a slider (enabled for Saját), and a "Kipróbálás" button that plays the bell as an alarm (stoppable).
- `custom` mode, around each alarm playback: if no `alarmVolumeSaved` pref exists, save the current level; set the stream to the slider level (rounded to the stream's steps; remember the level we set). On end/stop/loop limit: if the stream is still at the level we set, restore the saved level; then delete the pref either way. On app start: if `alarmVolumeSaved` exists (app was killed mid-alarm), do the same restore check.
- Tests (Dart side, fake channel): save/raise/restore; no restore when the user changed the level; startup restore; a second alarm while one plays doesn't overwrite the saved level.
- **Checks:** `flutter analyze`, `flutter test`.

### [ ] T25 (You): Try the alarm
1. On the existing install: ☰ → Listák → "Alapértelmezett listák visszaállítása": the red Riasztás chip appears last.
2. Tap each row. Bell and horn play once, the siren loops; Leállítás stops it. Let the siren run to check it stops after 2 minutes. Nothing appears in Előzmények.
3. Turn the alarm volume low with the phone settings, set Saját hangerő to max, play the siren from another room's distance, stop it: the phone's alarm volume is back to low. Try with Do Not Disturb on, and with the phone's volume buttons pressed during the siren.
4. In the editor, flag "Kérek vizet!" as an alarm: it's spoken loudly and stays out of history.
5. Note: is the siren too annoying / not loud enough, do the sentences fit, would a family member hear the bell from the next room?
Done → commit.

---

## Later (rough)
- Carry unsaid sentences of a conversation over to a new one.
- Offer new default lists/sentences added in later app versions to existing users (seed version).
- Message banking (record your own audio for a sentence).
- Speech speed setting (lengthScale): a row in the drawer (T19b).
- About screen (a row in the settings screen, T18) with licenses; needed before the Play Store release (Alma is CC BY 4.0 and needs credit) (GPL-3.0 app; per-voice licenses from the catalog; Apache-2.0 sherpa-onnx).
