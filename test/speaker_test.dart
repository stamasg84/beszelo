import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/speech/speaker.dart';
import 'package:mondom/voices/voice.dart';
import 'package:mondom/voices/voice_engine.dart';

class FakeEngine implements VoiceEngine {
  FakeEngine(this.dir);
  final Directory dir;
  int calls = 0;
  @override
  int get loadMs => 0;
  @override
  bool get isLoaded => true;
  @override
  Future<void> load() async {}
  @override
  Future<SynthResult> synthesizeToWav(String text) async {
    final f = File('${dir.path}/${calls++}.wav')..writeAsStringSync(text);
    return SynthResult(f.path, 1, 1);
  }

  @override
  void dispose() {}
}

class FakePlayer implements WavPlayer {
  final played = <String>[];
  int stops = 0;
  @override
  Future<void> play(String path) async => played.add(path);
  @override
  Future<void> stop() async => stops++;
  @override
  void dispose() {}
}

class FakeSoundPlayer implements SoundPlayer {
  final played = <String>[];
  final looped = <bool>[];
  int stops = 0;
  final _done = StreamController<void>.broadcast();
  void finish() => _done.add(null);
  @override
  Future<void> playAsset(String asset, {bool loop = false}) async {
    played.add(asset);
    looped.add(loop);
  }

  @override
  Future<void> playFile(String path) async {
    played.add(path);
    looped.add(false);
  }

  @override
  Future<void> stop() async => stops++;
  @override
  Stream<void> get onComplete => _done.stream;
  @override
  void dispose() {}
}

void main() {
  late Directory dir;
  late FakeEngine engine;
  late FakePlayer player;
  late Speaker speaker;
  late FakeSoundPlayer sounds;
  late FakeSoundPlayer alarms;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('speaker_test');
    engine = FakeEngine(dir);
    player = FakePlayer();
    sounds = FakeSoundPlayer();
    alarms = FakeSoundPlayer();
    speaker = Speaker(
      engineFactory: (_) async => engine,
      player: player,
      soundPlayer: sounds,
      alarmPlayer: alarms,
      loopLimit: const Duration(milliseconds: 50),
    );
    await speaker.setVoice(Voice.system('hu'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('same text twice = one synthesis, replayed', () async {
    await speaker.speak('Szia!');
    await speaker.speak('Szia!');
    expect(engine.calls, 1);
    expect(player.played, hasLength(2));
    expect(player.played[0], player.played[1]);
    expect(speaker.lastReplayed, isTrue);
  });

  test('whitespace-only difference = one synthesis', () async {
    await speaker.speak('Kérek  vizet!');
    await speaker.speak('  Kérek\n vizet! ');
    expect(engine.calls, 1);
  });

  test('different text = two syntheses and old WAV deleted', () async {
    await speaker.speak('Egy.');
    final first = player.played.single;
    await speaker.speak('Kettő.');
    expect(engine.calls, 2);
    expect(File(first).existsSync(), isFalse);
    expect(File(player.played.last).existsSync(), isTrue);
    expect(speaker.lastReplayed, isFalse);
  });

  test('voice switch = re-synthesis', () async {
    await speaker.speak('Szia!');
    await speaker.setVoice(Voice.system('en'));
    await speaker.speak('Szia!');
    expect(engine.calls, 2);
  });

  test(
    'alarm sound row plays on the alarm player and sets alarmPlaying',
    () async {
      await speaker.play(
        const SentenceRowData(
          text: 'Vészhelyzet!',
          soundKey: 'siren',
          alarm: true,
        ),
      );
      expect(alarms.played, ['sounds/siren.wav']);
      expect(alarms.looped, [true]);
      expect(sounds.played, isEmpty);
      expect(engine.calls, 0);
      expect(speaker.alarmPlaying, isTrue);
      await speaker.stop();
      expect(speaker.alarmPlaying, isFalse);
    },
  );

  test('non-alarm sound row uses the normal sound player', () async {
    await speaker.play(const SentenceRowData(text: 'Ding', soundKey: 'bell'));
    expect(sounds.played, ['sounds/bell.wav']);
    expect(alarms.played, isEmpty);
    expect(speaker.alarmPlaying, isFalse);
  });

  test('unknown sound key falls back to TTS', () async {
    await speaker.play(const SentenceRowData(text: 'Szia!', soundKey: 'nope'));
    expect(engine.calls, 1);
    expect(player.played, hasLength(1));
    expect(sounds.played, isEmpty);
  });

  test('alarm row without sound is spoken on the alarm player', () async {
    await speaker.play(const SentenceRowData(text: 'Segítség!', alarm: true));
    expect(engine.calls, 1);
    expect(player.played, isEmpty);
    expect(alarms.played, hasLength(1));
    expect(speaker.alarmPlaying, isTrue);
    alarms.finish();
    await Future<void>.delayed(Duration.zero);
    expect(speaker.alarmPlaying, isFalse);
  });

  test('any new playback stops a running alarm; same row restarts', () async {
    const siren = SentenceRowData(
      text: 'Vészhelyzet!',
      soundKey: 'siren',
      alarm: true,
    );
    await speaker.play(siren);
    await speaker.speak('Szia!');
    expect(speaker.alarmPlaying, isFalse);
    expect(alarms.stops, greaterThan(0));
    await speaker.play(siren);
    await speaker.play(siren);
    expect(alarms.played, hasLength(3));
    expect(speaker.alarmPlaying, isTrue);
  });

  test('looping alarm stops itself after the limit', () async {
    await speaker.play(
      const SentenceRowData(text: 'V', soundKey: 'siren', alarm: true),
    );
    expect(speaker.alarmPlaying, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(speaker.alarmPlaying, isFalse);
  });
}
