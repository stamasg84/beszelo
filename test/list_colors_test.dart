import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/storage/database.dart';
import 'package:mondom/storage/lists_repository.dart';
import 'package:mondom/storage/seed.dart';
import 'package:mondom/ui/list_colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Future<Seed> _fileSeed(String lang) async => Seed.fromJson(
  jsonDecode(File('assets/seed/$lang.json').readAsStringSync())
      as Map<String, dynamic>,
);

const _tables = '''
  CREATE TABLE sentences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    list_id INTEGER NOT NULL REFERENCES sentence_lists (id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    position INTEGER NOT NULL,
    said INTEGER NOT NULL DEFAULT 0,
    recording_path TEXT NULL,
    seed_key TEXT NULL,
    spoken_at INTEGER NULL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
    UNIQUE (list_id, seed_key)
  );
  CREATE TABLE app_meta (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL);
''';

/// Schema v2: seedLanguage exists, color does not.
void _createV2(dynamic raw) {
  raw.execute('''
    CREATE TABLE sentence_lists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      kind TEXT NOT NULL,
      pinned INTEGER NOT NULL DEFAULT 0,
      position INTEGER NOT NULL,
      seed_key TEXT NULL,
      seed_language TEXT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
      UNIQUE (seed_language, seed_key)
    );
    $_tables
    INSERT INTO app_meta VALUES ('seeded', '1');
    INSERT INTO sentence_lists (title, kind, pinned, position, seed_key, seed_language) VALUES
      ('Alap', 'everyday', 1, 0, 'everyday', 'hu'),
      ('Orvos', 'everyday', 0, 1, NULL, NULL),
      ('Példa', 'conversation', 0, 2, 'example-conversation', 'hu'),
      ('Éjszaka', 'everyday', 0, 3, NULL, NULL),
      ('Előzmények', 'history', 1, 4, 'history', NULL);
    INSERT INTO sentences (list_id, body, position) VALUES (2, 'Fáj a fejem.', 0);
    PRAGMA user_version = 2;
  ''');
}

/// Schema v1: one seed language in app_meta, UNIQUE on seedKey.
void _createV1(dynamic raw) {
  raw.execute('''
    CREATE TABLE sentence_lists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      kind TEXT NOT NULL,
      pinned INTEGER NOT NULL DEFAULT 0,
      position INTEGER NOT NULL,
      seed_key TEXT NULL UNIQUE,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
    );
    $_tables
    INSERT INTO app_meta VALUES ('seedLanguage', 'hu');
    INSERT INTO sentence_lists (title, kind, pinned, position, seed_key) VALUES
      ('Alap', 'everyday', 1, 0, 'everyday'),
      ('Orvos', 'everyday', 0, 1, NULL),
      ('History', 'history', 1, 2, 'history');
    PRAGMA user_version = 1;
  ''');
}

void main() {
  test('every palette entry keeps AA contrast for normal and said text', () {
    const lightText = Color(0xFF1D1B20), darkText = Color(0xFFE6E0E9);
    for (final key in listColorKeys) {
      for (final (brightness, text) in [
        (Brightness.light, lightText),
        (Brightness.dark, darkText),
      ]) {
        final tones = listColorFor(key, brightness);
        expect(tones, isNotNull, reason: '$key has no $brightness tones');
        for (final bg in [tones!.row, tones.rowActive, tones.chip]) {
          expect(_contrast(text, bg), greaterThanOrEqualTo(4.5), reason: key);
          final said = Color.alphaBlend(
            text.withValues(alpha: saidTextAlpha),
            bg,
          );
          expect(
            _contrast(said, bg),
            greaterThanOrEqualTo(3.0), // large (24 px) text: AA needs 3:1
            reason: '$key said text ($brightness)',
          );
        }
      }
    }
  });

  test('unknown key has no tones (neutral fallback)', () {
    expect(listColorFor('chartreuse', Brightness.light), isNull);
  });

  test('migration v2 -> v3: seed colors, then unused palette colors', () async {
    final db = AppDatabase(
      NativeDatabase.memory(setup: _createV2),
      loadSeed: (_) async => const Seed([]),
    );
    addTearDown(db.close);
    final repo = ListsRepository(db);
    final lists = await repo.watchLists().first;
    expect(lists.map((l) => (l.title, l.color)), [
      ('Alap', 'blue'),
      ('Orvos', 'green'), // blue and orange are taken by the seed lists
      ('Példa', 'orange'),
      ('Éjszaka', 'purple'),
      ('Előzmények', null),
    ]);
    expect((await repo.watchSentences(lists[1].id).first).length, 1);
  });

  test('migration v1 -> v3 also ends with colors', () async {
    final db = AppDatabase(
      NativeDatabase.memory(setup: _createV1),
      loadSeed: (_) async => const Seed([]),
    );
    addTearDown(db.close);
    final lists = await ListsRepository(db).watchLists().first;
    expect(lists.map((l) => l.color), ['blue', 'green', null]);
  });

  test('seeding sets seed colors; restoreDefaultLists keeps them', () async {
    final db = AppDatabase(NativeDatabase.memory(), loadSeed: _fileSeed);
    addTearDown(db.close);
    final repo = ListsRepository(db);
    await repo.addSeedLists('hu');
    var lists = await repo.watchLists().first;
    String? colorOf(String seedKey) =>
        lists.firstWhere((l) => l.seedKey == seedKey).color;
    expect(colorOf('everyday'), 'blue');
    expect(colorOf('example-conversation'), 'orange');
    expect(colorOf('history'), isNull);

    await repo.deleteList(lists.firstWhere((l) => l.seedKey == 'everyday').id);
    await repo.restoreDefaultLists('hu');
    lists = await repo.watchLists().first;
    expect(colorOf('everyday'), 'blue');
  });

  test('createList: first unused color, then least used', () async {
    final db = AppDatabase(NativeDatabase.memory(), loadSeed: _fileSeed);
    addTearDown(db.close);
    final repo = ListsRepository(db);
    await repo.addSeedLists('hu'); // blue, orange used
    final colors = <String?>[];
    for (var i = 0; i < 8; i++) {
      final id = await repo.createList('L$i');
      colors.add(
        (await repo.watchLists().first).firstWhere((l) => l.id == id).color,
      );
    }
    expect(colors.take(6), [
      'green',
      'purple',
      'teal',
      'pink',
      'yellow',
      'brown',
    ]);
    expect(colors[6], 'blue'); // all used once: back to the palette start
    expect(colors[7], 'green');
  });

  test('setColor stores a key or null; history is refused', () async {
    final db = AppDatabase(NativeDatabase.memory(), loadSeed: _fileSeed);
    addTearDown(db.close);
    final repo = ListsRepository(db);
    final id = await repo.createList('Orvos');
    Future<String?> color() async =>
        (await repo.watchLists().first).firstWhere((l) => l.id == id).color;
    await repo.setColor(id, 'pink');
    expect(await color(), 'pink');
    await repo.setColor(id, null);
    expect(await color(), isNull);
    final history = (await repo.watchLists().first).firstWhere(
      (l) => l.kind == ListKind.history,
    );
    expect(() => repo.setColor(history.id, 'blue'), throwsStateError);
  });
}
