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

void main() {
  late Directory dir;
  late FakeEngine engine;
  late FakePlayer player;
  late Speaker speaker;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('speaker_test');
    engine = FakeEngine(dir);
    player = FakePlayer();
    speaker = Speaker(engineFactory: (_) async => engine, player: player);
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
}
