import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/main.dart';

void main() {
  testWidgets('Hungarian phone shows Hungarian strings', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('hu', 'HU')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MondomApp());
    expect(find.text('Mondom'), findsOneWidget);
    expect(find.text('Betöltés…'), findsOneWidget);
    expect(find.text('Ismétlés'), findsNothing);
  });

  testWidgets('other locales fall back to English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MondomApp());
    expect(find.text('Loading…'), findsOneWidget);
    expect(find.text('Repeat'), findsNothing);
  });
}
