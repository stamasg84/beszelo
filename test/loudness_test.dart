import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/speech/loudness.dart';

Float32List sine(double amp, {int n = 4000}) => Float32List.fromList([
  for (var i = 0; i < n; i++) amp * math.sin(2 * math.pi * i / 50),
]);

double rms(Float32List s) =>
    math.sqrt(s.fold(0.0, (a, x) => a + x * x) / s.length);

void main() {
  final ceiling = math.pow(10, speechCeilingDb / 20).toDouble();

  test('never exceeds the ceiling', () {
    for (final amp in [0.01, 0.2, 0.9, 1.0]) {
      final out = boostLoudness(sine(amp));
      expect(out.map((x) => x.abs()).reduce(math.max), lessThanOrEqualTo(ceiling));
    }
    // Extra gain still can't pass the ceiling.
    final loud = boostLoudness(sine(1.0), gainDb: 30);
    expect(loud.map((x) => x.abs()).reduce(math.max), lessThanOrEqualTo(ceiling));
  });

  test('silence stays silence', () {
    final out = boostLoudness(Float32List(100));
    expect(out.every((x) => x == 0), isTrue);
    expect(out.length, 100);
  });

  test('a quiet sine gets louder', () {
    final quiet = sine(0.05);
    expect(rms(boostLoudness(quiet)), greaterThan(rms(quiet) * 4));
  });

  test('wav round trip', () {
    final src = sine(0.5, n: 1000);
    final bytes = writePcm16Wav(PcmWav(src, 22050, 1));
    final back = readPcm16Wav(bytes)!;
    expect(back.sampleRate, 22050);
    expect(back.channels, 1);
    expect(back.samples.length, 1000);
    for (var i = 0; i < 1000; i++) {
      expect(back.samples[i], closeTo(src[i], 1 / 16000));
    }
  });

  test('non-16-bit or non-wav input is rejected / file unchanged', () {
    expect(readPcm16Wav(Uint8List.fromList([1, 2, 3])), isNull);
    final bytes = writePcm16Wav(PcmWav(sine(0.5, n: 10), 22050, 1));
    bytes[34] = 8; // claim 8 bits per sample
    expect(readPcm16Wav(bytes), isNull);
    final dir = Directory.systemTemp.createTempSync('loud');
    addTearDown(() => dir.deleteSync(recursive: true));
    final f = File('${dir.path}/x.wav')..writeAsBytesSync(bytes);
    expect(boostWavFile(f.path), isFalse);
    expect(f.readAsBytesSync(), bytes);
  });

  test('boostWavFile makes the file louder in place', () {
    final dir = Directory.systemTemp.createTempSync('loud');
    addTearDown(() => dir.deleteSync(recursive: true));
    final f = File('${dir.path}/y.wav')
      ..writeAsBytesSync(writePcm16Wav(PcmWav(sine(0.05), 22050, 1)));
    expect(boostWavFile(f.path), isTrue);
    final after = readPcm16Wav(f.readAsBytesSync())!;
    expect(rms(after.samples), greaterThan(rms(sine(0.05)) * 4));
  });
}
