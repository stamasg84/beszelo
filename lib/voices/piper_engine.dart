import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'voice_engine.dart';

/// Wraps sherpa-onnx OfflineTts for one Piper voice directory.
/// Runs on the UI isolate for now (synthesis blocks the UI; T13 fixes that).
class PiperEngine implements VoiceEngine {
  PiperEngine({
    required this.voiceDir,
    required this.espeakDataDir,
    required this.modelFile,
    this.lengthScale = 1.2,
  });

  /// Installed voice directory (model, tokens.txt) and the shared
  /// espeak-ng-data directory, see `VoiceInstaller`.
  final String voiceDir;
  final String espeakDataDir;
  final String modelFile;

  /// 1.2 sounds best for imre (see measurements.md).
  final double lengthScale;

  sherpa.OfflineTts? _tts;
  int _counter = 0;

  @override
  int loadMs = 0;

  @override
  bool get isLoaded => _tts != null;

  @override
  Future<void> load() async {
    final sw = Stopwatch()..start();
    _tts?.free();
    _tts = null;
    sherpa.initBindings();
    final dir = voiceDir;
    final config = sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: '$dir/$modelFile',
          tokens: '$dir/tokens.txt',
          dataDir: espeakDataDir,
          lengthScale: lengthScale,
        ),
        numThreads: 2,
        debug: false,
      ),
    );
    _tts = sherpa.OfflineTts(config);
    loadMs = sw.elapsedMilliseconds;
    debugPrint('TTS load: $loadMs ms');
  }

  @override
  Future<SynthResult> synthesizeToWav(String text) async {
    final tts = _tts;
    if (tts == null) throw StateError('TTS not loaded');
    final sw = Stopwatch()..start();
    final audio = tts.generate(text: text, sid: 0, speed: 1.0);
    final synthMs = sw.elapsedMilliseconds;

    final tmp = await getTemporaryDirectory();
    final path = '${tmp.path}/tts_${_counter++}.wav';
    final ok = sherpa.writeWave(
      filename: path,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );
    if (!ok) throw FileSystemException('Failed to write WAV', path);

    final audioMs = audio.samples.length * 1000 ~/ audio.sampleRate;
    debugPrint('TTS synth: $synthMs ms for $audioMs ms of audio '
        '(RTF ${(synthMs / audioMs).toStringAsFixed(2)})');
    return SynthResult(path, synthMs, audioMs);
  }

  @override
  void dispose() {
    _tts?.free();
    _tts = null;
  }
}
