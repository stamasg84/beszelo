import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mondom/voices/catalog.dart';
import 'package:mondom/voices/voice_installer.dart';

Map<String, dynamic> entry(String id, {String minApp = '1.0.0'}) => {
      'id': id,
      'language': 'hu',
      'gender': 'male',
      'label': id,
      'url': 'https://example.com/$id.tar.bz2',
      'sizeBytes': 10,
      'sha256': 'ab' * 32,
      'modelFile': '$id.onnx',
      'sampleUrl': 'https://example.com/$id.wav',
      'license': 'MIT',
      'minAppVersion': minApp,
    };

String catalogJson({int schema = 1, List<Map<String, dynamic>>? voices}) =>
    jsonEncode({
      'schemaVersion': schema,
      'voices': voices ?? [entry('a')],
      'sampleText': {'hu': 'Szia!'},
    });

/// Builds a tiny `.tar.bz2` shaped like a sherpa-onnx voice archive.
List<int> fakeVoiceArchive(String id) {
  final tar = Archive()
    ..addFile(ArchiveFile.bytes('$id/$id.onnx', [1, 2, 3]))
    ..addFile(ArchiveFile.bytes('$id/tokens.txt', utf8.encode('a 1')))
    ..addFile(ArchiveFile.bytes('$id/espeak-ng-data/phondata', [4, 5]));
  return BZip2Encoder().encode(TarEncoder().encode(tar));
}

CatalogVoice voiceFor(String id, List<int> bytes, {String? sha}) =>
    CatalogVoice.fromJson({
      ...entry(id),
      'sizeBytes': bytes.length,
      'sha256': sha ?? sha256.convert(bytes).toString(),
    });

String lastSegment(FileSystemEntity e) =>
    e.uri.pathSegments.where((s) => s.isNotEmpty).last;

void main() {
  group('catalog parsing', () {
    test('parses voices and sample text', () {
      final c = Catalog.parse(catalogJson(), appVersion: '1.0.0')!;
      expect(c.voices.single.id, 'a');
      expect(c.sampleText['hu'], 'Szia!');
      expect(c.forLanguage('en'), isEmpty);
    });

    test('ignores unknown schemaVersion and garbage', () {
      expect(Catalog.parse(catalogJson(schema: 2), appVersion: '1.0.0'), isNull);
      expect(Catalog.parse('not json', appVersion: '1.0.0'), isNull);
    });

    test('drops entries needing a newer app and malformed entries', () {
      final c = Catalog.parse(
        catalogJson(voices: [
          entry('old'),
          entry('new', minApp: '1.10.0'),
          {'id': 'broken'},
        ]),
        appVersion: '1.2.0',
      )!;
      expect(c.voices.map((v) => v.id), ['old']);
    });

    test('compareVersions', () {
      expect(compareVersions('1.10.0', '1.2.0'), greaterThan(0));
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1.0.0', '1.0.0+5'), 0);
    });

    test('bundled catalog asset is valid and in sync', () {
      final text = File('assets/catalog.json').readAsStringSync();
      final c = Catalog.parse(text, appVersion: '1.0.0')!;
      expect(c.voices, isNotEmpty);
      expect(text, File('voices/catalog.json').readAsStringSync());
    });
  });

  group('catalog repository', () {
    test('uses the remote catalog when available', () async {
      final repo = CatalogRepository(
        appVersion: '1.0.0',
        client: MockClient((_) async => http.Response(catalogJson(), 200)),
        loadBundled: () async => catalogJson(voices: [entry('bundled')]),
      );
      expect((await repo.load()).voices.single.id, 'a');
    });

    test('falls back silently to the bundled copy', () async {
      for (final client in [
        MockClient((_) async => throw const SocketException('offline')),
        MockClient((_) async => http.Response('nope', 404)),
        MockClient((_) async => http.Response(catalogJson(schema: 9), 200)),
      ]) {
        final repo = CatalogRepository(
          appVersion: '1.0.0',
          client: client,
          loadBundled: () async => catalogJson(voices: [entry('bundled')]),
        );
        expect((await repo.load()).voices.single.id, 'bundled');
      }
    });
  });

  group('voice installer', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('mondom_test'));
    tearDown(() => root.deleteSync(recursive: true));

    VoiceInstaller installerServing(List<int> bytes) => VoiceInstaller(
          root: Directory('${root.path}/voices'),
          client: MockClient.streaming((req, _) async => http.StreamedResponse(
                Stream.fromIterable([bytes.sublist(0, 5), bytes.sublist(5)]),
                200,
              )),
        );

    test('installs, shares espeak data, deletes', () async {
      final bytes = fakeVoiceArchive('v1');
      final installer = installerServing(bytes);
      var last = 0;
      await installer.install(voiceFor('v1', bytes),
          onProgress: (r, t) => last = r);
      expect(last, bytes.length);
      expect(await installer.isInstalled('v1'), isTrue);
      expect(File('${await installer.voiceDir('v1')}/tokens.txt').existsSync(),
          isTrue);
      expect(File('${await installer.espeakDataDir()}/phondata').existsSync(),
          isTrue);
      // No staging leftovers.
      expect(Directory('${root.path}/voices').listSync().map(lastSegment).toSet(),
          {'v1', 'espeak-ng-data'});

      // A second voice reuses the shared espeak data.
      final bytes2 = fakeVoiceArchive('v2');
      await installerServing(bytes2).install(voiceFor('v2', bytes2));
      expect(await installer.isInstalled('v2'), isTrue);
      expect(
          Directory('${await installer.voiceDir('v2')}/espeak-ng-data')
              .existsSync(),
          isFalse);

      await installer.delete('v1');
      expect(await installer.isInstalled('v1'), isFalse);
      expect(Directory(await installer.espeakDataDir()).existsSync(), isTrue);
    });

    test('sha256 mismatch leaves nothing behind', () async {
      final bytes = fakeVoiceArchive('v1');
      final installer = installerServing(bytes);
      await expectLater(
        installer.install(voiceFor('v1', bytes, sha: '00' * 32)),
        throwsA(isA<Sha256MismatchException>()),
      );
      expect(await installer.isInstalled('v1'), isFalse);
      expect(Directory('${root.path}/voices').listSync(), isEmpty);
    });

    test('cancel leaves nothing behind', () async {
      final bytes = fakeVoiceArchive('v1');
      final installer = installerServing(bytes);
      final token = InstallCancelToken();
      await expectLater(
        installer.install(voiceFor('v1', bytes),
            cancel: token, onProgress: (a, b) => token.cancel()),
        throwsA(isA<InstallCancelledException>()),
      );
      expect(Directory('${root.path}/voices').listSync(), isEmpty);
    });

    test('network failure leaves nothing behind', () async {
      final installer = VoiceInstaller(
        root: Directory('${root.path}/voices'),
        client: MockClient.streaming((req, _) async => http.StreamedResponse(
              Stream<List<int>>.error(const SocketException('wifi off')),
              200,
            )),
      );
      await expectLater(
        installer.install(voiceFor('v1', [1, 2, 3])),
        throwsA(isA<SocketException>()),
      );
      expect(Directory('${root.path}/voices').listSync(), isEmpty);
    });
  });
}
