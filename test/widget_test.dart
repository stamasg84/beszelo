import 'package:flutter_test/flutter_test.dart';
import 'package:mondom/main.dart';

void main() {
  testWidgets('shows title and loading state', (tester) async {
    await tester.pumpWidget(const MondomApp());
    expect(find.text('Mondom'), findsOneWidget);
    expect(find.text('Betöltés…'), findsOneWidget);
  });
}
