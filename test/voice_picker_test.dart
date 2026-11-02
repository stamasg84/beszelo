import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/l10n/app_localizations.dart';
import 'package:mondom/ui/voice_picker.dart';
import 'package:mondom/voices/catalog.dart';
import 'package:mondom/voices/voice.dart';
import 'package:mondom/voices/voice_installer.dart';

class FakePreviewer implements VoicePreviewer {
  final spoken = <String>[];
  bool sampleOk = false;

  @override
  Future<bool> playSample(String url) async => sampleOk;
  @override
  Future<void> speakSystem(String text, String language) async =>
      spoken.add(text);
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

CatalogVoice cv(String id, String lang, VoiceGender g) => CatalogVoice(
  id: id,
  language: lang,
  gender: g,
  label: id,
  url: 'https://example.com/$id.tar.bz2',
  sizeBytes: 63000000,
  sha256: 'ab' * 32,
  modelFile: '$id.onnx',
  sampleUrl: 'https://example.com/$id.wav',
  license: 'MIT',
  minAppVersion: '1.0.0',
);

class _InstantInstaller extends VoiceInstaller {
  _InstantInstaller(Directory root) : super(root: root);
  final done = <String>{};
  @override
  Future<bool> isInstalled(String id) async => done.contains(id);
  @override
  Future<void> install(
    CatalogVoice voice, {
    void Function(int received, int total)? onProgress,
    InstallCancelToken? cancel,
    void Function(InstallStage stage)? onStage,
  }) async {
    done.add(voice.id);
  }
}

void main() {
  final catalog = Catalog(
    voices: [
      cv('imre', 'hu', VoiceGender.male),
      cv('berta', 'hu', VoiceGender.female),
      cv('amy', 'en', VoiceGender.female),
    ],
    sampleText: const {'hu': 'Szia, ez egy minta.'},
  );

  Future<(FakePreviewer, List<Voice>)> pump(
    WidgetTester tester, {
    bool firstRun = true,
    bool instantInstall = false,
  }) async {
    final previewer = FakePreviewer();
    final selected = <Voice>[];
    final dir = Directory.systemTemp.createTempSync('picker');
    addTearDown(() => dir.deleteSync(recursive: true));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('home')),
      ),
    );
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => VoicePickerScreen(
          catalog: catalog,
          installer: instantInstall
              ? _InstantInstaller(dir)
              : VoiceInstaller(root: dir),
          selectedId: '',
          firstRun: firstRun,
          previewer: previewer,
          onSelect: (v) async => selected.add(v),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (previewer, selected);
  }

  testWidgets('renders system voice, UI-language voices, other languages', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Android alapértelmezett'), findsOneWidget);
    expect(find.text('imre'), findsOneWidget);
    expect(find.text('berta'), findsOneWidget);
    expect(find.text('férfi · 63 MB'), findsOneWidget);
    expect(find.text('Más nyelvek'), findsOneWidget);
    expect(find.text('Letöltés'), findsNWidgets(2));
  });

  testWidgets('first run: selecting the system voice closes the picker', (
    tester,
  ) async {
    final (_, selected) = await pump(tester);
    expect(find.byKey(const Key('skip')), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('voice-system')),
        matching: find.text('Kiválasztás'),
      ),
    );
    await tester.pumpAndSettle();
    expect(selected.single.kind, VoiceKind.system);
    expect(find.byType(VoicePickerScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('first run: a finished download selects the voice and closes', (
    tester,
  ) async {
    final (_, selected) = await pump(tester, instantInstall: true);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('voice-imre')),
        matching: find.text('Letöltés'),
      ),
    );
    await tester.pumpAndSettle();
    expect(selected.single.id, 'imre');
    expect(find.byType(VoicePickerScreen), findsNothing);
  });

  testWidgets('not first run: selecting keeps the picker open', (tester) async {
    final (_, selected) = await pump(tester, firstRun: false);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('voice-system')),
        matching: find.text('Kiválasztás'),
      ),
    );
    await tester.pumpAndSettle();
    expect(selected.single.kind, VoiceKind.system);
    expect(find.byType(VoicePickerScreen), findsOneWidget);
  });

  testWidgets('system preview speaks the sample text; failed sample shows '
      'message', (tester) async {
    final (previewer, _) = await pump(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('voice-system')),
        matching: find.byIcon(Icons.play_circle_outline),
      ),
    );
    await tester.pump();
    expect(previewer.spoken, ['Szia, ez egy minta.']);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('voice-imre')),
        matching: find.byIcon(Icons.play_circle_outline),
      ),
    );
    await tester.pump();
    expect(find.text('A minta nem érhető el'), findsOneWidget);
  });
}
