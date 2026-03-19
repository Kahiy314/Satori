import '../core/models/focus_session.dart';
import 'session_repository.dart';
import 'stats_aggregator.dart';

/// 本地统计聚合器 — 基于 [SessionRepository] 在内存中聚合。
class LocalStatsAggregator implements StatsAggregator {
  final SessionRepository _repository;

  LocalStatsAggregator(this._repository);

  @override
  Future<StatsSnapshot> overview() async {
    final sessions = await _repository.findAllCounted();
    if (sessions.isEmpty) return StatsSnapshot.empty;

    double totalDuration = 0;
    int abandonedCount = 0;
    double abandonedDurationSum = 0;
    final daySet = <String>{};

    for (final s in sessions) {
      totalDuration += s.actualDuration;
      final dayKey =
          '${s.startAt.year}-${s.startAt.month}-${s.startAt.day}';
      daySet.add(dayKey);

      if (s.status == SessionStatus.abandoned ||
          s.status == SessionStatus.interrupted) {
        abandonedCount++;
        abandonedDurationSum += s.actualDuration;
      }
    }

    final completedSessions =
        sessions.where((s) => s.status == SessionStatus.completed).toList();
    final avgDuration = completedSessions.isEmpty
        ? 0.0
        : completedSessions.fold<double>(
                0, (sum, s) => sum + s.actualDuration) /
            completedSessions.length;
    final avgAbandonedDuration =
        abandonedCount == 0 ? 0.0 : abandonedDurationSum / abandonedCount;

    return StatsSnapshot(
      totalDuration: totalDuration,
      totalDays: daySet.length,
      totalSessions: sessions.length,
      avgDuration: avgDuration,
      abandonedCount: abandonedCount,
      avgAbandonedDuration: avgAbandonedDuration,
    );
  }

  @override
  Future<List<DailyStats>> dailyStats(DateTime from, DateTime to) async {
    final sessions = await _repository.findByDateRange(from, to);
    final map = <String, _DayAccumulator>{};

    for (final s in sessions) {
      final key =
          '${s.startAt.year}-${s.startAt.month.toString().padLeft(2, '0')}-${s.startAt.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(
          key,
          () => _DayAccumulator(
              DateTime(s.startAt.year, s.startAt.month, s.startAt.day)));
      map[key]!.totalDuration += s.actualDuration;
      map[key]!.count++;
    }

    // 填充没有记录的日期为零值
    final result = <DailyStats>[];
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!cursor.isAfter(end)) {
      final key =
          '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      final acc = map[key];
      result.add(DailyStats(
        date: cursor,
        totalDuration: acc?.totalDuration ?? 0,
        sessionCount: acc?.count ?? 0,
      ));
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  @override
  Future<List<FocusSession>> sessionsForDay(DateTime day) async {
    return _repository.findByDateRange(day, day);
  }
}

class _DayAccumulator {
  final DateTime date;
  double totalDuration = 0;
  int count = 0;
  _DayAccumulator(this.date);
}
