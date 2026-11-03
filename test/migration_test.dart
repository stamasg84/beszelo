import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/storage/database.dart';
import 'package:mondom/storage/lists_repository.dart';
import 'package:mondom/storage/seed.dart';

/// A schema v1 database: one seed language in app_meta, UNIQUE on seedKey.
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
    INSERT INTO app_meta VALUES ('seedLanguage', 'hu');
    INSERT INTO sentence_lists (title, kind, pinned, position, seed_key) VALUES
      ('Alap', 'everyday', 1, 0, 'everyday'),
      ('Orvos', 'everyday', 0, 1, NULL),
      ('History', 'history', 1, 2, 'history');
    INSERT INTO sentences (list_id, body, position, seed_key) VALUES
      (1, 'Kérek vizet!', 0, 'water'),
      (1, 'Saját mondat.', 1, NULL),
      (2, 'Fáj a fejem.', 0, NULL),
      (3, 'Szia!', 0, NULL);
    PRAGMA user_version = 1;
  ''');
}

void main() {
  test('migration v1 -> v2 keeps all rows and sets seedLanguage', () async {
    final db = AppDatabase(
      NativeDatabase.memory(setup: _createV1),
      loadSeed: (_) async => const Seed([]),
    );
    addTearDown(db.close);
    final repo = ListsRepository(db);

    final lists = await repo.watchLists().first;
    expect(lists.map((l) => (l.title, l.seedKey, l.seedLanguage)), [
      ('Alap', 'everyday', 'hu'),
      ('Orvos', null, null),
      ('History', 'history', null),
    ]);
    expect(lists.map((l) => l.pinned), [true, false, true]);

    // Cascade must not have wiped the sentences while the table was rebuilt.
    expect((await repo.watchSentences(lists[0].id).first).map((s) => s.body), [
      'Kérek vizet!',
      'Saját mondat.',
    ]);
    expect((await repo.watchSentences(lists[1].id).first).map((s) => s.body), [
      'Fáj a fejem.',
    ]);
    expect((await repo.watchSentences(lists[2].id).first).map((s) => s.body), [
      'Szia!',
    ]);

    // app_meta: seedLanguage replaced by seeded = 1.
    expect(await repo.isSeeded(), isTrue);
    expect(await repo.seedLanguages(), {'hu'});
    final meta = await db.select(db.appMeta).get();
    expect(meta.map((m) => m.key), ['seeded']);
  });
}
