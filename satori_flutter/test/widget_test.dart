import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:satori/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    });

    await tester.pumpWidget(const ProviderScope(child: SatoriApp()));
  }

  testWidgets('Satori app renders incense as default page',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // 默认进入焚香倒计时页面（U1）— 应显示时间和预设选项
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('一炷香'), findsOneWidget);
  });

  testWidgets('account tab opens settings page', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Symbols.account_circle));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('开发者模式'), findsOneWidget);
    expect(find.text('品茗 · 会员与权益'), findsOneWidget);
  });

  testWidgets('tea page opens from settings and returns back',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Symbols.account_circle));
    await tester.pumpAndSettle();

    await tester.tap(find.text('品茗 · 会员与权益'));
    await tester.pumpAndSettle();

    expect(find.text('品茗'), findsOneWidget);
    expect(find.text('会员与权益'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('品茗 · 会员与权益'), findsOneWidget);
  });

  testWidgets('developer mode dialog enables without throwing assertion',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Symbols.account_circle));
    await tester.pumpAndSettle();

    await tester.tap(find.text('开发者模式'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.widgetWithText(FilledButton, '开启'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('开发者模式已开启'), findsOneWidget);
    expect(find.text('已开启'), findsOneWidget);
  });

  testWidgets('locked rain source can open tea page and return',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Symbols.noise_control_off));
    await tester.pumpAndSettle();

    await tester.tap(find.text('海浪'));
    await tester.pumpAndSettle();

    expect(find.text('前往品茗'), findsOneWidget);

    await tester.tap(find.text('前往品茗'));
    await tester.pumpAndSettle();

    expect(find.text('品茗'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('听雨'), findsWidgets);
    expect(find.text('海浪'), findsOneWidget);
  });

  testWidgets('locked qin track can open tea page and return',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Symbols.noise_control_off));
    await tester.pumpAndSettle();

    await tester.tap(find.text('抚琴'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('渔舟唱晚'));
    await tester.pumpAndSettle();

    expect(find.text('前往品茗'), findsOneWidget);

    await tester.tap(find.text('前往品茗'));
    await tester.pumpAndSettle();

    expect(find.text('品茗'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('抚琴'), findsWidgets);
    expect(find.text('渔舟唱晚'), findsOneWidget);
  });
}
