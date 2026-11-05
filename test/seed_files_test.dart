import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/storage/database.dart';
import 'package:mondom/storage/seed.dart';

/// Structure checks on the shipped `assets/seed/*.json`. Deliberately no
/// assertions on texts or counts: the phrases are edited freely.
void main() {
  final files = Directory('assets/seed')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();
  Seed parse(File f) =>
      Seed.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
  String name(File f) => f.uri.pathSegments.last;

  test('there are seed files', () => expect(files, isNotEmpty));

  for (final f in files) {
    test('${name(f)} is well-formed', () {
      final seed = parse(f);
      final keys = seed.lists.map((l) => l.seedKey).toList();
      expect(keys, contains('everyday'));
      expect(keys.toSet(), hasLength(keys.length), reason: 'list keys');
      for (final l in seed.lists) {
        final sk = l.sentences.map((s) => s.seedKey).toList();
        expect(sk.toSet(), hasLength(sk.length), reason: '${l.seedKey} keys');
        if (l.color != null) {
          expect(listColorKeys, contains(l.color), reason: l.seedKey);
        }
        expect(
          [ListKind.everyday, ListKind.conversation],
          contains(l.kind),
          reason: l.seedKey,
        );
      }
    });
  }

  test('translations mirror hu.json (same list and sentence keys)', () {
    List<String> shape(File f) => [
      for (final l in parse(f).lists)
        '${l.seedKey}: ${l.sentences.map((s) => s.seedKey).join(',')}',
    ];
    final hu = files.firstWhere((f) => name(f) == 'hu.json');
    final expected = shape(hu);
    for (final f in files) {
      expect(shape(f), expected, reason: name(f));
    }
  });
}
