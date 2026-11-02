import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'catalog.dart';

class InstallCancelledException implements Exception {
  @override
  String toString() => 'Install cancelled';
}

class Sha256MismatchException implements Exception {
  Sha256MismatchException(this.expected, this.actual);
  final String expected;
  final String actual;
  @override
  String toString() => 'sha256 mismatch: expected $expected, got $actual';
}

/// Stage of [VoiceInstaller.install], for UI status text.
enum InstallStage { downloading, verifying, extracting }

/// Lets the UI cancel a running [VoiceInstaller.install].
class InstallCancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// Downloads, verifies and installs Piper voices into `<root>/<id>/`, with
/// one shared `<root>/espeak-ng-data/`. A voice directory only appears once
/// it is complete.
class VoiceInstaller {
  VoiceInstaller({Directory? root, http.Client? client})
      : _root = root, // ignore: prefer_initializing_formals
        _client = client ?? http.Client();

  /// Generous: cheap phones are slow, but a hang must end eventually.
  static const extractTimeout = Duration(minutes: 5);

  static const espeakDirName = 'espeak-ng-data';

  Directory? _root;
  final http.Client _client;

  /// `<appSupport>/voices` unless a root was injected (tests).
  Future<Directory> get root async {
    final existing = _root;
    if (existing != null) return existing;
    final support = await getApplicationSupportDirectory();
    return _root = Directory('${support.path}/voices');
  }

  Future<String> voiceDir(String id) async => '${(await root).path}/$id';

  Future<String> espeakDataDir() async =>
      '${(await root).path}/$espeakDirName';

  Future<bool> isInstalled(String id) async {
    final r = (await root).path;
    return Directory('$r/$id').existsSync() &&
        Directory('$r/$espeakDirName').existsSync();
  }

  /// Removes the voice. The shared espeak data stays (other voices use it).
  Future<void> delete(String id) async {
    final dir = Directory(await voiceDir(id));
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// Removes leftovers of interrupted installs (e.g. the app was killed).
  Future<void> cleanupStaging() async {
    final r = await root;
    if (!r.existsSync()) return;
    for (final e in r.listSync()) {
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (name.startsWith('.staging-')) await e.delete(recursive: true);
    }
  }

  /// Installs [voice]. Throws [InstallCancelledException],
  /// [Sha256MismatchException] or an I/O / HTTP error; in every failure case
  /// nothing is left behind.
  Future<void> install(
    CatalogVoice voice, {
    void Function(int received, int total)? onProgress,
    InstallCancelToken? cancel,
    void Function(InstallStage stage)? onStage,
  }) async {
    final r = await root;
    // Unique per attempt, so a stuck earlier attempt can never interfere.
    final staging = Directory(
        '${r.path}/.staging-${voice.id}-${DateTime.now().millisecondsSinceEpoch}');
    await staging.create(recursive: true);
    try {
      final archive = File('${staging.path}/voice.tar.bz2');
      onStage?.call(InstallStage.downloading);
      var sw = Stopwatch()..start();
      await _download(voice, archive, onProgress, cancel);
      debugPrint('Voice ${voice.id}: download ${sw.elapsedMilliseconds} ms');
      _checkCancelled(cancel);

      onStage?.call(InstallStage.verifying);
      final actual = (await sha256.bind(archive.openRead()).first).toString();
      if (actual != voice.sha256) {
        throw Sha256MismatchException(voice.sha256, actual);
      }

      onStage?.call(InstallStage.extracting);
      sw = Stopwatch()..start();
      final extracted = '${staging.path}/extracted';
      final archivePath = archive.path;
      await _extractInIsolate(archivePath, extracted, cancel);
      await archive.delete();
      debugPrint('Voice ${voice.id}: extraction ${sw.elapsedMilliseconds} ms');
      _checkCancelled(cancel);

      // The archive holds a single top-level folder.
      final top =
          Directory(extracted).listSync().whereType<Directory>().single;
      final espeakTarget = Directory('${r.path}/$espeakDirName');
      final espeakSource = Directory('${top.path}/$espeakDirName');
      if (!espeakTarget.existsSync()) {
        await espeakSource.rename(espeakTarget.path);
      } else {
        await espeakSource.delete(recursive: true);
      }
      // Last step: the voice directory appears only when complete.
      await top.rename('${r.path}/${voice.id}');
    } finally {
      if (staging.existsSync()) await staging.delete(recursive: true);
    }
  }

  Future<void> _download(
    CatalogVoice voice,
    File target,
    void Function(int, int)? onProgress,
    InstallCancelToken? cancel,
  ) async {
    final uri = Uri.parse(voice.url);
    final response = await _client.send(http.Request('GET', uri));
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    var received = 0;
    final sink = target.openWrite();
    try {
      await for (final chunk in response.stream) {
        _checkCancelled(cancel);
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, voice.sizeBytes);
      }
    } finally {
      await sink.close();
    }
  }

  /// Runs the extraction in its own isolate that is killed on cancel or
  /// after [extractTimeout], so a stuck extraction can't hang the install
  /// (and the UI) forever.
  Future<void> _extractInIsolate(
      String archivePath, String destDir, InstallCancelToken? cancel) async {
    final done = Completer<void>();
    final results = ReceivePort();
    final errors = ReceivePort();
    results.listen((msg) {
      if (done.isCompleted) return;
      msg == null
          ? done.complete()
          : done.completeError(Exception('Extraction failed: $msg'));
    });
    errors.listen((msg) {
      if (!done.isCompleted) done.completeError(Exception('Extraction: $msg'));
    });
    final poll = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if ((cancel?.isCancelled ?? false) && !done.isCompleted) {
        done.completeError(InstallCancelledException());
      }
    });
    final isolate = await Isolate.spawn(
      _extractEntry,
      [results.sendPort, archivePath, destDir],
      onError: errors.sendPort,
    );
    try {
      await done.future.timeout(extractTimeout, onTimeout: () {
        throw TimeoutException('Extraction timed out', extractTimeout);
      });
    } finally {
      poll.cancel();
      isolate.kill(priority: Isolate.immediate);
      results.close();
      errors.close();
    }
  }

  void _checkCancelled(InstallCancelToken? cancel) {
    if (cancel?.isCancelled ?? false) throw InstallCancelledException();
  }
}

/// Extracts a `.tar.bz2` into [destDir]. Top-level so it can run in an isolate.
Future<void> extractVoiceArchive(String archivePath, String destDir) async {
  await extractFileToDisk(archivePath, destDir, throwOnError: true);
}

Future<void> _extractEntry(List<Object> args) async {
  final port = args[0] as SendPort;
  try {
    await extractVoiceArchive(args[1] as String, args[2] as String);
    port.send(null);
  } catch (e) {
    port.send('$e');
  }
}
