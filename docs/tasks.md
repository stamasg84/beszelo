# Tasks

How to use: start a Sonnet session (`claude --model sonnet`) and say "Do task T14 from docs/tasks.md". Read `docs/architecture.md` first.
**Agent** tasks: stay in scope, run the listed checks, finish with a short summary of what changed and what the human should verify. Don't commit; the human commits after testing.
**You** tasks: done by the human (new to Flutter) on Windows + a Pixel 6a. Flutter SDK and Android Studio are installed, `flutter doctor` is OK, developer mode is on.
Mark tasks done by changing `[ ]` to `[x]`. When a phase is finished, move it to `docs/done.md`.

---

## Phase 3: sentence lists

Goal: the real speaking screen. Everything speakable is a sentence list, stored in SQLite (drift), seeded with per-locale default lists. Read `docs/architecture.md` "Speaking", "Storage" and "Sentence lists" first. State management stays plain `setState` + drift `watch` streams (`StreamBuilder`); no state-management package.

### [x] T14 (Agent): Speaker service, single "Mondd" button
- New `lib/speech/speaker.dart`: `Speaker` owns the current `VoiceEngine` and the `AudioPlayer` (move that logic out of `main.dart`). API: `Future<void> speak(String text)`, `Future<void> setVoice(Voice v)`, `stop()`, plus `busy`/`lastResult` for the UI (a `ChangeNotifier` is fine).
- **Last-utterance reuse:** `Speaker` remembers the last `(voice id, text)` → WAV path. Key = text trimmed with inner whitespace collapsed. Same key → stop current playback and replay the WAV from the start, without synthesizing. Different key → synthesize, then delete the previous WAV file (temp WAVs currently pile up in the temp dir). Switching voice clears the key. Only the last one is remembered; this is not a cache.
- Main screen: remove "Ismétlés". Keep the text in the field after speaking; add a large ✕ (clear) button inside the field. Mondd with an unchanged text = replay.
- Keep the small timing text (show "replay" instead of synth ms when reused).
- Remove the now-unused ARB key(s) in both `app_hu.arb` and `app_en.arb`.
- **Checks:** `flutter analyze`, `flutter test` (unit-test `Speaker` with a fake `VoiceEngine` that counts calls and a fake player: same text twice = 1 synthesis; whitespace-only difference = 1; different text = 2 and the old WAV is deleted; voice switch = re-synthesis).

### [x] T15 (Agent): Storage (drift) + seed data
- Add `drift`, `drift_flutter`; dev: `drift_dev`, `build_runner`. Commit the generated `*.g.dart` files (so a plain `flutter run` works without codegen). Note the regen command (`dart run build_runner build --delete-conflicting-outputs`) in architecture.md.
- `lib/storage/database.dart` with the tables from architecture.md "Storage": `sentence_lists`, `sentences`. Schema version 1.
- `assets/seed/hu.json`, `assets/seed/en.json` (format in architecture.md). Contents:
  - `everyday` list ("Alap" / "Basics"), pinned: ~25 short, well-punctuated phrases covering needs (water, food, toilet, pain, position, cold/hot, glasses, phone, TV, light), feelings, answers (Igen. / Nem. / Nem tudom. / Köszönöm!), and the meta phrases ("Várj, gépelek.", "Ismételd meg, kérlek!", "Lassabban, kérlek!"). Include the ones from `CLAUDE.md`. Natural, adult register (tegeződés, which is how family talks); no childish phrasing.
  - `example-conversation` ("Példa beszélgetés" / "Example conversation"), kind `conversation`, not pinned: the 3 sentences from `CLAUDE.md`'s prepared-conversation example (English: equivalent everyday sentences), so users discover the feature.
  - Every list and sentence has a stable `seedKey` (e.g. `"everyday"`, `"water"`).
