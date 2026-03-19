import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satori/main.dart';

void main() {
  testWidgets('Satori app renders incense as default page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SatoriApp()));

    // 默认进入焚香倒计时页面（U1）— 应显示时间和预设选项
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('一炷香'), findsOneWidget);
  });
}
