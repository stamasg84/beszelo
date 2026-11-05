import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'seed.dart';

part 'database.g.dart';

enum ListKind { everyday, conversation, history }

/// Language used when there is no seed for the requested language.
const fallbackSeedLanguage = 'en';

/// Palette keys for list colors, in the order new lists pick them. The tones
/// live in `ui/list_colors.dart`; the DB only stores the key.
const listColorKeys = [
  'blue',
  'green',
  'orange',
  'purple',
  'teal',
  'pink',
  'yellow',
  'brown',
  'red', // last; reserved for the alarm list, never picked automatically
];

/// Palette keys [nextListColor] may pick for new lists (red is for alarms).
final _autoColorKeys = [
  for (final k in listColorKeys)
    if (k != 'red') k,
];

/// Colors of the shipped seed lists (by `seedKey`); other lists get the next
/// unused palette color.
const seedListColors = {'everyday': 'blue', 'example-conversation': 'orange'};

/// First palette key not in [used]; when all are used, round robin over how
/// often each is used (least used first, palette order breaks ties).
String nextListColor(Iterable<String?> used) {
  final counts = {for (final k in _autoColorKeys) k: 0};
  for (final u in used) {
    if (counts.containsKey(u)) counts[u!] = counts[u]! + 1;
  }
  final min = counts.values.reduce((a, b) => a < b ? a : b);
  return _autoColorKeys.firstWhere((k) => counts[k] == min);
}

/// `seedKey` of the single history list.
const historySeedKey = 'history';

// Schema v1 kept the one seed language here; v2 moves it onto the lists.
const _legacySeedLanguageMetaKey = 'seedLanguage';
const _seededMetaKey = 'seeded';

class SentenceLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get kind => textEnum<ListKind>()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();
  TextColumn get seedKey => text().nullable()();

  /// Seed file the list came from (`hu`, `en`, ...); null for user lists and
  /// history. The same seed list can exist once per language.
  TextColumn get seedLanguage => text().nullable()();

  /// Palette key (see [listColorKeys]); null = neutral (always for history).
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {seedLanguage, seedKey},
  ];
}

class Sentences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId =>
      integer().references(SentenceLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  IntColumn get position => integer()();
  BoolColumn get said => boolean().withDefault(const Constant(false))();
  TextColumn get recordingPath => text().nullable()();

  /// Key into `builtInSounds` (schema v4): played instead of TTS. An unknown
  /// key falls back to TTS.
  TextColumn get soundKey => text().nullable()();

  /// Played loud on the alarm stream and kept out of history (schema v4).
  BoolColumn get alarm => boolean().withDefault(const Constant(false))();
  TextColumn get seedKey => text().nullable()();
  DateTimeColumn get spokenAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {listId, seedKey},
  ];
}

/// Key/value store for things that belong to the DB itself.
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [SentenceLists, Sentences, AppMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor, {this.loadSeed = loadSeedAsset});

  /// Production database in the app's documents directory.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'mondom'));

  final SeedLoader loadSeed;

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Seed lists are added when the first voice is chosen (see
      // ListsRepository.addSeedLists).
      await into(sentenceLists).insert(
        SentenceListsCompanion.insert(
          title: '', // set from the seed's historyTitle; UI-language fallback while empty
          kind: ListKind.history,
          pinned: const Value(true),
          position: 0,
          seedKey: const Value(historySeedKey),
        ),
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v1 had a column-level UNIQUE on seedKey, so the table is rebuilt.
        await m.alterTable(
          TableMigration(
            sentenceLists,
            // The rebuild creates the table as it is now, so `color` (v3) is
            // already part of it.
            newColumns: [sentenceLists.seedLanguage, sentenceLists.color],
            columnTransformer: {
              sentenceLists.seedLanguage: const CustomExpression<String>(
                'CASE WHEN seed_key IS NOT NULL '
                "AND seed_key <> '$historySeedKey' "
                '''THEN (SELECT value FROM app_meta WHERE key = '$_legacySeedLanguageMetaKey') END''',
              ),
            },
          ),
        );
        await (delete(
          appMeta,
        )..where((t) => t.key.equals(_legacySeedLanguageMetaKey))).go();
        await markSeeded();
      }
      if (from < 3) {
        if (from >= 2) await m.addColumn(sentenceLists, sentenceLists.color);
        final rows = await (select(
          sentenceLists,
        )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
        final used = <String?>[];
        final pending = <SentenceList>[];
        for (final l in rows) {
          if (l.kind == ListKind.history) continue;
          final seeded = seedListColors[l.seedKey];
          if (seeded != null) {
            used.add(seeded);
            await (update(sentenceLists)..where((t) => t.id.equals(l.id)))
                .write(SentenceListsCompanion(color: Value(seeded)));
          } else {
            pending.add(l);
          }
        }
        for (final l in pending) {
          final key = nextListColor(used);
          used.add(key);
          await (update(sentenceLists)..where((t) => t.id.equals(l.id))).write(
            SentenceListsCompanion(color: Value(key)),
          );
        }
      }
      if (from < 4) {
        // The v1 -> v2 rebuild only touches sentence_lists, so sentences
        // never had these columns.
        await m.addColumn(sentences, sentences.soundKey);
        await m.addColumn(sentences, sentences.alarm);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Seed for [lang], or for [fallbackSeedLanguage] if there is none.
  /// Returns the language actually used.
  Future<(String, Seed)> resolveSeed(String lang) async {
    try {
      return (lang, await loadSeed(lang));
    } catch (_) {
      return (fallbackSeedLanguage, await loadSeed(fallbackSeedLanguage));
    }
  }

  /// Whether a seed file exists for [lang] (no fallback).
  Future<bool> hasSeed(String lang) async {
    try {
      await loadSeed(lang);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether a seed was ever inserted (so deleting every seed list later does
  /// not trigger seeding again).
  Future<bool> isSeeded() async =>
      await (select(
        appMeta,
      )..where((t) => t.key.equals(_seededMetaKey))).getSingleOrNull() !=
      null;

  Future<void> markSeeded() => into(appMeta).insertOnConflictUpdate(
    AppMetaCompanion.insert(key: _seededMetaKey, value: '1'),
  );

  Future<int> insertSeedList(
    SeedList list,
    int position, {
    required String language,
  }) async {
    final id = await into(sentenceLists).insert(
      SentenceListsCompanion.insert(
        title: list.title,
        kind: list.kind,
        pinned: Value(list.pinned),
        position: position,
        color: Value(list.color),
        seedKey: Value(list.seedKey),
        seedLanguage: Value(language),
      ),
    );
    for (final (i, s) in list.sentences.indexed) {
      await into(sentences).insert(
        SentencesCompanion.insert(
          listId: id,
          body: s.text,
          position: i,
          seedKey: Value(s.seedKey),
          soundKey: Value(s.sound),
          alarm: Value(s.alarm),
        ),
      );
    }
    return id;
  }
}
