import 'package:flutter_test/flutter_test.dart';
import 'package:satori/main.dart';

void main() {
  testWidgets('Satori app renders initial tab', (WidgetTester tester) async {
    await tester.pumpWidget(const SatoriApp());

    expect(find.text('焚香'), findsWidgets);
    expect(find.text('听雨'), findsOneWidget);
    expect(find.text('抚琴'), findsOneWidget);
    expect(find.text('品茗'), findsOneWidget);
  });
}
