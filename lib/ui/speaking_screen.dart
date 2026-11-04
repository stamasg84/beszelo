import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../speech/speaker.dart';
import '../storage/lists_repository.dart';
import '../voices/voice.dart';
import 'list_colors.dart';
import 'settings_screen.dart';

/// Main screen: list chips, big sentence rows, always-visible free text.
class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({
    super.key,
    required this.speaker,
    required this.repo,
    this.voice,
    this.onOpenVoicePicker,
  });

  final Speaker speaker;
  final ListsRepository repo;

  /// The active voice, shown in settings. Defaults to the Hungarian system voice.
  final Voice Function()? voice;
  final Future<void> Function()? onOpenVoicePicker;

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final _controller = TextEditingController();

  late final Stream<List<SentenceList>> _lists;
  StreamSubscription<List<SentenceList>>? _listsSub;
  int? _lastUsedId;
  Stream<List<Sentence>>? _sentences;
  int? _currentId;
  bool _currentIsHistory = false;
  bool _currentIsConversation = false;

  /// After "Következő": the id of the sentence just said; once its `said`
  /// flag arrives, the new next row is scrolled into view (never otherwise).
  int? _scrollAfterId;
  final _scrollController = ScrollController();
  final _nextKey = GlobalKey();

  /// The open list was chosen by the fallback rule, not by the user or the
  /// remembered last list, so it may be replaced when lists appear later
  /// (e.g. the first seed is inserted after this screen is built).
  bool _autoPicked = false;
  int? _tappedId;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _lists = widget.repo.watchLists().asBroadcastStream();
    _start();
  }

  Future<void> _start() async {
    _lastUsedId = await widget.repo.lastUsedListId();
    if (!mounted) return;
    _listsSub = _lists.listen(_onLists);
  }

  /// Opens the last used list, else the first `everyday` list, else any
  /// non-history list, else history. Re-evaluated whenever the lists change
  /// while no valid list is open (or only a fallback history is).
  void _onLists(List<SentenceList> lists) {
    final current = lists.where((l) => l.id == _currentId).firstOrNull;
    if (current != null && !(_autoPicked && _currentIsHistory)) return;
    final lastUsed = lists.where((l) => l.id == _lastUsedId).firstOrNull;
    final initial =
        lastUsed ??
        lists.where((l) => l.seedKey == 'everyday').firstOrNull ??
        lists.where((l) => l.kind != ListKind.history).firstOrNull ??
        lists.firstOrNull;
    if (initial == null || initial.id == _currentId) return;
    _autoPicked = lastUsed == null;
    _showList(initial, remember: false);
  }

  void _showList(SentenceList list, {bool remember = true}) {
    final id = list.id;
    if (remember) _autoPicked = false;
    setState(() {
      _currentId = id;
      _currentIsHistory = list.kind == ListKind.history;
      _currentIsConversation = list.kind == ListKind.conversation;
      _scrollAfterId = null;
      _sentences = widget.repo.watchSentences(id);
      _expanded = false;
    });
    if (remember) widget.repo.setLastUsedListId(id);
  }

  Future<void> _speak(String text, {int? rowId}) async {
    final speaker = widget.speaker;
    if (!speaker.ready || text.trim().isEmpty) return;
    setState(() => _tappedId = rowId);
    if (rowId != null && _currentIsConversation) {
      unawaited(widget.repo.setSaid(rowId, true));
    }
    // Tapping a row in the history list must not reorder it under the finger.
    if (rowId == null || !_currentIsHistory) {
      unawaited(widget.repo.addToHistory(text));
    }
    await speaker.speak(text);
    if (mounted) setState(() => _tappedId = null);
  }

  @override
  void dispose() {
    _listsSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          repo: widget.repo,
          voice: widget.voice ?? () => Voice.system('hu'),
          onOpenVoicePicker: widget.onOpenVoicePicker ?? () async {},
          currentListId: () => _currentId,
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n, SentenceList l) =>
      l.kind == ListKind.history && l.title.isEmpty
      ? l10n.historyTitle
      : l.title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<SentenceList>>(
      stream: _lists,
      builder: (context, snap) {
        final lists = snap.data ?? const <SentenceList>[];
        final current = lists.where((l) => l.id == _currentId).firstOrNull;
        return Scaffold(
          appBar: AppBar(
            // The open list's name, so the screen says which list it is in
            // words as well as color.
            title: Text(
              current == null ? '' : _title(l10n, current),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: l10n.settingsTooltip,
                icon: const Icon(Icons.settings),
                onPressed: _openSettings,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _chipRow(l10n, lists),
                Expanded(
                  child: _expanded
                      ? _listGrid(l10n, lists)
                      : _sentenceArea(l10n, current),
                ),
                _bottomBar(l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chipRow(AppLocalizations l10n, List<SentenceList> lists) {
    final shown = [
      for (final l in lists)
        if (l.pinned || l.id == _currentId) l,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final l in shown)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          _title(l10n, l),
                          style: const TextStyle(fontSize: 20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        selected: l.id == _currentId,
                        showCheckmark: false,
                        backgroundColor: listColor(context, l.color).chip,
                        selectedColor: listColor(context, l.color).chip,
                        side: l.id == _currentId
                            ? BorderSide(
                                width: 4,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                            : BorderSide.none,
                        onSelected: (_) => _showList(l),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            iconSize: 36,
            tooltip: l10n.allLists,
            icon: Icon(_expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ),
    );
  }

  Widget _listGrid(AppLocalizations l10n, List<SentenceList> lists) {
    return GridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        for (final l in lists)
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: listColor(context, l.color).chip,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              side: l.id == _currentId
                  ? BorderSide(
                      width: 4,
                      color: Theme.of(context).colorScheme.onSurface,
                    )
                  : null,
            ),
            onPressed: () => _showList(l),
            child: Text(
              _title(l10n, l),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
            ),
          ),
      ],
    );
  }

  Widget _sentenceArea(AppLocalizations l10n, SentenceList? list) {
    final stream = _sentences;
    if (stream == null) return const SizedBox.shrink();
    return StreamBuilder<List<Sentence>>(
      stream: stream,
      builder: (context, snap) {
        final sentences = snap.data;
        if (sentences == null) return const SizedBox.shrink();
        if (sentences.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.emptyListHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          );
        }
        final conversation = list?.kind == ListKind.conversation;
        final next = conversation
            ? sentences.where((s) => !s.said).firstOrNull
            : null;
        final pending = _scrollAfterId;
        if (pending != null &&
            sentences.any((s) => s.id == pending && s.said)) {
          _scrollAfterId = null;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToNext(sentences),
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: widget.speaker,
                builder: (context, _) => ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: sentences.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _row(
                    sentences[i],
                    list?.color,
                    isNext: next != null && sentences[i].id == next.id,
                  ),
                ),
              ),
            ),
            if (conversation) _nextBar(l10n, next),
          ],
        );
      },
    );
  }

  /// Brings the next unsaid row into view: exact if it is built, otherwise
  /// jump near it by an estimated row height first.
  void _scrollToNext(List<Sentence> sentences) {
    if (!mounted || !_scrollController.hasClients) return;
    final i = sentences.indexWhere((s) => !s.said);
    if (i < 0) return;
    final ctx = _nextKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      return;
    }
    final pos = _scrollController.position;
    _scrollController.jumpTo((i * 80.0).clamp(0, pos.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _nextKey.currentContext;
      if (mounted && c != null) Scrollable.ensureVisible(c);
    });
  }

  Future<void> _speakNext(Sentence next) async {
    if (!widget.speaker.ready) return;
    _scrollAfterId = next.id;
    await _speak(next.body, rowId: next.id);
  }

  Future<void> _confirmReset(int listId) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(
          l10n.resetSaidQuestion,
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.resetSaid),
          ),
        ],
      ),
    );
    if (ok == true) await widget.repo.resetSaid(listId);
  }

  Widget _nextBar(AppLocalizations l10n, Sentence? next) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: next != null
          ? SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton.icon(
                onPressed: widget.speaker.ready ? () => _speakNext(next) : null,
                icon: const Icon(Icons.play_arrow, size: 32),
                label: Text(
                  l10n.nextSentence,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            )
          : SizedBox(
              height: 64,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.allSaid,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 56),
                    ),
                    onPressed: () => _confirmReset(_currentId!),
                    child: Text(
                      l10n.resetSaid,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(Sentence s, String? colorKey, {bool isNext = false}) {
    final scheme = Theme.of(context).colorScheme;
    final tones = listColor(context, colorKey);
    final active = _tappedId == s.id;
    return Material(
      key: isNext ? _nextKey : null,
      color: active ? tones.rowActive : tones.row,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNext
            ? BorderSide(width: 3, color: scheme.onSurface)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _speak(s.body, rowId: s.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 72,
            minWidth: double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.body,
                    style: TextStyle(
                      fontSize: 24,
                      color: s.said
                          ? scheme.onSurface.withValues(alpha: saidTextAlpha)
                          : null,
                    ),
                  ),
                ),
                if (active && widget.speaker.busy)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(AppLocalizations l10n) {
    return ListenableBuilder(
      listenable: widget.speaker,
      builder: (context, _) {
        final speaker = widget.speaker;
        final error = speaker.error;
        return Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 24),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: l10n.textHint,
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _controller,
                            builder: (context, value, _) => value.text.isEmpty
                                ? const SizedBox.shrink()
                                : IconButton(
                                    iconSize: 32,
                                    tooltip: l10n.clearText,
                                    icon: const Icon(Icons.close),
                                    onPressed: _controller.clear,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (speaker.loading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          l10n.loading,
                          style: const TextStyle(fontSize: 22),
                        ),
                      )
                    else
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: speaker.ready
                              ? () => _speak(_controller.text)
                              : null,
                          child: speaker.busy && _tappedId == null
                              ? const SizedBox(
                                  height: 28,
                                  width: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  l10n.speak,
                                  style: const TextStyle(fontSize: 26),
                                ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
