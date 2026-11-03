import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'seed.dart';

part 'database.g.dart';

enum ListKind { everyday, conversation, history }

/// Language used when there is no seed for the requested language.
const fallbackSeedLanguage = 'en';

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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Seed lists are added when the first voice is chosen (see
      // ListsRepository.addSeedLists).
      await into(sentenceLists).insert(
        SentenceListsCompanion.insert(
          title: 'History',
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
            newColumns: [sentenceLists.seedLanguage],
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
        ),
      );
    }
    return id;
  }
}
