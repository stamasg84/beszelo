import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../storage/lists_repository.dart';
import 'list_colors.dart';
import 'list_editor_screen.dart';

/// Lists overview: reorder, pin, rename, delete, create, restore defaults.
/// Sentences are edited in the per-list editor.
class ListsScreen extends StatefulWidget {
  const ListsScreen({
    super.key,
    required this.repo,
    required this.currentListId,
    required this.speechLanguage,
  });

  final ListsRepository repo;

  /// The list open on the speaking screen.
  final int? currentListId;

  /// Language of the selected voice (for restoring default lists).
  final String Function() speechLanguage;

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  late final Stream<List<SentenceList>> _lists = widget.repo
      .watchLists()
      .asBroadcastStream();
  late final Stream<Map<int, int>> _counts = widget.repo
      .watchSentenceCounts()
      .asBroadcastStream();
  late final Stream<bool> _missing = widget.repo
      .watchHasMissingDefaultLists(widget.speechLanguage())
      .asBroadcastStream();

  String _title(AppLocalizations l10n, SentenceList l) =>
      l.kind == ListKind.history && l.title.isEmpty
      ? l10n.historyTitle
      : l.title;

  void _openEditor(int id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListEditorScreen(repo: widget.repo, listId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsListsTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<SentenceList>>(
                stream: _lists,
                builder: (context, snap) {
                  final lists = snap.data ?? const <SentenceList>[];
                  return StreamBuilder<Map<int, int>>(
                    stream: _counts,
                    builder: (context, countSnap) {
                      final counts = countSnap.data ?? const <int, int>{};
                      return ReorderableListView.builder(
                        padding: const EdgeInsets.all(12),
                        buildDefaultDragHandles: false,
                        itemCount: lists.length,
                        onReorderItem: (from, to) {
                          final ids = [for (final l in lists) l.id];
                          ids.insert(to, ids.removeAt(from));
                          widget.repo.reorderLists(ids);
                        },
                        itemBuilder: (context, i) =>
                            _row(l10n, lists[i], i, counts[lists[i].id] ?? 0),
                      );
                    },
                  );
                },
              ),
            ),
            StreamBuilder<bool>(
              stream: _missing,
              builder: (context, snap) => snap.data == true
                  ? _restoreRow(l10n)
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _newList,
                  icon: const Icon(Icons.add),
                  label: Text(
                    l10n.newList,
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

  Widget _restoreRow(AppLocalizations l10n) {
    return InkWell(
      onTap: () => widget.repo.restoreDefaultLists(widget.speechLanguage()),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 72,
          minWidth: double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.restore, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.restoreDefaultLists,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(AppLocalizations l10n, SentenceList l, int index, int count) {
    final scheme = Theme.of(context).colorScheme;
    final isOpen = l.id == widget.currentListId;
    final tones = listColor(context, l.color);
    return Padding(
      key: ValueKey(l.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: tones.row,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openEditor(l.id),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(width: 12, color: tones.stripe),
                ),
              ),
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title(l10n, l),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 2,
                          children: [
                            Text(
                              l10n.sentenceCount(count),
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (l.pinned)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.push_pin, size: 18),
                                  const SizedBox(width: 2),
                                  Text(
                                    l10n.pinnedLabel,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            if (isOpen)
                              Text(
                                l10n.currentlyOpen,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 28,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: l10n.moreActions,
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _actions(l, count),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Semantics(
                      label: l10n.reorderHandle,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.drag_handle, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _actions(SentenceList l, int count) async {
    final l10n = AppLocalizations.of(context);
    final isHistory = l.kind == ListKind.history;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isHistory)
              _sheetRow(context, Icons.edit, l10n.renameList, 'rename'),
            _sheetRow(
              context,
              l.pinned ? Icons.push_pin_outlined : Icons.push_pin,
              l.pinned ? l10n.unpinList : l10n.pinList,
              'pin',
            ),
            if (!isHistory)
              _sheetRow(
                context,
                Icons.palette,
                l10n.listColorLabel,
                'color',
                trailing: _Swatch(
                  color: listColor(context, l.color).stripe,
                  size: 28,
                  neutral: l.color == null,
                ),
              ),
            if (!isHistory)
              _sheetRow(context, Icons.delete, l10n.deleteList, 'delete'),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'rename':
        await _rename(l);
      case 'pin':
        await widget.repo.setPinned(l.id, !l.pinned);
      case 'color':
        await _pickColor(l);
      case 'delete':
        await _delete(l, count);
    }
  }

  Widget _sheetRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 64,
          minWidth: double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(fontSize: 22)),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
            ],
          ),
        ),
      ),
    );
  }

  /// Grid of swatches; tapping one saves at once and closes the dialog.
  Future<void> _pickColor(SentenceList l) async {
    final l10n = AppLocalizations.of(context);
    final names = {
      'blue': l10n.colorName_blue,
      'green': l10n.colorName_green,
      'orange': l10n.colorName_orange,
      'purple': l10n.colorName_purple,
      'teal': l10n.colorName_teal,
      'pink': l10n.colorName_pink,
      'yellow': l10n.colorName_yellow,
      'brown': l10n.colorName_brown,
    };
    // A sentinel: dialog dismissed (no change) vs. "Nincs" (null).
    const none = '';
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.listColorDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final key in listColorKeys)
                    Semantics(
                      label: names[key],
                      selected: l.color == key,
                      button: true,
                      child: InkWell(
                        key: ValueKey('swatch-$key'),
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(key),
                        child: _Swatch(
                          color: listColor(context, key).stripe,
                          size: 56,
                          checked: l.color == key,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                key: const ValueKey('swatch-none'),
                onTap: () => Navigator.of(context).pop(none),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 56,
                    minWidth: double.infinity,
                  ),
                  child: Row(
                    children: [
                      _Swatch(
                        color: Theme.of(context).colorScheme.outline,
                        size: 40,
                        neutral: true,
                        checked: l.color == null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.listColorNone,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    await widget.repo.setColor(l.id, picked == none ? null : picked);
  }

  Future<void> _rename(SentenceList l) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: l.title, create: false),
    );
    if (name != null) await widget.repo.renameList(l.id, name);
  }

  Future<void> _delete(SentenceList l, int count) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          l10n.deleteListQuestion(l.title, count),
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
    if (ok == true) await widget.repo.deleteList(l.id);
  }

  Future<void> _newList() async {
    final result = await showDialog<(String, ListKind)>(
      context: context,
      builder: (_) => const _NameDialog(initial: '', create: true),
    );
    if (result == null) return;
    final (name, kind) = result;
    final id = await widget.repo.createList(name, kind: kind, pinned: true);
    if (!mounted) return;
    _openEditor(id);
  }
}

/// Round color swatch; [neutral] draws an outline only, [checked] a check mark.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.size,
    this.neutral = false,
    this.checked = false,
  });
  final Color color;
  final double size;
  final bool neutral;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: neutral ? null : color,
        border: Border.all(color: color, width: 3),
      ),
      child: checked
          ? Icon(
              Icons.check,
              size: size * 0.6,
              color: neutral
                  ? color
                  : ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.dark
                  ? Colors.white
                  : Colors.black,
            )
          : null,
    );
  }
}

/// Name dialog for rename (returns the name) and create (returns name + kind).
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial, required this.create});

  final String initial;
  final bool create;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  ListKind _kind = ListKind.everyday;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop<Object>(widget.create ? (name, _kind) : name);
  }

  Widget _kindRow(String title, String? subtitle, ListKind kind) {
    final selected = _kind == kind;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: () => setState(() => _kind = kind),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20)),
                    if (subtitle != null)
                      Text(subtitle, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.create ? l10n.newList : l10n.renameList),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 22),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.listNameLabel,
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.create) ...[
              const SizedBox(height: 12),
              _kindRow(l10n.kindEveryday, null, ListKind.everyday),
              _kindRow(
                l10n.kindConversation,
                l10n.kindConversationInfo,
                ListKind.conversation,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.create ? l10n.createAction : l10n.saveAction),
        ),
      ],
    );
  }
}
