/// 焚香统计相关常量
class FocusConstants {
  FocusConstants._();

  /// 最短有效专注阈值（秒）。
  /// 低于此阈值的会话不计入历史与统计聚合，
  /// 但会保留记录供提示计数。
  static const double minEffectiveDurationSeconds = 120; // 2 分钟

  /// 短时退出提示的偏好键（shared_preferences）
  static const String prefKeyShortFocusPromptDismissed =
      'short_focus_prompt_dismissed';
}
