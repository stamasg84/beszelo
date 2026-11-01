import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'tts/tts_engine.dart';

void main() => runApp(const MondomApp());

class MondomApp extends StatelessWidget {
  const MondomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Hungarian phones get Hungarian; everything else falls back to English.
      localeResolutionCallback: (locale, supported) =>
          locale?.languageCode == 'hu'
              ? const Locale('hu')
              : const Locale('en'),
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _engine = TtsEngine();
  final _player = AudioPlayer();
  final _controller = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _lastWav;
  SynthResult? _last;

  // Tuning applied to the loaded model, and the current slider values.
  TtsTuning _applied = const TtsTuning();
  double _length = 1.0;
  double _noise = 0.667;
  double _noiseW = 0.8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _engine.load(_applied);
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _speak() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    // Let the button repaint as disabled before the blocking synthesis.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final result = await _engine.synthesizeToWav(text);
      _last = result;
      _lastWav = result.path;
      _error = null;
      await _player.play(DeviceFileSource(result.path));
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _repeat() async {
    final path = _lastWav;
    if (path == null) return;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  bool get _dirty =>
      _length != _applied.lengthScale ||
      _noise != _applied.noiseScale ||
      _noiseW != _applied.noiseScaleW;

  Future<void> _applyTuning() async {
    final tuning = TtsTuning(
      lengthScale: _length,
      noiseScale: _noise,
      noiseScaleW: _noiseW,
    );
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      await _engine.load(tuning);
      _applied = tuning;
      _error = null;
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    _engine.dispose();
    super.dispose();
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text('$label ${value.toStringAsFixed(2)}'),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ready = _engine.isLoaded && !_loading && !_busy;
    final last = _last;
    const small = TextStyle(fontSize: 12);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 8,
                style: const TextStyle(fontSize: 26),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.textHint,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                Center(
                  child: Text(l10n.loading,
                      style: const TextStyle(fontSize: 24)),
                )
              else
                FilledButton(
                  onPressed: ready ? _speak : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.speak,
                        style: const TextStyle(fontSize: 32)),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: (ready && _lastWav != null) ? _repeat : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.repeat,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.modelLoadTime(_engine.loadMs), style: small),
              if (last != null)
                Text(
                  l10n.synthesisStats(
                      last.synthMs, last.audioMs, last.rtf.toStringAsFixed(2)),
                  style: small,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              ExpansionTile(
                title: Text(l10n.tuning),
                tilePadding: EdgeInsets.zero,
                children: [
                  _slider(l10n.tuningLength, _length, 0.7, 1.5,
                      (v) => setState(() => _length = v)),
                  _slider(l10n.tuningNoise, _noise, 0.3, 1.0,
                      (v) => setState(() => _noise = v)),
                  _slider(l10n.tuningNoiseW, _noiseW, 0.3, 1.0,
                      (v) => setState(() => _noiseW = v)),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: (_dirty && !_loading && !_busy)
                            ? _applyTuning
                            : null,
                        child: Text(l10n.tuningApply),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _length = 1.0;
                          _noise = 0.667;
                          _noiseW = 0.8;
                        }),
                        child: Text(l10n.tuningReset),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
