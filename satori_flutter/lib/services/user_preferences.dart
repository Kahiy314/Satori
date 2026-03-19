/// 用户偏好存储接口 — Phase P1 定义。
///
/// 封装 shared_preferences 读写，为短时退出提示偏好、
/// 标签历史等场景提供统一入口。
abstract class UserPreferences {
  /// 短时退出提示是否已关闭
  Future<bool> isShortFocusPromptDismissed();

  /// 设置短时退出提示关闭状态
  Future<void> setShortFocusPromptDismissed(bool dismissed);

  /// 获取最近使用的标签（用于标签输入 auto-suggest）
  Future<List<String>> recentTags();

  /// 新增一条最近标签
  Future<void> addRecentTag(String tag);
}
