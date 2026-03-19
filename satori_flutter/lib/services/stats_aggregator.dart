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

  const StatsSnapshot({
    required this.totalDuration,
    required this.totalDays,
    required this.totalSessions,
    required this.avgDuration,
    required this.abandonedCount,
    required this.avgAbandonedDuration,
  });

  static const empty = StatsSnapshot(
    totalDuration: 0,
    totalDays: 0,
    totalSessions: 0,
    avgDuration: 0,
    abandonedCount: 0,
    avgAbandonedDuration: 0,
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
  Future<StatsSnapshot> overview();

  /// 指定日期范围内的日粒度聚合（趋势图 / 热力图数据源）
  Future<List<DailyStats>> dailyStats(DateTime from, DateTime to);

  /// 指定某天的会话列表（单日时间轴数据源）
  Future<List<FocusSession>> sessionsForDay(DateTime day);
}
