import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the Android TTS engine can speak a language offline.
enum SystemVoiceAvailability {
  /// Voice data is on the phone.
  installed,

  /// The engine knows the language but the voice data isn't downloaded.
  missingData,

  /// The engine can't speak the language at all.
  unsupported,
}

/// Asks Android's TTS about languages. Replaceable in tests.
abstract class SystemTtsInfo {
  Future<SystemVoiceAvailability> availability(String language);

  /// Opens Android's voice-data install screen (or the TTS settings).
  /// Returns false if neither could be opened.
  Future<bool> openInstallVoiceData();
}

class DefaultSystemTtsInfo implements SystemTtsInfo {
  static const _channel = MethodChannel('io.github.stamasg84.mondom/tts');

  @override
  Future<SystemVoiceAvailability> availability(String language) async {
    // A quirky engine must never hide the always-available voice, so any
    // failure counts as installed (the behavior before this check existed).
    // Asked natively: flutter_tts' isLanguageInstalled compares "hu" with
    // the voices' "hu_HU" and so is always false.
    try {
      final answer = await _channel.invokeMethod<String>(
        'availability',
        language,
      );
      return switch (answer) {
        'missingData' => SystemVoiceAvailability.missingData,
        'unsupported' => SystemVoiceAvailability.unsupported,
        _ => SystemVoiceAvailability.installed,
      };
    } catch (e) {
      debugPrint('System TTS availability check failed for $language: $e');
      return SystemVoiceAvailability.installed;
    }
  }

  @override
  Future<bool> openInstallVoiceData() async {
    try {
      return await _channel.invokeMethod<bool>('openInstallVoiceData') ?? false;
    } catch (_) {
      return false;
    }
  }
}
