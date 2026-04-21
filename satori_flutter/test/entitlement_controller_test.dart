import 'package:flutter_test/flutter_test.dart';
import 'package:satori/core/models/member_tier.dart';
import 'package:satori/services/entitlement_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('开发者模式密码正确后会持久化解锁状态', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = EntitlementController();
    await controller.ready;

    expect(await controller.unlockDeveloperMode('123456'), true);
    expect(controller.isDeveloperModeEnabled, true);
    expect(controller.effectiveTier, MemberTier.premium);

    final restoredController = EntitlementController();
    await restoredController.ready;

    expect(restoredController.isDeveloperModeEnabled, true);
    expect(restoredController.effectiveTier, MemberTier.premium);

    controller.dispose();
    restoredController.dispose();
  });

  test('错误密码不会开启开发者模式', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = EntitlementController();
    await controller.ready;

    expect(await controller.unlockDeveloperMode('wrong-password'), false);
    expect(controller.isDeveloperModeEnabled, false);
    expect(controller.effectiveTier, MemberTier.free);

    controller.dispose();
  });
}
