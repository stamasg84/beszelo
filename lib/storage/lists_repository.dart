import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../speech/speaker.dart' show normalizeText;
import 'database.dart';
import 'seed.dart';

export 'database.dart' show ListKind, Sentence, SentenceList;

/// Maximum number of rows in the history list.
const historyCap = 30;

const _lastListKey = 'lastListId';
const _declinedSeedKey = 'declinedSeedLanguages';

/// The only storage API the UI uses.
class ListsRepository {
  ListsRepository(this._db);
  final AppDatabase _db;

  $SentenceListsTable get _lists => _db.sentenceLists;
  $SentencesTable get _sentences => _db.sentences;

  // ---- Lists ----

  Stream<List<SentenceList>> watchLists() => (_db.select(
    _lists,
  )..orderBy([(t) => OrderingTerm.asc(t.position)])).watch();

  Future<int> createList(
    String title, {
    ListKind kind = ListKind.everyday,
    bool pinned = false,
  }) async {
    final last = await _lastListPosition();
    return _db
        .into(_lists)
        .insert(
          SentenceListsCompanion.insert(
            title: title.trim(),
            kind: kind,
            pinned: Value(pinned),
            position: last + 1,
          ),
        );
  }

  Future<void> renameList(int id, String title) async {
    await _requireNotHistory(id, 'renamed');
    final t = title.trim();
    if (t.isEmpty) return;
    await (_db.update(_lists)..where((l) => l.id.equals(id))).write(
      SentenceListsCompanion(title: Value(t)),
    );
  }

  /// Deletes the list and (cascade) its sentences. Not allowed for history.
  Future<void> deleteList(int id) async {
    await _requireNotHistory(id, 'deleted');
    await (_db.delete(_lists)..where((l) => l.id.equals(id))).go();
  }

  Future<void> setPinned(int id, bool pinned) =>
      (_db.update(_lists)..where((l) => l.id.equals(id))).write(
        SentenceListsCompanion(pinned: Value(pinned)),
      );

