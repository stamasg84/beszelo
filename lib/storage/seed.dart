import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'database.dart' show ListKind;

class SeedSentence {
  const SeedSentence(this.seedKey, this.text);
  final String seedKey;
  final String text;
}

class SeedList {
  const SeedList({
    required this.seedKey,
    required this.title,
    required this.kind,
    required this.pinned,
    this.color,
    required this.sentences,
  });
  final String seedKey;
  final String title;
  final ListKind kind;
  final bool pinned;

  /// Palette key, or null for neutral.
  final String? color;
  final List<SeedSentence> sentences;
}

class Seed {
  const Seed(this.lists, {this.historyTitle});
  final List<SeedList> lists;

  /// Title of the history list in this language (null: keep the current one).
  final String? historyTitle;

  /// Format: see docs/architecture.md "Storage".
  factory Seed.fromJson(Map<String, dynamic> json) =>
      Seed(historyTitle: json['historyTitle'] as String?, [
        for (final l in json['lists'] as List)
          SeedList(
            seedKey: l['seedKey'] as String,
            title: l['title'] as String,
            kind: ListKind.values.byName(l['kind'] as String),
            pinned: l['pinned'] as bool? ?? false,
            color: l['color'] as String?,
            sentences: [
              for (final s in l['sentences'] as List)
                SeedSentence(s['seedKey'] as String, s['text'] as String),
            ],
          ),
      ]);
}

/// Loads the seed for a language code; throws if there is none.
typedef SeedLoader = Future<Seed> Function(String language);

Future<Seed> loadSeedAsset(String language) async {
  final raw = await rootBundle.loadString('assets/seed/$language.json');
  return Seed.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
