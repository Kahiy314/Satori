import 'package:shared_preferences/shared_preferences.dart';
import 'user_preferences.dart';

/// 基于 shared_preferences 的用户偏好实现。
class LocalUserPreferences implements UserPreferences {
  static const _shortFocusKey = 'short_focus_prompt_dismissed';
  static const _recentTagsKey = 'recent_tags';
  static const _maxRecentTags = 20;

  @override
  Future<bool> isShortFocusPromptDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_shortFocusKey) ?? false;
  }

  @override
  Future<void> setShortFocusPromptDismissed(bool dismissed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shortFocusKey, dismissed);
  }

  @override
  Future<List<String>> recentTags() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentTagsKey) ?? [];
  }

  @override
  Future<void> addRecentTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final tags = prefs.getStringList(_recentTagsKey) ?? [];
    tags.remove(tag); // 去重
    tags.insert(0, tag); // 最新在前
    if (tags.length > _maxRecentTags) {
      tags.removeRange(_maxRecentTags, tags.length);
    }
    await prefs.setStringList(_recentTagsKey, tags);
  }
}
