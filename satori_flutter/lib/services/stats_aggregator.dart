import '../core/models/focus_session.dart';
import 'session_repository.dart';

/// 统计聚合结果
class StatsSnapshot {
  /// 总有效专注时长（秒）
  final double totalDuration;

  /// 有效专注天数
  final int totalDays;

  /// 有效专注次数
  final int totalSessions;

  /// 平均每次时长（秒）
  final double avgDuration;

  /// 放弃次数（abandoned + interrupted，仅统计 counted）
  final int abandonedCount;

  /// 平均多久放弃（秒）
  final double avgAbandonedDuration;

  /// 正常完成次数
  final int completedSessions;

  /// 当前连续专注天数（以查询结束日为锚点）
  final int currentStreak;

  /// 最长连续专注天数
  final int longestStreak;

  /// 完成率（0 - 1）
  final double completionRate;

  /// 最长单次完成时长（秒）
  final double longestSessionDuration;

  /// 最佳专注时段（0 - 23 点）
  final int? bestFocusHour;

  /// 最常见标签
  final String? topTag;

  /// 最常见感受
  final ReflectionMood? topMood;

  const StatsSnapshot({
    required this.totalDuration,
    required this.totalDays,
    required this.totalSessions,
    required this.avgDuration,
    required this.abandonedCount,
    required this.avgAbandonedDuration,
    required this.completedSessions,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.longestSessionDuration,
    required this.bestFocusHour,
    required this.topTag,
    required this.topMood,
  });

  static const empty = StatsSnapshot(
    totalDuration: 0,
    totalDays: 0,
    totalSessions: 0,
    avgDuration: 0,
    abandonedCount: 0,
    avgAbandonedDuration: 0,
    completedSessions: 0,
    currentStreak: 0,
    longestStreak: 0,
    completionRate: 0,
    longestSessionDuration: 0,
    bestFocusHour: null,
    topTag: null,
    topMood: null,
  );
}

/// 日粒度聚合点（用于趋势图 / 热力图）
class DailyStats {
  final DateTime date;
  final double totalDuration;
  final int sessionCount;

  const DailyStats({
    required this.date,
    required this.totalDuration,
    required this.sessionCount,
  });
}

/// 统计聚合器 — Phase P1 定义接口，Phase P3 实现。
///
/// 从 [SessionRepository] 拉取会话列表，在内存中完成聚合。
abstract class StatsAggregator {
  /// 全量概览
  Future<StatsSnapshot> overview({DateTime? from, DateTime? to});

  /// 指定日期范围内的日粒度聚合（趋势图 / 热力图数据源）
  Future<List<DailyStats>> dailyStats(DateTime from, DateTime to);

  /// 指定某天的会话列表（单日时间轴数据源）
  Future<List<FocusSession>> sessionsForDay(DateTime day);

  /// 指定日期范围内的会话列表（历史检索 / 懒加载数据源）
  Future<List<FocusSession>> sessionsInRange(DateTime from, DateTime to);
}
