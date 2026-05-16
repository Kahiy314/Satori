import '../core/models/focus_session.dart';
import 'session_repository.dart';
import 'stats_aggregator.dart';

/// 本地统计聚合器 — 基于 [SessionRepository] 在内存中聚合。
class LocalStatsAggregator implements StatsAggregator {
  final SessionRepository _repository;

  LocalStatsAggregator(this._repository);

  @override
  Future<StatsSnapshot> overview({DateTime? from, DateTime? to}) async {
    final sessions = await _sessionsForOptionalRange(from, to);
    if (sessions.isEmpty) return StatsSnapshot.empty;

    double totalDuration = 0;
    int abandonedCount = 0;
    double abandonedDurationSum = 0;
    final daySet = <String>{};
    final completedHourDuration = <int, double>{};
    final tagCounts = <String, int>{};
    final moodCounts = <ReflectionMood, int>{};

    for (final s in sessions) {
      totalDuration += s.actualDuration;
      final dayKey =
          '${s.startAt.year}-${s.startAt.month}-${s.startAt.day}';
      daySet.add(dayKey);

      if (s.taskTag != null && s.taskTag!.trim().isNotEmpty) {
        final normalizedTag = s.taskTag!.trim();
        tagCounts.update(normalizedTag, (count) => count + 1,
            ifAbsent: () => 1);
      }

      if (s.reflectionMood != null) {
        moodCounts.update(s.reflectionMood!, (count) => count + 1,
            ifAbsent: () => 1);
      }

      if (s.status == SessionStatus.abandoned ||
          s.status == SessionStatus.interrupted) {
        abandonedCount++;
        abandonedDurationSum += s.actualDuration;
      }
    }

    final completedSessions =
        sessions.where((s) => s.status == SessionStatus.completed).toList();
    for (final s in completedSessions) {
      completedHourDuration.update(
        s.startAt.hour,
        (duration) => duration + s.actualDuration,
        ifAbsent: () => s.actualDuration,
      );
    }

    final avgDuration = completedSessions.isEmpty
        ? 0.0
        : completedSessions.fold<double>(
                0, (sum, s) => sum + s.actualDuration) /
            completedSessions.length;
    final avgAbandonedDuration =
        abandonedCount == 0 ? 0.0 : abandonedDurationSum / abandonedCount;
    final bestFocusHour = _bestHour(completedHourDuration);
    final topTag = _topEntry(tagCounts);
    final topMood = _topEntry(moodCounts);
    final currentStreak = _currentStreak(
      sessions: completedSessions,
      anchorDay: _anchorDay(from, to),
    );
    final longestStreak = _longestStreak(completedSessions);
    final longestSessionDuration = completedSessions.fold<double>(
      0,
      (maxDuration, session) =>
          session.actualDuration > maxDuration ? session.actualDuration : maxDuration,
    );
    final completionRate =
        sessions.isEmpty ? 0.0 : completedSessions.length / sessions.length;

    return StatsSnapshot(
      totalDuration: totalDuration,
      totalDays: daySet.length,
      totalSessions: sessions.length,
      avgDuration: avgDuration,
      abandonedCount: abandonedCount,
      avgAbandonedDuration: avgAbandonedDuration,
      completedSessions: completedSessions.length,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionRate: completionRate,
      longestSessionDuration: longestSessionDuration,
      bestFocusHour: bestFocusHour,
      topTag: topTag,
      topMood: topMood,
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

  @override
  Future<List<FocusSession>> sessionsInRange(DateTime from, DateTime to) {
    return _repository.findByDateRange(from, to);
  }

  Future<List<FocusSession>> _sessionsForOptionalRange(
    DateTime? from,
    DateTime? to,
  ) {
    if (from == null || to == null) {
      return _repository.findAllCounted();
    }
    return _repository.findByDateRange(from, to);
  }

  DateTime _anchorDay(DateTime? from, DateTime? to) {
    final raw = to ?? DateTime.now();
    return DateTime(raw.year, raw.month, raw.day);
  }

  int _currentStreak({
    required List<FocusSession> sessions,
    required DateTime anchorDay,
  }) {
    final completedDays = _completedDaySet(sessions);
    var cursor = anchorDay;
    var streak = 0;

    while (completedDays.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _longestStreak(List<FocusSession> sessions) {
    final orderedDays = _completedDaySet(sessions).toList()..sort();
    if (orderedDays.isEmpty) return 0;

    var longest = 1;
    var current = 1;

    for (var index = 1; index < orderedDays.length; index++) {
      final previous = DateTime.parse(orderedDays[index - 1]);
      final currentDay = DateTime.parse(orderedDays[index]);
      final gap = currentDay.difference(previous).inDays;
      if (gap == 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > longest) {
        longest = current;
      }
    }

    return longest;
  }

  Set<String> _completedDaySet(List<FocusSession> sessions) {
    return sessions
        .where((session) => session.status == SessionStatus.completed)
        .map((session) => _dayKey(session.startAt))
        .toSet();
  }

  String _dayKey(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return normalized.toIso8601String();
  }

  T? _topEntry<T>(Map<T, int> values) {
    if (values.isEmpty) return null;

    T? bestKey;
    var bestCount = -1;
    for (final entry in values.entries) {
      if (entry.value > bestCount) {
        bestKey = entry.key;
        bestCount = entry.value;
      }
    }
    return bestKey;
  }

  int? _bestHour(Map<int, double> hourDurations) {
    if (hourDurations.isEmpty) return null;

    var bestHour = 0;
    var bestDuration = -1.0;
    for (final entry in hourDurations.entries) {
      if (entry.value > bestDuration) {
        bestHour = entry.key;
        bestDuration = entry.value;
      }
    }
    return bestHour;
  }
}

class _DayAccumulator {
  final DateTime date;
  double totalDuration = 0;
  int count = 0;
  _DayAccumulator(this.date);
}
