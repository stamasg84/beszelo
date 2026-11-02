import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../voices/voice.dart';
import '../voices/voice_engine.dart';

/// Plays WAV files. Abstracted so [Speaker] can be unit-tested.
abstract class WavPlayer {
  Future<void> play(String path);
  Future<void> stop();
  void dispose();
}

class AudioPlayersWavPlayer implements WavPlayer {
  final _player = AudioPlayer();

  @override
  Future<void> play(String path) => _player.play(DeviceFileSource(path));

  @override
  Future<void> stop() => _player.stop();

  @override
  void dispose() => _player.dispose();
}

/// Trim + collapse inner whitespace. Also used as the history key.
String normalizeText(String text) =>
    text.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Owns the current [VoiceEngine] and the player. Remembers only the last
/// utterance (voice id + normalized text → WAV); not a cache.
class Speaker extends ChangeNotifier {
  Speaker({
    required Future<VoiceEngine> Function(Voice) engineFactory,
    WavPlayer? player,
  }) : _createEngine = engineFactory,
       _player = player ?? AudioPlayersWavPlayer();

  final Future<VoiceEngine> Function(Voice) _createEngine;
  final WavPlayer _player;
  VoiceEngine? _engine;
  Voice? _voice;

  String? _lastKey;
  String? _lastPath;

  bool _busy = false;
  // True until the first voice is loaded (the app always sets one at start).
  bool _loading = true;
  String? _error;
  SynthResult? _lastResult;
  bool _lastReplayed = false;

  /// True while synthesizing.
  bool get busy => _busy;

  /// True while a voice is being loaded.
  bool get loading => _loading;
  String? get error => _error;
  SynthResult? get lastResult => _lastResult;

  /// Whether the last [speak] replayed the WAV instead of synthesizing.
  bool get lastReplayed => _lastReplayed;
  bool get ready => (_engine?.isLoaded ?? false) && !_loading && !_busy;
  int get loadMs => _engine?.loadMs ?? 0;

  /// Switches voice: disposes the old engine, loads the engine for [v] and
  /// forgets the last utterance.
  Future<void> setVoice(Voice v) async {
    _loading = true;
    _voice = v;
    _engine?.dispose();
    _engine = null;
    await _forgetLast();
    notifyListeners();
    try {
      final engine = await _createEngine(v);
      await engine.load();
      _engine = engine;
      _error = null;
    } catch (e) {
      _error = '$e';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    final normalized = normalizeText(text);
    final engine = _engine;
    final voice = _voice;
    if (normalized.isEmpty || engine == null || voice == null || _busy) return;
    final key = '${voice.id}\u0000$normalized';
    try {
      await _player.stop();
      if (key == _lastKey && _lastPath != null) {
        _lastReplayed = true;
        _error = null;
        notifyListeners();
        await _player.play(_lastPath!);
        return;
      }
      _busy = true;
      notifyListeners();
      final result = await engine.synthesizeToWav(normalized);
      final old = _lastPath;
      _lastKey = key;
      _lastPath = result.path;
      _lastResult = result;
      _lastReplayed = false;
      _error = null;
      if (old != null && old != result.path) await _deleteQuietly(old);
      _busy = false;
      notifyListeners();
      await _player.play(result.path);
    } catch (e) {
      _error = '$e';
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> stop() => _player.stop();

  Future<void> _forgetLast() async {
    final old = _lastPath;
    _lastKey = null;
    _lastPath = null;
    if (old != null) await _deleteQuietly(old);
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    _engine?.dispose();
    super.dispose();
  }
}
