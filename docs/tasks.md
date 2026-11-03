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
- Main screen: remove "Ismétlés". Keep the text in the field after speaking; add a large ✕ (clear) button inside the field. Mondom with an unchanged text = replay.
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

### [x] T16 (Agent): Speaking screen
- Replaces the current main screen layout, per architecture.md "Sentence lists" (diagram + interaction rules). Voice picker stays behind the settings icon.
- Chip row: pinned lists in their order, plus the current list as a temporary chip if it isn't pinned, plus **▾**. ▾ toggles a large grid of all lists covering the sentence area; picking one closes it and shows that list.
- Sentence rows: big (font ≥ 24, min height 72 dp, full-width tap target, text wraps, never truncated). Tap = `Speaker.speak(text)`. Visual feedback on the tapped row while it is synthesizing/playing. `said` rows greyed out but tappable (the `said` logic itself is T19).
- Every speak (row or free text) calls `addToHistory`.
- Bottom bar: the free-text field with ✕, and Mondom (from T14), always visible.
- Opens on the last used list (fallback: the `everyday` list).
- An edit icon in the app bar opens the editing screen (T18); until then, it can be a placeholder.
- Empty list: a short hint text ("Ez a lista üres. Szerkesztés: ✎").
- All strings via ARB (hu + en).
- **Checks:** `flutter analyze`, `flutter test` (widget test with an in-memory DB and a fake `Speaker`: tapping a row speaks its text and adds it to history; chips switch lists; ▾ grid shows all lists and picking one shows it).

### [x] T16a (Agent): First-run voice picker closes on selection
Problem: on first launch the picker (`firstRun: true`) hides the back arrow, so after choosing a voice the only way out is "Kihagyás", which also overrides the choice with the system voice (`_skip` in `lib/ui/voice_picker.dart` calls `_select(_systemVoice)`).
- First run: choosing a voice closes the picker and returns to the speaking screen. That covers both "Kiválaszt" on an installed/system voice and a finished download (`_download` already calls `_select` on success). Pop only after `onSelect` completes, and only if still `mounted`.
- Remove the "Kihagyás" button, `_skip`, and the `skip` ARB key (hu + en). The "Android alapértelmezett" row's own select button already does what Kihagyás was for.
- Leaving with the system back gesture without choosing stays allowed: the system voice is used, nothing is saved, and the picker shows again on the next launch (current `savedId == null` logic in `main.dart`, unchanged).
- During a download on first run, nothing closes; cancelling the download leaves the picker open.
- Opened from settings (`firstRun: false`): unchanged (stays open after selecting, back arrow to leave), since there the user may also download or delete voices.
- **Checks:** `flutter analyze`, `flutter test`. Replace the `skip selects the system voice` test in `test/voice_picker_test.dart` with: first run, select system voice → `onSelect` called once and the picker route is popped; first run, a download finishing → selected and popped; not first run, select → not popped.

