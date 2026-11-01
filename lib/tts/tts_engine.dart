import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'voice_assets.dart';

/// Voice tuning parameters. Fixed at model creation time in sherpa-onnx.
class TtsTuning {
  const TtsTuning({
    this.lengthScale = 1.0,
    this.noiseScale = 0.667,
    this.noiseScaleW = 0.8,
  });

  final double lengthScale;
  final double noiseScale;
  final double noiseScaleW;
}

/// Result of one synthesis: WAV path plus timings.
class SynthResult {
  const SynthResult(this.path, this.synthMs, this.audioMs);

  final String path;
  final int synthMs;
  final int audioMs;

  double get rtf => audioMs == 0 ? 0 : synthMs / audioMs;
}

/// Wraps sherpa-onnx OfflineTts for the bundled imre voice.
/// Prototype: runs on the UI isolate (synthesis blocks the UI).
class TtsEngine {
  static const _voiceDir = 'vits-piper-hu_HU-imre-medium';

  sherpa.OfflineTts? _tts;
  int _counter = 0;

  /// Duration of the last [load] call in ms.
  int loadMs = 0;

  bool get isLoaded => _tts != null;

  /// (Re)creates the OfflineTts with [tuning]. Frees any previous instance.
  Future<void> load([TtsTuning tuning = const TtsTuning()]) async {
    final sw = Stopwatch()..start();
    _tts?.free();
    _tts = null;
    sherpa.initBindings();
    final dir = await VoiceAssets.prepare(_voiceDir);
    final config = sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: '$dir/hu_HU-imre-medium.onnx',
          tokens: '$dir/tokens.txt',
          dataDir: '$dir/espeak-ng-data',
          lengthScale: tuning.lengthScale,
          noiseScale: tuning.noiseScale,
          noiseScaleW: tuning.noiseScaleW,
        ),
        numThreads: 2,
        debug: false,
      ),
    );
    _tts = sherpa.OfflineTts(config);
    loadMs = sw.elapsedMilliseconds;
    debugPrint('TTS load: $loadMs ms');
  }

  /// Synthesizes [text], writes a WAV file and returns its path and timings.
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

  void dispose() {
    _tts?.free();
    _tts = null;
  }
}
