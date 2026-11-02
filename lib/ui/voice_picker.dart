import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';
import '../voices/catalog.dart';
import '../voices/voice.dart';
import '../voices/voice_installer.dart';

/// Plays voice previews. Replaceable in tests.
abstract class VoicePreviewer {
  /// Streams the sample at [url]. Returns false when it can't be played.
  Future<bool> playSample(String url);

  /// Speaks [text] with the system voice.
  Future<void> speakSystem(String text, String language);

  Future<void> stop();
  void dispose();
}

class DefaultVoicePreviewer implements VoicePreviewer {
  final _player = AudioPlayer();
  FlutterTts? _tts;

  @override
  Future<bool> playSample(String url) async {
    try {
      await stop();
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return false;
      await _player.play(BytesSource(res.bodyBytes));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> speakSystem(String text, String language) async {
    await stop();
    final tts = _tts ??= FlutterTts();
    await tts.setLanguage(language);
    await tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _tts?.stop();
  }

  @override
  void dispose() {
    _player.dispose();
    _tts?.stop();
  }
}

/// Voice list: system voice + catalog voices (downloadable / installed).
class VoicePickerScreen extends StatefulWidget {
  const VoicePickerScreen({
    super.key,
    required this.catalog,
    required this.installer,
    required this.selectedId,
    required this.onSelect,
    this.firstRun = false,
    this.previewer,
  });

  final Catalog catalog;
  final VoiceInstaller installer;
  final String selectedId;

  /// Makes [voice] the active voice (saves it and loads the engine).
  final Future<void> Function(Voice voice) onSelect;

  /// Shows the "Kihagyás" button.
  final bool firstRun;
  final VoicePreviewer? previewer;

  @override
  State<VoicePickerScreen> createState() => _VoicePickerScreenState();
}

class _VoicePickerScreenState extends State<VoicePickerScreen> {
  late final VoicePreviewer _previewer;
  late String _selectedId = widget.selectedId;
  final _installed = <String>{};
  bool _checkedInstalled = false;
  bool _showOthers = false;
  String? _downloadingId;
  double _progress = 0;
  InstallStage _stage = InstallStage.downloading;
  InstallCancelToken? _token;
  String? _message;
  String? _sampleError;

  @override
  void initState() {
    super.initState();
    _previewer = widget.previewer ?? DefaultVoicePreviewer();
    _refreshInstalled();
  }

  @override
  void dispose() {
    _token?.cancel();
    _previewer.dispose();
    super.dispose();
  }

  Future<void> _refreshInstalled() async {
    for (final v in widget.catalog.voices) {
      if (await widget.installer.isInstalled(v.id)) _installed.add(v.id);
    }
    if (mounted) setState(() => _checkedInstalled = true);
  }

  String get _uiLanguage => Localizations.localeOf(context).languageCode;

  Voice get _systemVoice => Voice.system(_uiLanguage);

  Future<void> _select(Voice v) async {
    setState(() => _selectedId = v.id);
    await widget.onSelect(v);
  }

  Future<void> _download(CatalogVoice v) async {
    final l10n = AppLocalizations.of(context);
    final token = InstallCancelToken();
    setState(() {
      _downloadingId = v.id;
      _progress = 0;
      _stage = InstallStage.downloading;
      _token = token;
      _message = null;
    });
    var ok = false;
    try {
      await widget.installer.install(
        v,
        cancel: token,
        onStage: (st) {
          if (mounted) setState(() => _stage = st);
        },
        onProgress: (received, total) {
          if (mounted) setState(() => _progress = received / total);
        },
      );
      ok = true;
    } on InstallCancelledException {
      // The user cancelled; nothing to report.
    } catch (_) {
      if (mounted) setState(() => _message = l10n.downloadFailed);
    }
    if (!mounted) return;
    setState(() {
      _downloadingId = null;
      _token = null;
      if (ok) _installed.add(v.id);
    });
    if (ok) await _select(v.toVoice());
  }

  Future<void> _delete(CatalogVoice v) async {
    if (_selectedId == v.id) await _select(_systemVoice);
    await widget.installer.delete(v.id);
    if (mounted) setState(() => _installed.remove(v.id));
  }

  Future<void> _play(Future<bool> Function() play) async {
    setState(() => _sampleError = null);
    final ok = await play();
    if (!ok && mounted) {
      setState(
        () => _sampleError = AppLocalizations.of(context).sampleUnavailable,
      );
    }
  }

  Future<void> _skip() async {
    await _select(_systemVoice);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = _uiLanguage;
    final mine = widget.catalog.forLanguage(lang);
    final others = widget.catalog.voices
        .where((v) => v.language != lang)
        .toList();
    final sample = widget.catalog.sampleText[lang];
    final system = _systemVoice;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.voicePickerTitle),
        automaticallyImplyLeading: !widget.firstRun,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (widget.catalog.isBundled || widget.catalog.voices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l10n.downloadsNeedInternet),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_sampleError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _sampleError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            _row(
              key: const Key('voice-system'),
              title: l10n.systemVoice,
              subtitle: l10n.systemVoiceInfo,
              onPlay: sample == null
                  ? null
                  : () => _previewer.speakSystem(sample, lang),
              trailing: _selectedId == system.id
                  ? _selectedLabel(l10n)
                  : OutlinedButton(
                      onPressed: () => _select(system),
                      child: Text(l10n.select),
                    ),
            ),
            for (final v in mine) _catalogRow(v, l10n),
            if (others.isNotEmpty)
              ExpansionTile(
                key: const Key('more-languages'),
                title: Text(l10n.moreLanguages),
                initiallyExpanded: _showOthers,
                onExpansionChanged: (e) => _showOthers = e,
                children: [for (final v in others) _catalogRow(v, l10n)],
              ),
            if (widget.firstRun)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  key: const Key('skip'),
                  onPressed: _downloadingId == null ? _skip : null,
                  child: Text(l10n.skip, style: const TextStyle(fontSize: 20)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _selectedLabel(AppLocalizations l10n) => Chip(
    avatar: const Icon(Icons.check, size: 18),
    label: Text(l10n.selected),
  );

  Widget _catalogRow(CatalogVoice v, AppLocalizations l10n) {
    final installed = _installed.contains(v.id);
    final downloading = _downloadingId == v.id;
    final gender = switch (v.gender) {
      VoiceGender.male => l10n.genderMale,
      VoiceGender.female => l10n.genderFemale,
      VoiceGender.unknown => null,
    };
    final size = l10n.voiceSizeMb((v.sizeBytes / 1000000).round());
    final subtitle = [?gender, size].join(' · ');

    Widget trailing;
    if (downloading) {
      trailing = TextButton(
        onPressed: _token?.cancel,
        child: Text(l10n.cancel),
      );
    } else if (installed && _selectedId == v.id) {
      trailing = _selectedLabel(l10n);
    } else if (installed) {
      trailing = OutlinedButton(
        onPressed: () => _select(v.toVoice()),
        child: Text(l10n.select),
      );
    } else {
      trailing = FilledButton(
        onPressed: _downloadingId == null && _checkedInstalled
            ? () => _download(v)
            : null,
        child: Text(l10n.download),
      );
    }

    return _row(
      key: Key('voice-${v.id}'),
      title: v.label,
      subtitle: subtitle,
      onPlay: () => _play(() => _previewer.playSample(v.sampleUrl)),
      showProgress: downloading,
      progress: _stage == InstallStage.downloading ? _progress : null,
      progressLabel: downloading && _stage != InstallStage.downloading
          ? l10n.installing
          : null,
      trailing: trailing,
      onDelete: installed && !downloading ? () => _delete(v) : null,
      deleteTooltip: l10n.deleteVoice,
      playTooltip: l10n.playSample,
    );
  }

  Widget _row({
    required Key key,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onPlay,
    bool showProgress = false,
    double? progress,
    String? progressLabel,
    VoidCallback? onDelete,
    String? deleteTooltip,
    String? playTooltip,
  }) {
    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  iconSize: 36,
                  tooltip:
                      playTooltip ?? AppLocalizations.of(context).playSample,
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: onPlay,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 20)),
                      Text(subtitle),
                    ],
                  ),
                ),
                trailing,
                if (onDelete != null)
                  IconButton(
                    tooltip: deleteTooltip,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
              ],
            ),
            if (showProgress)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // value == null → indeterminate (unpacking has no
                    // measurable progress).
                    LinearProgressIndicator(value: progress),
                    if (progressLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(progressLabel),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
