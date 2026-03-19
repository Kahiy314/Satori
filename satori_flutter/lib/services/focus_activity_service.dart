/// 焚香后台可见性服务接口 — Phase P5。
///
/// 为焚香的后台进行中展示抽象 start / update / stop 接口。
/// iOS 通过 Live Activity 实现，Android 通过通知栏前台服务实现。
/// 业务层只依赖此接口，不感知平台通道细节。
abstract class FocusActivityService {
  /// 开始一次焚香活动展示。
  /// [totalSeconds] 倒计时总秒数，正计时传 null。
  /// [isCountdown] 是否为倒计时模式。
  Future<void> startActivity({
    required bool isCountdown,
    double? totalSeconds,
  });

  /// 更新当前进行中的展示。
  /// [remainingOrElapsed] 剩余秒数（倒计时）或已用秒数（正计时）。
  Future<void> updateActivity({
    required double remainingOrElapsed,
  });

  /// 结束当前活动展示。
  Future<void> stopActivity();

  /// 当前是否有活动在展示中。
  bool get isActive;
}