  /// Lists named in [ids] get that order; any others follow in their old order.
  Future<void> reorderLists(List<int> ids) => _db.transaction(() async {
    final all = await (_db.select(
      _lists,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    final order = _merge(ids, [for (final l in all) l.id]);
    for (final (i, id) in order.indexed) {
      await (_db.update(_lists)..where((l) => l.id.equals(id))).write(
        SentenceListsCompanion(position: Value(i)),
      );
    }
  });

  // ---- Sentences ----

  /// Ordered by position (history: newest first).
  Stream<List<Sentence>> watchSentences(int listId) =>
      (_db.select(_sentences)
            ..where((s) => s.listId.equals(listId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .watch();

  /// Inserts [texts] (trimmed, empty ones skipped) at index [at] (default:
  /// end). Returns the new ids.
  Future<List<int>> addSentences(int listId, List<String> texts, {int? at}) =>
      _db.transaction(() async {
        final old = await _sentenceIds(listId);
        final ids = <int>[];
        for (final t in texts) {
          if (t.trim().isEmpty) continue;
          ids.add(await _insertSentence(listId, t.trim()));
        }
        if (at != null && ids.isNotEmpty) {
          final i = at.clamp(0, old.length);
          await _writeOrder(listId, [...old.take(i), ...ids, ...old.skip(i)]);
        }
        return ids;
      });

  Future<void> updateSentenceText(int id, String text) {
    final t = text.trim();
    if (t.isEmpty) return Future.value();
    return (_db.update(
      _sentences,
    )..where((s) => s.id.equals(id))).write(SentencesCompanion(body: Value(t)));
  }

  Future<void> deleteSentence(int id) => _db.transaction(() async {
    final s = await _sentenceById(id);
    if (s == null) return;
    await (_db.delete(_sentences)..where((x) => x.id.equals(id))).go();
    await _writeOrder(s.listId, await _sentenceIds(s.listId));
  });

  /// Moves to the end of [toListId]. The seed identity is dropped.
  Future<void> moveSentence(int id, int toListId) => _db.transaction(() async {
    final s = await _sentenceById(id);
    if (s == null || s.listId == toListId) return;
    final end = await _lastSentencePosition(toListId);
    await (_db.update(_sentences)..where((x) => x.id.equals(id))).write(
      SentencesCompanion(
        listId: Value(toListId),
        position: Value(end + 1),
        seedKey: const Value(null),
        spokenAt: const Value(null),
      ),
    );
    await _writeOrder(s.listId, await _sentenceIds(s.listId));
  });

  /// Copies to the end of [toListId] (keeps the recording, resets `said`).
  Future<int?> copySentence(int id, int toListId) async {
    final s = await _sentenceById(id);
    if (s == null) return null;
    return _insertSentence(toListId, s.body, recordingPath: s.recordingPath);
  }

  /// [ids] get that order; any others in the list follow in their old order.
  Future<void> reorderSentences(int listId, List<int> ids) => _db.transaction(
    () async => _writeOrder(listId, _merge(ids, await _sentenceIds(listId))),
  );

  Future<void> setSaid(int id, bool said) =>
      (_db.update(_sentences)..where((s) => s.id.equals(id))).write(
        SentencesCompanion(said: Value(said)),
      );

  Future<void> resetSaid(int listId) =>
      (_db.update(_sentences)..where((s) => s.listId.equals(listId))).write(
        const SentencesCompanion(said: Value(false)),
      );

  // ---- History ----

  /// Records a spoken text at the top of history; the same normalized text is
  /// moved instead of duplicated. Oldest rows beyond [historyCap] are dropped.
  /// Newest-first order is kept by giving the new row the lowest position.
  Future<void> addToHistory(String text) => _db.transaction(() async {
    final normalized = normalizeText(text);
    if (normalized.isEmpty) return;
    final history = await _historyList();
    final rows =
        await (_db.select(_sentences)
              ..where((s) => s.listId.equals(history.id))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final now = DateTime.now();
    final top = rows.isEmpty ? 0 : rows.first.position - 1;
    final same = rows
        .where((r) => normalizeText(r.body) == normalized)
        .toList();
    if (same.isNotEmpty) {
      await (_db.update(
        _sentences,
      )..where((s) => s.id.equals(same.first.id))).write(
        SentencesCompanion(position: Value(top), spokenAt: Value(now)),
      );
    } else {
      await _db
          .into(_sentences)
          .insert(
            SentencesCompanion.insert(
              listId: history.id,
              body: normalized,
              position: top,
              spokenAt: Value(now),
            ),
          );
    }
    final ids = await _sentenceIds(history.id);
    for (final id in ids.skip(historyCap)) {
      await (_db.delete(_sentences)..where((s) => s.id.equals(id))).go();
    }
  });

  // ---- Defaults ----

  /// Whether some seed sentences of the list are missing from it.
  Future<bool> hasMissingDefaults(int listId) async =>
      (await _missingSeedSentences(listId)).isNotEmpty;

  /// Re-adds missing seed sentences at their seed position, from the list's
  /// own seed language. Never deletes or changes anything. Returns how many
  /// were added.
  Future<int> restoreDefaultSentences(int listId) => _db.transaction(() async {
    final missing = await _missingSeedSentences(listId);
    for (final (index, s) in missing) {
      final ids = await _sentenceIds(listId);
      final newId = await _insertSentence(listId, s.text, seedKey: s.seedKey);
      ids.insert(index.clamp(0, ids.length), newId);
      await _writeOrder(listId, ids);
    }
    return missing.length;
  });

  /// Re-creates the seed lists of [language] (the current speech language)
  /// that are missing. Lists of other languages are left alone. Returns how
  /// many were added.
  Future<int> restoreDefaultLists(String language) =>
      _db.transaction(() => _addMissingSeedLists(language));

  /// Whether any seed was ever inserted.
  Future<bool> isSeeded() => _db.isSeeded();

  /// Languages of the seed lists currently present.
  Future<Set<String>> seedLanguages() async => {
    for (final l in await _db.select(_lists).get())
      if (l.seedLanguage != null) l.seedLanguage!,
  };

  /// Appends the default lists of [language] (falling back to `en` when there
  /// is no seed file) after the existing ones. Lists already present are not
  /// duplicated.
  Future<void> addSeedLists(String language) => _db.transaction(() async {
    await _addMissingSeedLists(language);
    await syncHistoryTitle(language);
    await _db.markSeeded();
  });

  /// Gives the history list the title of [language]'s seed, so it matches the
  /// seeded lists (the speech language, not the UI language). No-op without a
  /// seed file for [language] or if the title is already right.
  Future<void> syncHistoryTitle(String language) async {
    if (!await _db.hasSeed(language)) return;
    final title = (await _db.resolveSeed(language)).$2.historyTitle;
    if (title == null) return;
    final history = await _historyList();
    if (history.title == title) return;
    await (_db.update(_lists)..where((l) => l.id.equals(history.id))).write(
      SentenceListsCompanion(title: Value(title)),
    );
  }

  /// Called when a voice of [language] becomes the speech language. Seeds on
  /// first use; later, asks (via [ask]) once whether to add that language's
  /// default lists. Returns whether lists were added.
  Future<bool> offerSeedLists(
    String language, {
    required Future<bool> Function() ask,
  }) async {
    await syncHistoryTitle(language);
    if (!await isSeeded()) {
      await addSeedLists(language);
      return true;
    }
    if ((await seedLanguages()).contains(language)) return false;
    if (!await _db.hasSeed(language)) return false;
    final prefs = await SharedPreferences.getInstance();
    final declined = prefs.getStringList(_declinedSeedKey) ?? const [];
    if (declined.contains(language)) return false;
    if (await ask()) {
      await addSeedLists(language);
      return true;
    }
    await prefs.setStringList(_declinedSeedKey, [...declined, language]);
    return false;
  }

  // ---- Last used list ----

  Future<int?> lastUsedListId() async =>
      (await SharedPreferences.getInstance()).getInt(_lastListKey);

  Future<void> setLastUsedListId(int id) async =>
      (await SharedPreferences.getInstance()).setInt(_lastListKey, id);

  // ---- Helpers ----

  Future<SentenceList> _historyList() => (_db.select(
    _lists,
  )..where((l) => l.kind.equalsValue(ListKind.history))).getSingle();

  Future<void> _requireNotHistory(int id, String action) async {
    final l = await (_db.select(
      _lists,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    if (l?.kind == ListKind.history) {
      throw StateError('The history list cannot be $action');
    }
  }

  Future<Sentence?> _sentenceById(int id) =>
      (_db.select(_sentences)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<int> _lastListPosition() async {
    final max = _lists.position.max();
    final row = await (_db.selectOnly(_lists)..addColumns([max])).getSingle();
    return row.read(max) ?? -1;
  }

  Future<int> _lastSentencePosition(int listId) async {
    final max = _sentences.position.max();
    final row =
        await (_db.selectOnly(_sentences)
              ..addColumns([max])
              ..where(_sentences.listId.equals(listId)))
            .getSingle();
    return row.read(max) ?? -1;
  }

  Future<int> _insertSentence(
    int listId,
    String text, {
    String? recordingPath,
    String? seedKey,
  }) async => _db
      .into(_sentences)
      .insert(
        SentencesCompanion.insert(
          listId: listId,
          body: text,
          position: await _lastSentencePosition(listId) + 1,
          recordingPath: Value(recordingPath),
          seedKey: Value(seedKey),
        ),
      );

  /// Sentence ids of a list in position order.
  Future<List<int>> _sentenceIds(int listId) async => [
    for (final s
        in await (_db.select(_sentences)
              ..where((x) => x.listId.equals(listId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get())
      s.id,
  ];

  Future<void> _writeOrder(int listId, List<int> ids) async {
    for (final (i, id) in ids.indexed) {
      await (_db.update(_sentences)..where((s) => s.id.equals(id))).write(
        SentencesCompanion(position: Value(i)),
      );
    }
  }

  /// [first] (only ids that exist in [all]), then the rest of [all] in order.
  List<int> _merge(List<int> first, List<int> all) {
    final known = all.toSet();
    final head = [
      for (final id in first.toSet())
        if (known.contains(id)) id,
    ];
    return [...head, ...all.where((id) => !head.contains(id))];
  }

  /// Inserts the seed lists of [language] that are missing, after the existing
  /// ones; the history list stays last if it was last. Returns how many.
  Future<int> _addMissingSeedLists(String language) async {
    final (used, seed) = await _db.resolveSeed(language);
    final all = await (_db.select(
      _lists,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    final history = all.where((l) => l.kind == ListKind.history).firstOrNull;
    final historyLast = history != null && all.last.id == history.id;
    final existing = {
      for (final l in all)
        if (l.seedLanguage == used && l.seedKey != null) l.seedKey,
    };
    var added = 0;
    for (final l in seed.lists) {
      if (existing.contains(l.seedKey)) continue;
      await _db.insertSeedList(
        l,
        await _lastListPosition() + 1,
        language: used,
      );
      added++;
    }
    if (added > 0 && historyLast) {
      await (_db.update(_lists)..where((x) => x.id.equals(history.id))).write(
        SentenceListsCompanion(position: Value(await _lastListPosition() + 1)),
      );
    }
    return added;
  }

  /// Seed sentences (with their seed index) missing from the list, from the
  /// list's own seed language. Empty for lists without a seed (user lists,
  /// history).
  Future<List<(int, SeedSentence)>> _missingSeedSentences(int listId) async {
    final list = await (_db.select(
      _lists,
    )..where((l) => l.id.equals(listId))).getSingleOrNull();
    if (list?.seedKey == null || list?.seedLanguage == null) return const [];
    final (_, seed) = await _db.resolveSeed(list!.seedLanguage!);
    final seedList = seed.lists
        .where((l) => l.seedKey == list.seedKey)
        .firstOrNull;
    if (seedList == null) return const [];
    final have = {
      for (final s in await (_db.select(
        _sentences,
      )..where((x) => x.listId.equals(listId))).get())
        if (s.seedKey != null) s.seedKey,
    };
    return [
      for (final (i, s) in seedList.sentences.indexed)
        if (!have.contains(s.seedKey)) (i, s),
    ];
  }
}
