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
  static const _sentence = 'Szia! Kérek egy pohár vizet.';

  final _engine = TtsEngine();
  final _player = AudioPlayer();
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _engine.load();
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _speak() async {
    setState(() => _busy = true);
    // Let the button repaint as disabled before the blocking synthesis.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final path = await _engine.synthesizeToWav(_sentence);
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _player.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mondom')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const Text('Betöltés…', style: TextStyle(fontSize: 24))
            else
              FilledButton(
                onPressed: (_engine.isLoaded && !_busy) ? _speak : null,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Beszélj', style: TextStyle(fontSize: 32)),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