- `onCreate`: insert the seed for the UI language (fallback `en`), plus the single `history` list ("Előzmények" / "History", pinned, `seedKey: "history"`; its title is localized at display time via ARB, not stored).
- `lib/storage/lists_repository.dart`: the only API the UI uses. At least: `watchLists()`, `watchSentences(listId)` (ordered), `createList`, `renameList`, `deleteList` (not for history), `setPinned`, `reorderLists`, `addSentences(listId, texts, {at})`, `updateSentenceText`, `deleteSentence`, `moveSentence(id, toListId)`, `copySentence(id, toListId)`, `reorderSentences(listId, ids)`, `setSaid(id, bool)`, `resetSaid(listId)`, `addToHistory(text)`, `restoreDefaultSentences(listId)`, `restoreDefaultLists()`, `hasMissingDefaults(listId)`.
  - `addToHistory`: if the same text (same normalization as `Speaker`) is already in history, move it to the top instead of duplicating; cap at 30 via a single constant `historyCap` (drop the oldest, no exceptions; history rows are separate `sentences` rows, so this never affects permanent lists. A recording only survives if a sentence in a non-history list has it. No recording files exist yet, so don't delete any files here).
  - Restore rules: see architecture.md "Storage" (only re-adds missing seed items, never deletes or changes anything).
- Last used list id: `shared_preferences`.
- **Checks:** `flutter analyze`, `flutter test` (in-memory drift DB, `NativeDatabase.memory()`): seeding hu vs en; history dedupe + cap; restore re-adds a deleted seed sentence at its seed position, doesn't duplicate an edited one, leaves user-added sentences alone; restore lists re-creates a deleted seed list; deleting a list cascades its sentences. `flutter build apk --debug 2>&1 | tail -40` (native sqlite libs).

### [ ] T16 (Agent): Speaking screen
- Replaces the current main screen layout, per architecture.md "Sentence lists" (diagram + interaction rules). Voice picker stays behind the settings icon.
- Chip row: pinned lists in their order, plus the current list as a temporary chip if it isn't pinned, plus **▾**. ▾ toggles a large grid of all lists covering the sentence area; picking one closes it and shows that list.
- Sentence rows: big (font ≥ 24, min height 72 dp, full-width tap target, text wraps, never truncated). Tap = `Speaker.speak(text)`. Visual feedback on the tapped row while it is synthesizing/playing. `said` rows greyed out but tappable (the `said` logic itself is T19).
- Every speak (row or free text) calls `addToHistory`.
- Bottom bar: the free-text field with ✕, and Mondd (from T14), always visible.
- Opens on the last used list (fallback: the `everyday` list).
- An edit icon in the app bar opens the editing screen (T18); until then, it can be a placeholder.
- Empty list: a short hint text ("Ez a lista üres. Szerkesztés: ✎").
- All strings via ARB (hu + en).
- **Checks:** `flutter analyze`, `flutter test` (widget test with an in-memory DB and a fake `Speaker`: tapping a row speaks its text and adds it to history; chips switch lists; ▾ grid shows all lists and picking one shows it).

### [ ] T17 (You): Try the speaking screen
1. Uninstall the app (fresh DB), `flutter run --profile`.
2. Use the Alap list for a few minutes as if you couldn't speak: are rows big enough, is anything missing or unnatural in the default phrases? Note changes to make in `assets/seed/hu.json`.
3. Tap the same row twice quickly: second tap replays at once. Type text, Mondd twice: second is instant.
4. Switch between Alap / Előzmények / Példa beszélgetés: one tap, nothing jumps under your finger.
5. Close and reopen: same list is open.
Done → commit.

### [ ] T18 (Agent): Editing screen
- Opened from the speaking screen's edit icon, for the current list. Lists overview: create, rename, delete (confirm dialog), pin/unpin, reorder; "Alapértelmezett listák visszaállítása" if any seed list is missing.
- Per-list editor: one row per sentence (keeps sentence ids, so recordings and `said` survive edits). Tap a row = edit its text (dialog with a large multi-line field). Drag handle to reorder, delete icon (with undo snackbar). A large "Új mondat(ok)" field at the bottom: what's typed or pasted is split into sentences and appended.
- **Splitting** (`lib/lists/split_sentences.dart`, pure function): split after `.`, `!`, `?`, `…` (and runs like `?!`, `...`) **only when followed by whitespace and an uppercase letter or a newline / end of text**, and on every newline. Keep the punctuation, trim, drop empties. This keeps Hungarian ordinals and dates together ("a 3. emeleten", "2026. 11. 02.") and abbreviations followed by lowercase ("pl. holnap").
- "Alapértelmezett mondatok visszaállítása" on seeded lists, only shown when `hasMissingDefaults` is true.
- History list: not reorderable; each row has "Mentés listába" (copy to a chosen list) and delete. No add field.
- Any list: per-row "Áthelyezés…" / "Másolás…" to another list.
- Conversation lists: "Újrakezdés" button (`resetSaid`).
- All strings via ARB (hu + en).
- **Checks:** `flutter analyze`, `flutter test` (unit-test the splitter thoroughly with Hungarian cases: ordinals, dates, `pl.`, `?!`, `...`, `…`, multiple newlines, no final punctuation; widget test: paste a paragraph → N sentences appear in the list).

### [ ] T19 (Agent): Prepared conversations
- In a `conversation` list, speaking a row (tap or Következő) sets its `said = true`.
- **"Következő ▶"** button below the rows (conversation lists only, fixed position, large): speaks the first unsaid sentence in order. When all are said, it's disabled and shows "Minden elhangzott" with an "Újrakezdés" action next to it (confirm first; this is the one place the speaking screen changes data besides `said`).
- The next unsaid sentence gets a subtle highlight (border/marker, no size change, no auto-scroll jumping; if it's off-screen, scroll it into view only after a Következő tap, never during the user's own scrolling).
- `said` survives app restarts (it's in the DB).
- **Checks:** `flutter analyze`, `flutter test` (Következő order, skipping sentences already said by direct tap, all-said state, reset).

### [ ] T20 (You): A real prepared conversation
1. The evening before talking to someone (a family member is fine), create a conversation list in the editor: paste 5–10 sentences as one paragraph and check they split correctly. Pin it.
2. Next day, open the app: the list is already open. Hold the conversation using only Következő, list taps and the occasional typed sentence; jump to Alap and back at least once.
3. Note what felt slow, confusing or missing (and what the other person noticed). These notes feed Phase 4 and the ALS group / logopédus questions.
Done → commit.

---

## Later (rough)
- Carry unsaid sentences of a conversation over to a new one.
- Offer new default lists/sentences added in later app versions to existing users (seed version).
- Message banking (record your own audio for a sentence).
- Bell; emergency SMS with GPS (platform channel).
- Speech speed setting (lengthScale) in settings.
- About screen with licenses (GPL-3.0 app; per-voice licenses from the catalog; Apache-2.0 sherpa-onnx).
