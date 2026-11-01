import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'voice_assets.dart';

/// Wraps sherpa-onnx OfflineTts for the bundled imre voice.
/// Prototype: runs on the UI isolate (synthesis blocks the UI).
class TtsEngine {
  static const _voiceDir = 'vits-piper-hu_HU-imre-medium';

  sherpa.OfflineTts? _tts;
  int _counter = 0;

  bool get isLoaded => _tts != null;

  Future<void> load() async {
    final sw = Stopwatch()..start();
    sherpa.initBindings();
    final dir = await VoiceAssets.prepare(_voiceDir);
    final config = sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: '$dir/hu_HU-imre-medium.onnx',
          tokens: '$dir/tokens.txt',
          dataDir: '$dir/espeak-ng-data',
        ),
        numThreads: 2,
        debug: false,
      ),
    );
    _tts = sherpa.OfflineTts(config);
    debugPrint('TTS load: ${sw.elapsedMilliseconds} ms');
  }

  /// Synthesizes [text] and returns the path of the written WAV file.
  Future<String> synthesizeToWav(String text) async {
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
    return path;
  }

  void dispose() {
    _tts?.free();
    _tts = null;
  }
}
