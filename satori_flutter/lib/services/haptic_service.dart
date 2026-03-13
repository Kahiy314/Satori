import 'package:vibration/vibration.dart';

/// 触感反馈服务
class HapticService {
  HapticService._();
  static final instance = HapticService._();

  /// 轻触 — Tab 切换、选项选择
  Future<void> lightTap() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 10, amplitude: 40);
    }
  }

  /// 中等 — 开始计时、确认操作
  Future<void> mediumTap() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 20, amplitude: 80);
    }
  }

  /// 成功 — 完成一次焚香
  Future<void> successTap() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 30, amplitude: 120);
    }
  }

  /// 警告 — 尝试访问锁定内容
  Future<void> warningTap() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 20, 50, 20], intensities: [0, 80, 0, 80]);
    }
  }
}
