import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'tts/tts_engine.dart';

void main() => runApp(const MondomApp());

class MondomApp extends StatelessWidget {
  const MondomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mondom',
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
    final ready = _engine.isLoaded && !_loading && !_busy;
    final last = _last;
    const small = TextStyle(fontSize: 12);
    return Scaffold(
      appBar: AppBar(title: const Text('Mondom')),
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Írj ide…',
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(
                  child: Text('Betöltés…', style: TextStyle(fontSize: 24)),
                )
              else
                FilledButton(
                  onPressed: ready ? _speak : null,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Beszélj', style: TextStyle(fontSize: 32)),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: (ready && _lastWav != null) ? _repeat : null,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Ismétlés', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Modell betöltés: ${_engine.loadMs} ms', style: small),
              if (last != null)
                Text(
                  'Szintézis: ${last.synthMs} ms, hang: ${last.audioMs} ms, '
                  'RTF: ${last.rtf.toStringAsFixed(2)}',
                  style: small,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              ExpansionTile(
                title: const Text('Hangolás'),
                tilePadding: EdgeInsets.zero,
                children: [
                  _slider('Hossz', _length, 0.7, 1.5,
                      (v) => setState(() => _length = v)),
                  _slider('Zaj', _noise, 0.3, 1.0,
                      (v) => setState(() => _noise = v)),
                  _slider('Zaj W', _noiseW, 0.3, 1.0,
                      (v) => setState(() => _noiseW = v)),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: (_dirty && !_loading && !_busy)
                            ? _applyTuning
                            : null,
                        child: const Text('Alkalmaz (újratöltés)'),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _length = 1.0;
                          _noise = 0.667;
                          _noiseW = 0.8;
                        }),
                        child: const Text('Alapértelmezett'),
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
