import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'speech/speaker.dart';
import 'ui/voice_picker.dart';
import 'voices/catalog.dart';
import 'voices/piper_engine.dart';
import 'voices/system_engine.dart';
import 'voices/voice.dart';
import 'voices/voice_engine.dart';
import 'voices/voice_installer.dart';

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

  late final Speaker _speaker;
  final _controller = TextEditingController();

  final _installer = VoiceInstaller();
  Catalog _catalog = Catalog.empty;

  Voice _voice = Voice.system('hu');

  @override
  void initState() {
    super.initState();
    _speaker = Speaker(engineFactory: _createEngine)
      ..addListener(() => setState(() {}));
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    await _installer.cleanupStaging();
    final info = await PackageInfo.fromPlatform();
    _catalog = await CatalogRepository(appVersion: info.version).load();
    if (!mounted) return;
    final uiLang = Localizations.localeOf(context).languageCode;
    final savedId = prefs.getString(_prefKey);
    final saved = _catalog.byId(savedId ?? '');
    if (saved != null && await _installer.isInstalled(saved.id)) {
      _voice = saved.toVoice();
    } else if (savedId != null && savedId.startsWith('system-')) {
      _voice = Voice.system(savedId.substring('system-'.length));
    } else {
      _voice = Voice.system(uiLang);
    }
    await _speaker.setVoice(_voice);
    // First launch: no voice chosen yet.
    if (savedId == null && mounted) _openPicker(firstRun: true);
  }

  void _openPicker({bool firstRun = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VoicePickerScreen(
          catalog: _catalog,
          installer: _installer,
          selectedId: _voice.id,
          firstRun: firstRun,
          onSelect: _selectVoice,
        ),
      ),
    );
  }

  Future<VoiceEngine> _createEngine(Voice v) async => switch (v.kind) {
    VoiceKind.system => SystemEngine(v),
    VoiceKind.piper => PiperEngine(
      voiceDir: await _installer.voiceDir(v.id),
      espeakDataDir: await _installer.espeakDataDir(),
      modelFile: _catalog.byId(v.id)!.modelFile,
    ),
  };

  Future<void> _selectVoice(Voice v) async {
    _voice = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, v.id);
    await _speaker.setVoice(v);
  }

  @override
  void dispose() {
    _controller.dispose();
    _speaker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final speaker = _speaker;
    final ready = speaker.ready;
    final last = speaker.lastResult;
    final error = speaker.error;
    const small = TextStyle(fontSize: 12);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.voiceSettingsTooltip,
            icon: const Icon(Icons.record_voice_over),
            onPressed: _openPicker,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            iconSize: 36,
                            tooltip: l10n.clearText,
                            icon: const Icon(Icons.close),
                            onPressed: _controller.clear,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (speaker.loading)
                Center(
                  child: Text(
                    l10n.loading,
                    style: const TextStyle(fontSize: 24),
                  ),
                )
              else
                FilledButton(
                  onPressed: ready
                      ? () => speaker.speak(_controller.text)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: speaker.busy
                        ? const SizedBox(
                            height: 44,
                            width: 44,
                            child: CircularProgressIndicator(strokeWidth: 4),
                          )
                        : Text(
                            l10n.speak,
                            style: const TextStyle(fontSize: 32),
                          ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(l10n.modelLoadTime(speaker.loadMs), style: small),
              if (last != null)
                Text(
                  speaker.lastReplayed
                      ? l10n.replayed
                      : l10n.synthesisStats(
                          last.synthMs,
                          last.audioMs,
                          last.rtf.toStringAsFixed(2),
                        ),
                  style: small,
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
