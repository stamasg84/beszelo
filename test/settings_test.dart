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
  var pickerOpened = 0;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory(), loadSeed: _fileSeed);
    repo = ListsRepository(db);
    pickerOpened = 0;
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
          onOpenVoicePicker: () async => pickerOpened++,
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

  testWidgets('cog → settings → Hang és nyelv opens the picker', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byTooltip('Szerkesztés'), findsNothing);
    await tester.tap(find.byTooltip('Beállítások'));
    await settle(tester);
    expect(find.text('Android alapértelmezett · Magyar'), findsOneWidget);
    await tester.tap(find.text('Hang és nyelv'));
    await settle(tester);
    expect(pickerOpened, 1);
    await finish(tester);
  });

  testWidgets('lists overview shows all lists, marks the open one', (
    tester,
  ) async {
    await pumpScreen(tester);
    await openLists(tester);
    expect(find.text('Alap'), findsOneWidget);
    expect(find.text('Példa beszélgetés'), findsOneWidget);
    expect(find.text('Előzmények'), findsOneWidget);
    expect(find.text('Most megnyitva'), findsOneWidget);
    expect(find.text('Kitűzve'), findsNWidgets(2)); // Alap + Előzmények
    await finish(tester);
  });

  testWidgets('new conversation list is created pinned', (tester) async {
    await pumpScreen(tester);
    await openLists(tester);
    await tester.tap(find.text('Új lista'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Kati');
    await tester.tap(find.text('Beszélgetés').last);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Létrehozás'));
    await settle(tester);
    final created = (await lists(tester)).firstWhere((l) => l.title == 'Kati');
    expect(created.kind, ListKind.conversation);
    expect(created.pinned, isTrue);
    await finish(tester);
  });

  testWidgets('delete asks first; cancel keeps the list', (tester) async {
    await pumpScreen(tester);
    await openLists(tester);
    Future<void> askDelete() async {
      await tester.tap(find.byTooltip('További műveletek').first);
      await settle(tester);
      await tester.tap(find.text('Törlés'));
      await settle(tester);
    }

    await askDelete();
    expect(find.textContaining('Törlöd a(z) „Alap” listát'), findsOneWidget);
    await tester.tap(find.text('Mégse'));
    await settle(tester);
    expect((await lists(tester)).any((l) => l.title == 'Alap'), isTrue);

    await askDelete();
    await tester.tap(find.widgetWithText(FilledButton, 'Törlés'));
    await settle(tester);
    expect((await lists(tester)).any((l) => l.title == 'Alap'), isFalse);
    await finish(tester);
  });

  testWidgets('history has no rename or delete', (tester) async {
    await pumpScreen(tester);
    await openLists(tester);
    await tester.tap(find.byTooltip('További műveletek').last);
    await settle(tester);
    expect(find.text('Átnevezés'), findsNothing);
    expect(find.text('Törlés'), findsNothing);
    expect(find.text('Kitűzés megszüntetése'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('restore row appears only when a seed list is missing', (
    tester,
  ) async {
    await pumpScreen(tester);
    await openLists(tester);
    const restore = 'Alapértelmezett listák visszaállítása';
    expect(find.text(restore), findsNothing);

    final example = (await lists(
      tester,
    )).firstWhere((l) => l.seedKey == 'example-conversation');
    await tester.runAsync(() => repo.deleteList(example.id));
    await settle(tester);
    expect(find.text(restore), findsOneWidget);

    await tester.tap(find.text(restore));
    await settle(tester);
    expect(find.text(restore), findsNothing);
    expect(find.text('Példa beszélgetés'), findsOneWidget);
    await finish(tester);
  });
}
