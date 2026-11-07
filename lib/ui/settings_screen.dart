import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../speech/alarm_volume.dart';
import '../speech/loudness.dart';
import '../speech/speaker.dart';

/// Small sound settings: speech boost, and the alarm volume (the phone's own
/// level, or Mondom's own level raised while an alarm plays, restored after).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.alarmVolume,
    required this.speaker,
  });

  final AlarmVolume alarmVolume;
  final Speaker speaker;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AlarmVolumeMode? _mode;
  double _level = 1.0;
  bool _boost = true;

  @override
  void initState() {
    super.initState();
    widget.speaker.addListener(_changed);
    _load();
  }

  Future<void> _load() async {
    final mode = await widget.alarmVolume.mode();
    final level = await widget.alarmVolume.level();
    final boost = await speechBoostEnabled();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _level = level;
      _boost = boost;
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.speaker.removeListener(_changed);
    // Leaving the screen ends a running test.
    if (widget.speaker.alarmPlaying) widget.speaker.stop();
    super.dispose();
  }

  Future<void> _setMode(AlarmVolumeMode? m) async {
    if (m == null) return;
    setState(() => _mode = m);
    await widget.alarmVolume.setMode(m);
  }

  Future<void> _setBoost(bool v) async {
    setState(() => _boost = v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(speechBoostKey, v);
    } catch (_) {}
  }

  void _test() {
    widget.speaker.play(
      const SentenceRowData(text: '', soundKey: 'bell', alarm: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = _mode;
    final playing = widget.speaker.alarmPlaying;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: mode == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  _header(l10n.settingsSpeechSection),
                  SwitchListTile(
                    value: _boost,
                    onChanged: _setBoost,
                    title: Text(
                      l10n.settingsBoostTitle,
                      style: const TextStyle(fontSize: 22),
                    ),
                    subtitle: Text(
                      l10n.settingsBoostHelp,
                      style: const TextStyle(fontSize: 16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  _header(l10n.settingsAlarmSection),
                  RadioGroup<AlarmVolumeMode>(
                    groupValue: mode,
                    onChanged: _setMode,
                    child: Column(
                      children: [
                        _radio(AlarmVolumeMode.system, l10n.alarmVolumeSystem),
                        _radio(AlarmVolumeMode.custom, l10n.alarmVolumeCustom),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Slider(
                      value: _level,
                      onChanged: mode == AlarmVolumeMode.custom
                          ? (v) => setState(() => _level = v)
                          : null,
                      onChangeEnd: widget.alarmVolume.setLevel,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 64,
                      child: playing
                          ? FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                              ),
                              onPressed: widget.speaker.stop,
                              icon: const Icon(Icons.stop, size: 32),
                              label: Text(
                                l10n.stopAlarm,
                                style: const TextStyle(fontSize: 22),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: _test,
                              icon: const Icon(Icons.campaign, size: 32),
                              label: Text(
                                l10n.alarmVolumeTest,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Widget _radio(AlarmVolumeMode value, String title) =>
      RadioListTile<AlarmVolumeMode>(
        value: value,
        title: Text(title, style: const TextStyle(fontSize: 22)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
}
