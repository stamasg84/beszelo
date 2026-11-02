import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'seed.dart';

part 'database.g.dart';

enum ListKind { everyday, conversation, history }

/// Language used when there is no seed for the UI language.
const fallbackSeedLanguage = 'en';

/// `seedKey` of the single history list.
const historySeedKey = 'history';

const _seedLanguageMetaKey = 'seedLanguage';

class SentenceLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get kind => textEnum<ListKind>()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();
  TextColumn get seedKey => text().nullable().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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
  /// [language]: UI language code used to pick the seed on creation.
  AppDatabase(
    super.executor, {
    required this.language,
    this.loadSeed = loadSeedAsset,
  });

  /// Production database in the app's documents directory.
  factory AppDatabase.open({required String language}) =>
      AppDatabase(driftDatabase(name: 'mondom'), language: language);

  final String language;
  final SeedLoader loadSeed;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      final (seedLanguage, seed) = await resolveSeed(language);
      await into(appMeta).insert(
        AppMetaCompanion.insert(key: _seedLanguageMetaKey, value: seedLanguage),
      );
      for (final (i, list) in seed.lists.indexed) {
        await insertSeedList(list, i);
      }
      await into(sentenceLists).insert(
        SentenceListsCompanion.insert(
          title: 'History',
          kind: ListKind.history,
          pinned: const Value(true),
          position: seed.lists.length,
          seedKey: const Value(historySeedKey),
        ),
      );
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

  /// Language the DB was seeded with (restore uses the same seed).
  Future<String> seedLanguage() async {
    final row = await (select(
      appMeta,
    )..where((t) => t.key.equals(_seedLanguageMetaKey))).getSingleOrNull();
    return row?.value ?? fallbackSeedLanguage;
  }

  Future<int> insertSeedList(SeedList list, int position) async {
    final id = await into(sentenceLists).insert(
      SentenceListsCompanion.insert(
        title: list.title,
        kind: list.kind,
        pinned: Value(list.pinned),
        position: position,
        seedKey: Value(list.seedKey),
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
