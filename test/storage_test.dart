import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/storage/database.dart';
import 'package:mondom/storage/lists_repository.dart';
import 'package:mondom/storage/seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Seed> _fileSeed(String lang) async {
  final f = File('assets/seed/$lang.json');
  if (!f.existsSync()) throw Exception('no seed $lang');
  return Seed.fromJson(
    jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
  );
}

AppDatabase _open() =>
    AppDatabase(NativeDatabase.memory(), loadSeed: _fileSeed);

void main() {
  late AppDatabase db;
  late ListsRepository repo;

  Future<SentenceList> listByKey(String key) => (db.select(
    db.sentenceLists,
  )..where((l) => l.seedKey.equals(key))).getSingle();
  Future<List<Sentence>> sentencesOf(int id) async =>
      (await repo.watchSentences(id).first);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = _open();
    repo = ListsRepository(db);
    await repo.addSeedLists('hu');
  });
  tearDown(() => db.close());

  test('seeds hu, with history list', () async {
    final lists = await repo.watchLists().first;
    expect(lists.map((l) => l.seedKey), [
      'everyday',
      'example-conversation',
      'history',
    ]);
    expect(lists.first.title, 'Alap');
    expect(lists.first.pinned, isTrue);
    expect(lists[1].kind, ListKind.conversation);
    expect(lists[1].pinned, isFalse);
    expect(lists.last.kind, ListKind.history);
    final s = await sentencesOf(lists.first.id);
    expect(s.first.body, 'Kérek vizet!');
    expect(s.map((x) => x.body), contains('Várj, gépelek.'));
  });

  test(
    'history title follows the speech language, not the UI language',
    () async {
      expect((await repo.watchLists().first).last.title, 'Előzmények');
      await repo.syncHistoryTitle('sv');
      expect((await repo.watchLists().first).last.title, 'Historik');
      await repo.syncHistoryTitle('fi'); // no seed: unchanged
      expect((await repo.watchLists().first).last.title, 'Historik');
    },
  );

  test('fresh DB has only history and is not seeded', () async {
    await db.close();
    db = _open();
    repo = ListsRepository(db);
    expect((await repo.watchLists().first).map((l) => l.kind), [
      ListKind.history,
    ]);
    expect(await repo.isSeeded(), isFalse);
    expect(await repo.seedLanguages(), isEmpty);
  });

  test('addSeedLists: hu then en, no key clash, history stays last', () async {
    expect(await repo.isSeeded(), isTrue);
    await repo.addSeedLists('en');
    final lists = await repo.watchLists().first;
    expect(lists.map((l) => (l.seedLanguage, l.seedKey)), [
      ('hu', 'everyday'),
      ('hu', 'example-conversation'),
      ('en', 'everyday'),
      ('en', 'example-conversation'),
      (null, 'history'),
    ]);
    expect(lists.where((l) => l.title == 'Basics'), hasLength(1));
    expect(await repo.seedLanguages(), {'hu', 'en'});
    // Idempotent.
    await repo.addSeedLists('en');
    expect(await repo.watchLists().first, hasLength(5));
  });

  test('unknown language falls back to en', () async {
    await repo.addSeedLists('de');
    expect(await repo.seedLanguages(), {'hu', 'en'});
    final lists = await repo.watchLists().first;
    expect(lists.where((l) => l.seedLanguage == 'en').first.title, 'Basics');
  });

  test('every catalog language has a seed file', () {
    final catalog = jsonDecode(
      File('assets/catalog.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final languages = {
      for (final v in catalog['voices'] as List) v['language'] as String,
    };
    expect(languages, isNotEmpty);
    for (final l in languages) {
      expect(File('assets/seed/$l.json').existsSync(), isTrue, reason: l);
    }
  });

  group('offerSeedLists', () {
    late int asked;
    Future<bool> Function() answer(bool yes) => () async {
      asked++;
      return yes;
    };
    setUp(() => asked = 0);

    test('not seeded: seeds without asking', () async {
      await db.close();
      db = _open();
      repo = ListsRepository(db);
      expect(await repo.offerSeedLists('sv', ask: answer(false)), isTrue);
      expect(asked, 0);
      expect(await repo.seedLanguages(), {'sv'});
    });

    test('seeded + new language: asks; yes adds the lists', () async {
      expect(await repo.offerSeedLists('sv', ask: answer(true)), isTrue);
      expect(asked, 1);
      expect(await repo.seedLanguages(), {'hu', 'sv'});
    });

    test('declined: not asked again', () async {
      expect(await repo.offerSeedLists('sv', ask: answer(false)), isFalse);
      expect(await repo.offerSeedLists('sv', ask: answer(true)), isFalse);
      expect(asked, 1);
      expect(await repo.seedLanguages(), {'hu'});
    });

    test('same language: nothing', () async {
      expect(await repo.offerSeedLists('hu', ask: answer(true)), isFalse);
      expect(asked, 0);
    });

    test('same-language voice switch after deleting seed lists: '
        'not asked', () async {
      for (final key in ['everyday', 'example-conversation']) {
        await repo.deleteList((await listByKey(key)).id);
      }
      expect(await repo.seedLanguages(), isEmpty);
      expect(
        await repo.offerSeedLists(
          'hu',
          ask: answer(true),
          languageChanged: false,
        ),
        isFalse,
      );
      expect(asked, 0);
    });

    test('language without a seed file: nothing', () async {
      expect(await repo.offerSeedLists('de', ask: answer(true)), isFalse);
      expect(asked, 0);
    });
  });

  test('history dedupes by normalized text and moves to top', () async {
    final h = await listByKey('history');
    await repo.addToHistory('Szia!');
    await repo.addToHistory('Nem.');
    await repo.addToHistory('  Szia!  ');
    final s = await sentencesOf(h.id);
    expect(s.map((x) => x.body), ['Szia!', 'Nem.']);
  });

  test('history is capped, oldest dropped', () async {
    final h = await listByKey('history');
    for (var i = 0; i < historyCap + 5; i++) {
      await repo.addToHistory('mondat $i');
    }
    final s = await sentencesOf(h.id);
    expect(s, hasLength(historyCap));
    expect(s.first.body, 'mondat ${historyCap + 4}');
    expect(s.last.body, 'mondat 5');
  });

  test('history cap does not touch other lists', () async {
    final e = await listByKey('everyday');
    final before = (await sentencesOf(e.id)).length;
    await repo.addToHistory('Kérek vizet!');
    for (var i = 0; i < historyCap + 2; i++) {
      await repo.addToHistory('x $i');
    }
    expect(await sentencesOf(e.id), hasLength(before));
  });

  test('restore re-adds deleted seed sentence at its seed position', () async {
    final e = await listByKey('everyday');
    var s = await sentencesOf(e.id);
    final water = s.firstWhere((x) => x.seedKey == 'water');
    expect(await repo.hasMissingDefaults(e.id), isFalse);
    await repo.deleteSentence(water.id);
    expect(await repo.hasMissingDefaults(e.id), isTrue);
    expect(await repo.restoreDefaultSentences(e.id), 1);
    s = await sentencesOf(e.id);
    expect(s.first.seedKey, 'water');
    expect(await repo.hasMissingDefaults(e.id), isFalse);
  });

  test('restore does not duplicate an edited seed sentence', () async {
    final e = await listByKey('everyday');
    final s = await sentencesOf(e.id);
    await repo.updateSentenceText(s.first.id, 'Vizet kérek!');
    final n = s.length;
    expect(await repo.restoreDefaultSentences(e.id), 0);
    final after = await sentencesOf(e.id);
    expect(after, hasLength(n));
    expect(after.first.body, 'Vizet kérek!');
  });

  test('restore leaves user-added sentences alone', () async {
    final e = await listByKey('everyday');
    await repo.addSentences(e.id, ['Saját mondat.']);
    final water = (await sentencesOf(e.id))
        .firstWhere((x) => x.seedKey == 'water');
    await repo.deleteSentence(water.id);
    await repo.restoreDefaultSentences(e.id);
    final s = await sentencesOf(e.id);
    expect(s.map((x) => x.body), contains('Saját mondat.'));
    expect(s.last.body, 'Saját mondat.');
    expect(s.first.seedKey, 'water');
  });

  test('restore lists re-creates a deleted seed list', () async {
    final c = await listByKey('example-conversation');
    await repo.deleteList(c.id);
    expect(await db.select(db.sentenceLists).get(), hasLength(2));
    expect(await repo.restoreDefaultLists('hu'), 1);
    final again = await listByKey('example-conversation');
    expect(await sentencesOf(again.id), hasLength(3));
    expect(await repo.restoreDefaultLists('hu'), 0);
    expect((await repo.watchLists().first).last.kind, ListKind.history);
  });

  test('restore lists only touches the given language', () async {
    await repo.addSeedLists('en');
    for (final l in await repo.watchLists().first) {
      if (l.kind != ListKind.history) await repo.deleteList(l.id);
    }
    expect(await repo.restoreDefaultLists('en'), 2);
    expect(await repo.seedLanguages(), {'en'});
  });

  test('restore sentences uses the own language of the list', () async {
    await repo.addSeedLists('en');
    final en = (await repo.watchLists().first).firstWhere(
      (l) => l.seedLanguage == 'en' && l.seedKey == 'everyday',
    );
    final s = await sentencesOf(en.id);
    await repo.deleteSentence(s.first.id);
    expect(await repo.restoreDefaultSentences(en.id), 1);
    final after = await sentencesOf(en.id);
    expect(after.first.seedKey, s.first.seedKey);
    expect(after.first.body, s.first.body);
    expect(after.every((x) => !x.body.contains('Kérek')), isTrue);
  });

  test('user lists and history have nothing to restore', () async {
    final id = await repo.createList('Orvos');
    expect(await repo.hasMissingDefaults(id), isFalse);
    expect(await repo.restoreDefaultSentences(id), 0);
  });

  test('deleting a list cascades its sentences', () async {
    final c = await listByKey('example-conversation');
    await repo.deleteList(c.id);
    final left = await (db.select(
      db.sentences,
    )..where((s) => s.listId.equals(c.id))).get();
    expect(left, isEmpty);
  });

  test('history cannot be deleted or renamed', () async {
    final h = await listByKey('history');
    expect(repo.deleteList(h.id), throwsStateError);
    expect(repo.renameList(h.id, 'x'), throwsStateError);
  });

  test('add at index, move, copy, reorder, said', () async {
    final id = await repo.createList('Orvos');
    final ids = await repo.addSentences(id, ['A.', 'B.', 'C.']);
    await repo.addSentences(id, ['X.', ' ', 'Y.'], at: 1);
    expect((await sentencesOf(id)).map((s) => s.body), [
      'A.',
      'X.',
      'Y.',
      'B.',
      'C.',
    ]);
    await repo.reorderSentences(id, [ids[2], ids[0]]);
    expect((await sentencesOf(id)).map((s) => s.body).take(2), ['C.', 'A.']);
    final other = await repo.createList('Éjszaka');
    await repo.copySentence(ids[0], other);
    await repo.moveSentence(ids[1], other);
    expect((await sentencesOf(other)).map((s) => s.body), ['A.', 'B.']);
    expect(await sentencesOf(id), hasLength(4));
    await repo.setSaid(ids[0], true);
    expect((await sentencesOf(id)).where((s) => s.said), hasLength(1));
    await repo.resetSaid(id);
    expect((await sentencesOf(id)).where((s) => s.said), isEmpty);
  });
}
