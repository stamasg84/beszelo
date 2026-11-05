import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../speech/alarm_volume.dart';
import '../speech/speaker.dart';

/// Alarm volume setting: the phone's own alarm volume, or Mondom's own level
/// (raised while an alarm plays, restored afterwards).
class AlarmVolumeScreen extends StatefulWidget {
  const AlarmVolumeScreen({
    super.key,
    required this.alarmVolume,
    required this.speaker,
  });

  final AlarmVolume alarmVolume;
  final Speaker speaker;

  @override
  State<AlarmVolumeScreen> createState() => _AlarmVolumeScreenState();
}

class _AlarmVolumeScreenState extends State<AlarmVolumeScreen> {
  AlarmVolumeMode? _mode;
  double _level = 1.0;

  @override
  void initState() {
    super.initState();
    widget.speaker.addListener(_changed);
    _load();
  }

  Future<void> _load() async {
    final mode = await widget.alarmVolume.mode();
    final level = await widget.alarmVolume.level();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _level = level;
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
      appBar: AppBar(title: Text(l10n.alarmVolumeTitle)),
      body: SafeArea(
        child: mode == null
            ? const Center(child: CircularProgressIndicator())
            : RadioGroup<AlarmVolumeMode>(
                groupValue: mode,
                onChanged: _setMode,
                child: ListView(
                  children: [
                    _radio(AlarmVolumeMode.system, l10n.alarmVolumeSystem),
                    _radio(AlarmVolumeMode.custom, l10n.alarmVolumeCustom),
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
      ),
    );
  }

  Widget _radio(AlarmVolumeMode value, String title) =>
      RadioListTile<AlarmVolumeMode>(
        value: value,
        title: Text(title, style: const TextStyle(fontSize: 22)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
}
