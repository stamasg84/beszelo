import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/main.dart';
import 'package:mondom/speech/speaker.dart';
import 'package:mondom/storage/database.dart';
import 'package:mondom/storage/lists_repository.dart';
import 'package:mondom/storage/seed.dart';
import 'package:mondom/ui/speaking_screen.dart';
import 'package:mondom/voices/voice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSpeaker extends Speaker {
  _FakeSpeaker()
    : super(
        engineFactory: (Voice _) async => throw UnimplementedError(),
        player: _NoPlayer(),
      );
  @override
  bool get ready => true;
  @override
  bool get loading => false;
  @override
  Future<void> speak(String text) async {}
}

class _NoPlayer implements WavPlayer {
  @override
  Future<void> play(String path) async {}
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

Future<Seed> _fileSeed(String lang) async => Seed.fromJson(
  jsonDecode(File('assets/seed/$lang.json').readAsStringSync())
      as Map<String, dynamic>,
);

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    // A duration lets route transitions finish, so covered screens go offstage.
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  late AppDatabase db;
  late ListsRepository repo;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory(), loadSeed: _fileSeed);
    repo = ListsRepository(db);
  });

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.runAsync(() => repo.addSeedLists('hu'));
    tester.platformDispatcher.localesTestValue = const [Locale('hu', 'HU')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MondomApp(
        home: SpeakingScreen(
          speaker: _FakeSpeaker(),
          repo: repo,
          voice: () => Voice.system('hu'),
          onOpenVoicePicker: () async {},
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> openLists(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Beállítások'));
    await settle(tester);
    await tester.tap(find.text('Listák'));
    await settle(tester);
  }

  Future<List<SentenceList>> lists(WidgetTester tester) async =>
      (await tester.runAsync(() => repo.watchLists().first))!;

  Future<void> openEditor(WidgetTester tester, String list) async {
    await openLists(tester);
    await tester.tap(find.text(list));
    await settle(tester);
  }

  Future<List<Sentence>> rows(WidgetTester tester, int listId) async =>
      (await tester.runAsync(() => repo.watchSentences(listId).first))!;

  Future<int> idOf(WidgetTester tester, String title) async =>
      (await lists(tester)).firstWhere((l) => l.title == title).id;

  Future<void> addLines(WidgetTester tester, String text) async {
    await tester.enterText(find.widgetWithText(TextField, 'Új sor(ok)'), text);
    await tester.tap(find.widgetWithText(FilledButton, 'Hozzáadás'));
    await settle(tester);
  }

  testWidgets('lines with blank lines between become rows in order', (
    tester,
  ) async {
    await pumpScreen(tester);
    final id = (await tester.runAsync(() => repo.createList('Orvos')))!;
    await openEditor(tester, 'Orvos');
    await addLines(tester, 'Első\n\nMásodik\n  \nHarmadik');
    expect(
      [for (final s in await rows(tester, id)) s.body],
      ['Első', 'Második', 'Harmadik'],
    );
    await finish(tester);
  });

  testWidgets('one line with several sentences stays one row', (tester) async {
    await pumpScreen(tester);
    final id = (await tester.runAsync(() => repo.createList('Orvos')))!;
    await openEditor(tester, 'Orvos');
    await addLines(tester, 'Vegyetek sütit! Tegnap csináltuk.');
    final r = await rows(tester, id);
    expect(r.length, 1);
    expect(r.single.body, 'Vegyetek sütit! Tegnap csináltuk.');
    await finish(tester);
  });

  testWidgets('editing a row keeps its id', (tester) async {
    await pumpScreen(tester);
    final id = (await tester.runAsync(() => repo.createList('Orvos')))!;
    final sid = (await tester.runAsync(() => repo.addSentences(id, ['Régi'])))!
        .single;
    await openEditor(tester, 'Orvos');
    await tester.tap(find.text('Régi'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Új szöveg');
    await tester.tap(find.widgetWithText(FilledButton, 'Mentés'));
    await settle(tester);
    final r = await rows(tester, id);
    expect(r.single.id, sid);
    expect(r.single.body, 'Új szöveg');
    await finish(tester);
  });

  testWidgets('delete has undo', (tester) async {
    await pumpScreen(tester);
    final id = (await tester.runAsync(() => repo.createList('Orvos')))!;
    await tester.runAsync(() => repo.addSentences(id, ['A', 'B', 'C']));
    await openEditor(tester, 'Orvos');
    await tester.tap(find.byTooltip('További műveletek').at(1));
    await settle(tester);
    await tester.tap(find.text('Törlés'));
    await settle(tester);
    expect([for (final s in await rows(tester, id)) s.body], ['A', 'C']);
    await tester.tap(find.text('Visszavonás'));
    await settle(tester);
    expect([for (final s in await rows(tester, id)) s.body], ['A', 'B', 'C']);
    await finish(tester);
  });

  testWidgets('move to another list', (tester) async {
    await pumpScreen(tester);
    final id = (await tester.runAsync(() => repo.createList('Orvos')))!;
    await tester.runAsync(() => repo.addSentences(id, ['A']));
    await openEditor(tester, 'Orvos');
    await tester.tap(find.byTooltip('További műveletek'));
    await settle(tester);
    await tester.tap(find.text('Áthelyezés listába…'));
    await settle(tester);
    expect(find.text('Előzmények'), findsNothing);
    await tester.tap(find.text('Alap'));
    await settle(tester);
    expect(await rows(tester, id), isEmpty);
    final alap = await idOf(tester, 'Alap');
    expect((await rows(tester, alap)).last.body, 'A');
    await finish(tester);
  });

  testWidgets('history: no add field, copy and delete only via sheet', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.runAsync(() => repo.addToHistory('Szia'));
    await openEditor(tester, 'Előzmények');
    expect(find.text('Új sor(ok)'), findsNothing);
    expect(find.byTooltip('Mozgatás'), findsNothing);
    await tester.tap(find.byTooltip('További műveletek'));
    await settle(tester);
    expect(find.text('Másolás listába…'), findsOneWidget);
    expect(find.text('Áthelyezés listába…'), findsOneWidget);
    await tester.tap(find.text('Törlés'));
    await settle(tester);
    final history = (await lists(tester))
        .firstWhere((l) => l.kind == ListKind.history);
    expect(await rows(tester, history.id), isEmpty);
    await finish(tester);
  });
}
