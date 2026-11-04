import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../storage/lists_repository.dart';
import '../voices/language_names.dart';
import '../voices/voice.dart';
import 'lists_screen.dart';

/// Settings: a plain list of large rows. Editing lives behind it, never on the
/// speaking screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repo,
    required this.voice,
    required this.onOpenVoicePicker,
    required this.currentListId,
  });

  final ListsRepository repo;

  /// The active voice (read again after the voice picker closes).
  final Voice Function() voice;
  final Future<void> Function() onOpenVoicePicker;

  /// The list open on the speaking screen, if any.
  final int? Function() currentListId;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ui = Localizations.localeOf(context).languageCode;
    final voice = widget.voice();
    final voiceName = voice.kind == VoiceKind.system
        ? l10n.systemVoice
        : voice.label;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTooltip)),
      body: SafeArea(
        child: ListView(
          children: [
            _SettingsRow(
              icon: Icons.record_voice_over,
              title: l10n.settingsVoiceTitle,
              subtitle: l10n.settingsVoiceSubtitle(
                voiceName,
                languageName(voice.languageCode, ui),
              ),
              onTap: () async {
                await widget.onOpenVoicePicker();
                if (mounted) setState(() {});
              },
            ),
            _SettingsRow(
              icon: Icons.list_alt,
              title: l10n.settingsListsTitle,
              subtitle: l10n.settingsListsSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ListsScreen(
                    repo: widget.repo,
                    currentListId: widget.currentListId(),
                    speechLanguage: () => widget.voice().languageCode,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