### [x] T16b (Agent): Speaking from the history list doesn't reorder it
Problem: tapping a row in Előzmények calls `addToHistory`, which moves that row to the top, so the list jumps under the user's finger (and a second tap on the same spot hits a different sentence).
- Rule: **speaking a row while the history list is shown doesn't change history** (no move, no insert). In `_speak` in `lib/ui/speaking_screen.dart`, skip `addToHistory` when the call is a row tap and the current list is the history list. Free text and rows in every other list still call `addToHistory` as before (same text → moves to the top), since the user isn't looking at history then.
- Free text typed while the history list is shown still goes in at the top (that's a new utterance; a shift there is expected).
- Accepted trade-off: a phrase repeated only from history can eventually fall off at the 30 cap. That's fine; frequently used phrases belong in a real list ("Mentés listába", T18).
- Add the rule as one sentence to the "History:" paragraph in architecture.md.
- **Checks:** `flutter analyze`, `flutter test` (widget test: with history showing A, B, C (A newest), tapping C speaks C and the order stays A, B, C; tapping a row in Alap that matches C moves C to the top; free text while history is shown is added at the top).

### [x] T17 (You): Try the speaking screen
1. Uninstall the app (fresh DB), `flutter run --profile`.
2. Use the Alap list for a few minutes as if you couldn't speak: are rows big enough, is anything missing or unnatural in the default phrases? Note changes to make in `assets/seed/hu.json`.
3. Tap the same row twice quickly: second tap replays at once. Type text, Mondom twice: second is instant.
4. Switch between Alap / Előzmények / Példa beszélgetés: one tap, nothing jumps under your finger.
5. Close and reopen: same list is open.
Done → commit.

### [x] T17a (Agent): Seed in the speech language, seed language per list
Problem: `onCreate` seeds from the UI language before any voice is picked, so a user who picks a voice in another language ("Más nyelvek") gets default sentences the voice can't pronounce, and restore keeps bringing them back. Read architecture.md "Storage", especially "Speech language", first.
- **Schema v2:** `sentence_lists.seedLanguage` nullable text; the list's `seedKey` uniqueness becomes `(seedLanguage, seedKey)`. Migration v1→v2: `addColumn`, set `seedLanguage` = the old `app_meta.seedLanguage` value on every list with a `seedKey` except history, replace the meta row with `seeded = 1`. Rebuilding the table is needed if the old unique constraint on `seedKey` is a column constraint (drift's `TableMigration`). Regenerate `*.g.dart`.
- **Deferred seeding:** `AppDatabase` no longer takes a `language`; `onCreate` creates only the history list. New repository methods: `isSeeded()`, `seedLanguages()` (distinct non-null `seedLanguage` of lists), `addSeedLists(String language)` (appends that seed's lists after the existing ones, with `seedLanguage` set, falling back to `en` via `resolveSeed`; sets `seeded = 1`). Seeding becomes a normal operation instead of being done in `onCreate`.
- **main.dart:** in `_selectVoice`, if not seeded → `addSeedLists(v.language)`. If seeded and `v.language` isn't in `seedLanguages()`, a seed file exists for it, and it isn't in `declinedSeedLanguages` (`shared_preferences`) → dialog "Hozzáadjam a(z) <nyelv> alapértelmezett listákat?" with "Hozzáadás" / "Nem". Language name in the UI language (a small `languageName(code, uiLang)` helper with a map for the catalog languages is fine; unknown code → the code itself).
- **Voice picker:** rows under "Más nyelvek" show the voice's language in the subtitle (e.g. "Svéd · Férfi · 67 MB"), using the same helper; otherwise a Swedish voice there is indistinguishable from a Hungarian one. When the first-run picker route is popped without a choice and the DB still isn't seeded → `addSeedLists(uiLang)`.
- The speaking screen's "last used list, fallback `everyday`" must work when lists appear after the screen is built (fallback: the first `everyday` list by position, re-evaluated when the lists stream changes while no valid list is open).
- **Restore:** `restoreDefaultSentences(listId)` uses the list's own `seedLanguage`. `restoreDefaultLists(language)` takes the current speech language and only re-creates that language's missing seed lists; the editor (T18) passes `Voice.language`.
- Unit test: every language in `assets/catalog.json` has `assets/seed/<lang>.json`.
- **Checks:** `flutter analyze`, `flutter test` (fresh DB has only history; `addSeedLists('hu')` then `('en')` gives both sets with no key clash; unknown language falls back to `en`; migration v1→v2 keeps all rows and sets `seedLanguage`; restore sentences uses the list's language; restore lists only touches the given language; widget/unit test for the decision in `_selectVoice`: not seeded → seed; seeded + new language → asks; declined → doesn't ask again; same language → nothing). `flutter build apk --debug 2>&1 | tail -40`.

### [x] T17b (You): Seeding by voice language
1. Migration first: **don't uninstall** the build from T17. Note a few edits (a deleted and an added sentence), then `flutter run --profile` the new build over it: lists and sentences are unchanged, and "restore" still works on Alap.
2. Uninstall, set the phone language to English, `flutter run --profile`. In the first-run picker choose Imre (under other languages): the lists are Hungarian (Alap…), the UI is English.
3. Settings → voice → pick the English system voice: you're asked once whether to add the English default lists. Say no, switch to Imre and back to English: not asked again.
4. Uninstall again, Hungarian phone, leave the first-run picker with the back gesture: Hungarian lists exist, and the picker shows again next launch.
Done → commit.

### [x] T17c (Agent): Voice picker: language selector, system voice per language
Do after T17a (uses its `languageName` helper and the speech-language rules). Read architecture.md "Voices" (voice picker) first. Replaces the "Más nyelvek" `ExpansionTile` in `lib/ui/voice_picker.dart`.
- **Language selector** at the top, only if the catalog has more than one language: a full-width button ≥ 56 dp, "Nyelv: Magyar ▾". It opens a bottom sheet (or dialog) of large rows (≥ 56 dp), one per catalog language: "Svéd (Svenska)" (UI-language name + native name; add the native name to the helper), with a marker (✓ + "1 letöltve") on languages that have installed voices, so downloaded voices in other languages can still be found and deleted. UI language first, then the others alphabetically by their UI-language name.
- **Default:** opened from settings → the selected voice's language; first run → the UI language. Changing the selector only filters the list; nothing is saved and no seed question is asked until a voice is picked.
- **List for the chosen language:** the "Android alapértelmezett" row (`Voice.system(lang)`), then that language's catalog voices (rows as today). The `language` subtitle T17a added under "Más nyelvek" isn't needed anymore (the selector shows it); remove it if the rows are now always single-language.
- **System voice availability** (new method on `SystemEngine` or a small `SystemTtsInfo` service, so tests can fake it): returns `installed | missingData | unsupported` for a language. Use `flutter_tts` (`isLanguageAvailable`, and on Android `isLanguageInstalled`, which tells an offline voice from a network-only one; check the current package API). Row states:
  - `installed`: ▶ preview (speaks the catalog's `sampleText` for that language) and Kiválaszt.
  - `missingData`: no Kiválaszt; text "A hang nincs letöltve a telefonon." and a button "Letöltés az Android beállításaiban", which opens the engine's install-voice-data screen (`TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA`) or, if that fails, the TTS settings (`com.android.settings.TTS_SETTINGS`). Needs a tiny platform channel or `android_intent_plus` (ask before adding the package). Re-check when the app resumes (`AppLifecycleState.resumed`), so the row turns selectable after the user installed the voice.
  - `unsupported`: row hidden, except for the UI language, where it stays with "A telefon nem tud ezen a nyelven beszélni." so the picker never looks voiceless.
  - If the check itself throws: treat as `installed` (today's behavior), so a quirky engine never hides the always-available voice.
- An already selected system voice keeps working whatever the check says (it's only a hint for choosing).
- ARB (hu + en) for new strings.
- **Follow-up (2026-11-03):** the history list's title now follows the speech language like the seeded lists do (`historyTitle` in each `assets/seed/<lang>.json`, stored on the history row by `ListsRepository.syncHistoryTitle`, called when a voice is chosen and at app start). Before, it came from the UI-language ARB, so it showed "Előzmények" next to Swedish lists. An empty title falls back to the ARB string. New seed files must include `historyTitle`.
- **Checks:** `flutter analyze`, `flutter test` (widget tests with a fake catalog of hu + sv and a fake availability service: selector hidden with one language; defaults to the UI language on first run and to the selected voice's language from settings; switching to Svéd shows the sv system row + NST + Alma and no Hungarian voices; `missingData` shows the hint and no select button; `unsupported` hides the row for sv but shows the hint for the UI language; the installed marker appears on a language with a downloaded voice; picking `system-sv` calls `onSelect` with language `sv`).

### [x] T17d (You): Voice picker by language
1. Settings → voice: the selector shows "Magyar". Switch to Svéd: system row, NST, Alma. Play the samples.
2. If the Swedish system row says the voice isn't downloaded: tap the button, install Swedish in Google's voice data, come back: the row is selectable now. Select it and type "Hej, hur mår du?": it speaks Swedish. Check it with airplane mode on (a network-only voice would fail here, which means `isLanguageInstalled` isn't telling the truth on this phone; note it).
3. Download NST, switch the selector back to Magyar: Svéd shows the installed marker in the language list.
Done → commit.

### [ ] T18 (Agent): Editing screen
- Opened from the speaking screen's edit icon, for the current list. Lists overview: create, rename, delete (confirm dialog), pin/unpin, reorder; "Alapértelmezett listák visszaállítása" if any seed list of the current speech language is missing (`restoreDefaultLists(voice.language)`, see T17a).
- Per-list editor: one row per sentence (keeps sentence ids, so recordings and `said` survive edits). Tap a row = edit its text (dialog with a large multi-line field). Drag handle to reorder, delete icon (with undo snackbar). A large "Új mondat(ok)" field at the bottom: what's typed or pasted is split into sentences and appended.
- **Splitting** (`lib/lists/split_sentences.dart`, pure function): split after `.`, `!`, `?`, `…` (and runs like `?!`, `...`) **only when followed by whitespace and an uppercase letter or a newline / end of text**, and on every newline. Keep the punctuation, trim, drop empties. This keeps Hungarian ordinals and dates together ("a 3. emeleten", "2026. 11. 02.") and abbreviations followed by lowercase ("pl. holnap").
- "Alapértelmezett mondatok visszaállítása" on seeded lists, only shown when `hasMissingDefaults` is true.
- History list: not reorderable; each row has "Mentés listába" (copy to a chosen list) and delete. No add field.
- Any list: per-row "Áthelyezés…" / "Másolás…" to another list.
- Conversation lists: "Újrakezdés" button (`resetSaid`).
- All strings via ARB (hu + en).
- **Checks:** `flutter analyze`, `flutter test` (unit-test the splitter thoroughly with Hungarian cases: ordinals, dates, `pl.`, `?!`, `...`, `…`, multiple newlines, no final punctuation; widget test: paste a paragraph → N sentences appear in the list).

### [ ] T18a (Agent): List colors
Each list has a color; its chip, its tile in the ▾ grid and all its sentence rows use it, so the user sees which list they're in without reading the chip row. See architecture.md "List colors".
- Schema v3 (v2 is T17a): `sentence_lists.color` nullable text = a **palette key** (e.g. `"blue"`), not an ARGB value. `null` = neutral. Migration: `addColumn`, then give existing lists their seed color (by `seedLanguage` + `seedKey`) or the next palette color. Regenerate `*.g.dart`.
- `lib/ui/list_colors.dart`: a fixed palette of ~8 keys (blue, green, orange, purple, teal, pink, yellow, brown) → `ListColor { chip, row, rowActive }` for light theme (dark theme: return darker tones from the same function, even if the app has no dark mode yet). All tones keep body text at WCAG AA contrast (≥ 4.5:1) with the normal text color, including the greyed-out `said` text (raise its alpha if needed). Unknown key → neutral (forward compatible).
- Seed JSON: optional `"color"` per list (`everyday`: blue, `example-conversation`: orange). History is always neutral grey, no color option. `restoreDefaultLists` uses the seed color.
- `createList` picks the first palette color not used by any list (round robin when all are used).
- Speaking screen: chips filled with their list color, the selected chip additionally gets a thick dark border (color must not be the only cue); grid tiles likewise; rows use `row`, the tapped/speaking row uses `rowActive` + the existing spinner (not `primaryContainer` anymore).
- App bar title on the speaking screen: the **current list's name** instead of the app name (history: its localized title), so the screen says which list is open in words as well as color. Long names: one line, ellipsized (the chip row and the rows themselves stay unchanged). The app name "Mondom" no longer appears on the speaking screen (it was the same word as the speak button).
- Editor (T18): per list a "Szín" row with large swatches (≥ 48 dp, selected one with a check mark) plus "Nincs" (neutral). Repository: `setColor(listId, key?)`.
- ARB (hu + en) for new strings; color names only as semantics labels for TalkBack.
- **Checks:** `flutter analyze`, `flutter test` (migration v2→v3 test with drift's schema tools or a hand-built v2 DB, plus v1→v3; seeding sets colors; `createList` picks unused colors; contrast unit test over every palette entry for both `said` and normal text; widget test: rows of a colored list have its row color; the app bar shows the current list name and changes when switching lists).

### [ ] T19 (Agent): Prepared conversations
- In a `conversation` list, speaking a row (tap or Következő) sets its `said = true`.
- **"Következő ▶"** button below the rows (conversation lists only, fixed position, large): speaks the first unsaid sentence in order. When all are said, it's disabled and shows "Minden elhangzott" with an "Újrakezdés" action next to it (confirm first; this is the one place the speaking screen changes data besides `said`).
- The next unsaid sentence gets a subtle highlight (border/marker, no size change, no auto-scroll jumping; if it's off-screen, scroll it into view only after a Következő tap, never during the user's own scrolling).
- `said` survives app restarts (it's in the DB).
- **Checks:** `flutter analyze`, `flutter test` (Következő order, skipping sentences already said by direct tap, all-said state, reset).

### [ ] T19a (Agent): Load sentences into the free-text field (one-shot builder mode)
Goal: say a variation of a saved sentence ("Kérek egy pohár vizet!" → "Kérek egy pohár teát!") or build a sentence from pieces, without breaking "a tap on a row speaks".
- **Button:** a large (≥ 48 dp) button in the bottom bar, left of the free-text field (e.g. `Icons.playlist_add` or a ↓ icon; TalkBack label "Mondat betöltése a szövegmezőbe"). Pressing it **arms** builder mode; pressing it again cancels.
- **One-shot:** while armed, the next tap on a sentence row (any list, including history) **appends** its text to the free-text field and builder mode **turns off automatically**. To add several pieces, press the button again before each one. Builder mode never stays on: it is cancelled by pressing the button again, the banner's ✕, switching lists (chip or ▾ grid), pressing Mondom, or the app going to the background.
- **Append rule:** empty field → the sentence text; otherwise `field.trimRight() + " " + text`. Cursor at the end. Don't focus the field or open the keyboard automatically (it would cover the list and block adding more pieces); the user taps the field to edit.
- **Loading is not speaking:** it doesn't speak, doesn't call `addToHistory`, doesn't set `said`, doesn't reorder anything.
- **Visual cues while armed (must be unmistakable):** the button shows an active state (filled/highlighted); a banner at the top of the sentence area: "Koppints a mondatra, amit a szövegmezőbe töltenél" with a ✕; sentence rows get a clearly different look (e.g. dashed border plus a small ↓ icon at the end, or a distinct tint) so a row never looks like it will speak when it won't. The banner appearing is a layout change triggered by a dedicated button, which the interaction rules allow; make sure nothing else shifts. In conversation lists, hide or disable Következő while armed.
- Update architecture.md "Interaction rules": "One tap = one fixed meaning" gets the exception: the one-shot load button, which changes the meaning of exactly the next row tap, with a strong visual cue, and then turns itself off. Add one line on why it isn't a toggle (a mode left on by accident would make a tap silent in an urgent moment), and the rejected alternatives: long-press (slow ALS fingers exceed the long-press time, so a tap meant to speak would load instead; also undiscoverable), a per-row icon (second small target next to the big one, mis-taps), swipe (unreliable with shaky hands, conflicts with scrolling), suggestions above the keyboard (too crowded next to the keyboard's own suggestion row).
- All strings via ARB (hu + en).
- **Checks:** `flutter analyze`, `flutter test` (widget tests with the fake `Speaker`: armed + row tap → text in field, nothing spoken, history unchanged, mode off afterwards; second row tap after that speaks normally; appending to existing text adds one space; cancel via button / ✕ / chip switch / Mondom; a conversation row loaded while armed stays unsaid).

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
