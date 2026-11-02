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
    required this.sentences,
  });
  final String seedKey;
  final String title;
  final ListKind kind;
  final bool pinned;
  final List<SeedSentence> sentences;
}

class Seed {
  const Seed(this.lists);
  final List<SeedList> lists;

  /// Format: see docs/architecture.md "Storage".
  factory Seed.fromJson(Map<String, dynamic> json) => Seed([
        for (final l in json['lists'] as List)
          SeedList(
            seedKey: l['seedKey'] as String,
            title: l['title'] as String,
            kind: ListKind.values.byName(l['kind'] as String),
            pinned: l['pinned'] as bool? ?? false,
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
