import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Current and maximum level of Android's alarm stream.
typedef StreamLevels = ({int current, int max});

/// Platform access to the alarm stream volume. Abstracted for tests.
abstract class AlarmVolumeChannel {
  /// Null when the platform can't tell (e.g. no plugin in tests).
  Future<StreamLevels?> get();
  Future<void> set(int level);
}

class MethodAlarmVolumeChannel implements AlarmVolumeChannel {
  static const _channel = MethodChannel('mondom/alarm_volume');

  @override
  Future<StreamLevels?> get() async {
    try {
      final m = await _channel.invokeMapMethod<String, int>('get');
      if (m == null) return null;
      return (current: m['current']!, max: m['max']!);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> set(int level) async {
    try {
      await _channel.invokeMethod<void>('set', level);
    } on PlatformException {
      // Playing at the current volume is better than not playing.
    } on MissingPluginException {
      // Same.
    }
  }
}

enum AlarmVolumeMode { system, custom }

/// The alarm volume setting plus the raise-and-restore around each alarm.
///
/// In `custom` mode the alarm stream is set to the chosen level while an
/// alarm plays. The level it had before is kept in `alarmVolumeSaved` (and the
/// level we set in `alarmVolumeSet`) so it can be put back afterwards, even
/// if the app was killed mid-alarm: [restore] runs at app start too.
class AlarmVolume {
  AlarmVolume({AlarmVolumeChannel? channel})
    : _channel = channel ?? MethodAlarmVolumeChannel();

  static const modeKey = 'alarmVolumeMode';
  static const levelKey = 'alarmVolumeLevel';
  static const savedKey = 'alarmVolumeSaved';
  static const setKey = 'alarmVolumeSet';

  final AlarmVolumeChannel _channel;

  Future<AlarmVolumeMode> mode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(modeKey) == 'system'
        ? AlarmVolumeMode.system
        : AlarmVolumeMode.custom;
  }

  Future<void> setMode(AlarmVolumeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(modeKey, mode.name);
  }

  /// 0.0–1.0, default 1.0.
  Future<double> level() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble(levelKey) ?? 1.0).clamp(0.0, 1.0);
  }

  Future<void> setLevel(double level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(levelKey, level.clamp(0.0, 1.0));
  }

  /// Before an alarm plays. A second call while the first alarm is still
  /// raised keeps the originally saved level.
  Future<void> raise() async {
    if (await mode() != AlarmVolumeMode.custom) return;
    final levels = await _channel.get();
    if (levels == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(savedKey)) {
      await prefs.setInt(savedKey, levels.current);
    }
    // Never 0: a silent alarm is worse than a quiet one.
    final target = ((await level()) * levels.max).round().clamp(1, levels.max);
    await prefs.setInt(setKey, target);
    await _channel.set(target);
  }

  /// After an alarm ended, or at app start. Puts the saved level back unless
  /// the user has changed the volume meanwhile; the saved state is cleared
  /// either way.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(savedKey);
    if (saved == null) return;
    final ours = prefs.getInt(setKey);
    await prefs.remove(savedKey);
    await prefs.remove(setKey);
    final levels = await _channel.get();
    if (levels != null && levels.current == ours) {
      await _channel.set(saved);
    }
  }
}
