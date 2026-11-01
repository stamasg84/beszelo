import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'voices/piper_engine.dart';
import 'voices/system_engine.dart';
import 'voices/voice.dart';
import 'voices/voice_engine.dart';

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
  static const _prefKey = 'voiceId';

  VoiceEngine? _engine;
  final _player = AudioPlayer();
  final _controller = TextEditingController();

  Voice _voice = Voice.imre;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _lastWav;
  SynthResult? _last;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _voice = Voice.byId(prefs.getString(_prefKey));
    await _loadVoice();
  }

  VoiceEngine _createEngine(Voice v) => switch (v.kind) {
        VoiceKind.system => SystemEngine(v),
        VoiceKind.piper => PiperEngine(
            voiceDirName: 'vits-piper-hu_HU-imre-medium',
            modelFile: 'hu_HU-imre-medium.onnx',
          ),
      };

  Future<void> _loadVoice() async {
    setState(() => _loading = true);
    // Let the UI repaint before a blocking model load.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _engine?.dispose();
    _engine = null;
    try {
      final engine = _createEngine(_voice);
      await engine.load();
      _engine = engine;
      _error = null;
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _selectVoice(Voice? v) async {
    if (v == null || v.id == _voice.id) return;
    _voice = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, v.id);
    await _loadVoice();
  }

  Future<void> _speak() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    // Let the button repaint as disabled before the blocking synthesis.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final result = await _engine!.synthesizeToWav(text);
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

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    _engine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ready = (_engine?.isLoaded ?? false) && !_loading && !_busy;
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
              DropdownButton<Voice>(
                value: _voice,
                isExpanded: true,
                onChanged: (_loading || _busy) ? null : _selectVoice,
                items: [
                  for (final v in Voice.temporary)
                    DropdownMenuItem(value: v, child: Text(v.label)),
                ],
              ),
              const SizedBox(height: 12),
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
              Text(l10n.modelLoadTime((_engine?.loadMs ?? 0)), style: small),
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
            ],
          ),
        ),
      ),
    );
  }
}
