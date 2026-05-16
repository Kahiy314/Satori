import 'package:flutter_test/flutter_test.dart';
import 'package:satori/core/models/focus_session.dart';
import 'package:satori/core/models/focus_constants.dart';
import 'package:satori/services/local_stats_aggregator.dart';
import 'package:satori/services/session_repository.dart';

/// In-memory mock repository for testing （不依赖 shared_preferences）。
class InMemorySessionRepository implements SessionRepository {
  final List<FocusSession> _sessions = [];

  @override
  Future<void> save(FocusSession session) async {
    final idx = _sessions.indexWhere((s) => s.sessionId == session.sessionId);
    if (idx >= 0) {
      _sessions[idx] = session;
    } else {
      _sessions.add(session);
    }
  }

  @override
  Future<FocusSession?> findById(String sessionId) async {
    try {
      return _sessions.firstWhere((s) => s.sessionId == sessionId);
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<FocusSession>> findAllCounted() async {
    return _sessions.where((s) => s.isCountedInHistory).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  @override
  Future<List<FocusSession>> findByDateRange(DateTime from, DateTime to) async {
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return _sessions
        .where((s) =>
            s.isCountedInHistory &&
            !s.startAt.isBefore(fromDay) &&
            !s.startAt.isAfter(toDay))
        .toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  @override
  Future<List<FocusSession>> findUncounted() async {
    return _sessions.where((s) => !s.isCountedInHistory).toList();
  }

  @override
  Future<void> delete(String sessionId) async {
    _sessions.removeWhere((s) => s.sessionId == sessionId);
  }

  @override
  Future<int> count() async => _sessions.length;
}

void main() {
  group('FocusSession 模型', () {
    test('JSON 往返序列化保持一致', () {
      final session = FocusSession(
        sessionId: 'test_1',
        startAt: DateTime(2026, 3, 16, 10, 0),
        endAt: DateTime(2026, 3, 16, 10, 25),
        plannedDuration: 1500,
        actualDuration: 1500,
        mode: FocusMode.countdown,
        status: SessionStatus.completed,
        createdAt: DateTime(2026, 3, 16, 9, 59),
        trustLevel: 'client_reported',
        serverScore: 4,
        taskTag: '写代码',
        summaryNote: '很专注',
        reflectionMood: ReflectionMood.focused,
        isCountedInHistory: true,
      );

      final json = session.toJson();
      final restored = FocusSession.fromJson(json);

      expect(restored.sessionId, session.sessionId);
      expect(restored.startAt, session.startAt);
      expect(restored.endAt, session.endAt);
      expect(restored.plannedDuration, session.plannedDuration);
      expect(restored.actualDuration, session.actualDuration);
      expect(restored.mode, session.mode);
      expect(restored.status, session.status);
      expect(restored.trustLevel, 'client_reported');
      expect(restored.serverScore, 4);
      expect(restored.taskTag, '写代码');
      expect(restored.summaryNote, '很专注');
      expect(restored.reflectionMood, ReflectionMood.focused);
      expect(restored.isCountedInHistory, true);
    });

    test('copyWith 不可变更新', () {
      final session = FocusSession(
        sessionId: 'test_2',
        startAt: DateTime(2026, 3, 16, 10, 0),
        actualDuration: 60,
        mode: FocusMode.countUp,
        status: SessionStatus.abandoned,
        createdAt: DateTime(2026, 3, 16, 10, 0),
      );

      final updated = session.copyWith(
        trustLevel: 'server_verified',
        serverScore: 9,
        summaryNote: '有点分心',
        reflectionMood: ReflectionMood.distracted,
      );

      expect(updated.trustLevel, 'server_verified');
      expect(updated.serverScore, 9);
      expect(updated.summaryNote, '有点分心');
      expect(updated.reflectionMood, ReflectionMood.distracted);
      expect(updated.sessionId, session.sessionId);
      expect(session.summaryNote, isNull); // 原对象不变
    });
  });

  group('SessionRepository', () {
    late InMemorySessionRepository repo;

    setUp(() {
      repo = InMemorySessionRepository();
    });

    test('save 和 findById', () async {
      final session =
          _makeSession('s1', duration: 600, status: SessionStatus.completed);
      await repo.save(session);
      final found = await repo.findById('s1');
      expect(found, isNotNull);
      expect(found!.sessionId, 's1');
    });

    test('save 更新已有记录', () async {
      final session =
          _makeSession('s1', duration: 600, status: SessionStatus.completed);
      await repo.save(session);
      final updated = session.copyWith(summaryNote: '更新备注');
      await repo.save(updated);
      final found = await repo.findById('s1');
      expect(found!.summaryNote, '更新备注');
      expect(await repo.count(), 1);
    });

    test('findAllCounted 过滤未计入历史的会话', () async {
      await repo.save(_makeSession('s1', duration: 600, counted: true));
      await repo.save(_makeSession('s2', duration: 30, counted: false));
      await repo.save(_makeSession('s3', duration: 900, counted: true));

      final counted = await repo.findAllCounted();
      expect(counted.length, 2);
      expect(counted.every((s) => s.isCountedInHistory), true);
    });

    test('findUncounted 返回未计入的', () async {
      await repo.save(_makeSession('s1', duration: 600, counted: true));
      await repo.save(_makeSession('s2', duration: 30, counted: false));

      final uncounted = await repo.findUncounted();
      expect(uncounted.length, 1);
      expect(uncounted.first.sessionId, 's2');
    });

    test('delete 删除', () async {
      await repo.save(_makeSession('s1', duration: 600));
      await repo.delete('s1');
      expect(await repo.findById('s1'), isNull);
      expect(await repo.count(), 0);
    });

    test('findByDateRange 按日期范围过滤', () async {
      await repo.save(_makeSession('s1',
          duration: 600, start: DateTime(2026, 3, 14, 10, 0)));
      await repo.save(_makeSession('s2',
          duration: 600, start: DateTime(2026, 3, 15, 10, 0)));
      await repo.save(_makeSession('s3',
          duration: 600, start: DateTime(2026, 3, 16, 10, 0)));

      final result = await repo.findByDateRange(
        DateTime(2026, 3, 15),
        DateTime(2026, 3, 15),
      );
      expect(result.length, 1);
      expect(result.first.sessionId, 's2');
    });
  });

  group('StatsAggregator', () {
    late InMemorySessionRepository repo;
    late LocalStatsAggregator agg;

    setUp(() {
      repo = InMemorySessionRepository();
      agg = LocalStatsAggregator(repo);
    });

    test('空仓库返回 empty', () async {
      final overview = await agg.overview();
      expect(overview.totalSessions, 0);
      expect(overview.totalDuration, 0);
    });

    test('completed / abandoned / interrupted 统计正确', () async {
      await repo.save(_makeSession('s1',
          duration: 1500,
          status: SessionStatus.completed,
        taskTag: '写作',
        mood: ReflectionMood.focused,
          start: DateTime(2026, 3, 16, 10, 0)));
      await repo.save(_makeSession('s2',
          duration: 600,
          status: SessionStatus.abandoned,
        taskTag: '写作',
          start: DateTime(2026, 3, 16, 14, 0)));
      await repo.save(_makeSession('s3',
          duration: 300,
          status: SessionStatus.interrupted,
        mood: ReflectionMood.distracted,
          start: DateTime(2026, 3, 15, 9, 0)));

      final overview = await agg.overview();
      expect(overview.totalSessions, 3);
      expect(overview.totalDuration, 1500 + 600 + 300);
      expect(overview.totalDays, 2); // 3.15 和 3.16
      expect(overview.abandonedCount, 2); // abandoned + interrupted
      expect(overview.avgDuration, 1500); // 仅 completed 的平均
      expect(overview.avgAbandonedDuration, (600 + 300) / 2);
      expect(overview.completedSessions, 1);
      expect(overview.completionRate, closeTo(1 / 3, 0.0001));
      expect(overview.longestSessionDuration, 1500);
      expect(overview.bestFocusHour, 10);
      expect(overview.topTag, '写作');
      expect(overview.topMood, ReflectionMood.focused);
    });

    test('低于阈值的会话不进入统计', () async {
      // 短时会话（60s < 120s 阈值），isCountedInHistory = false
      await repo.save(_makeSession('short', duration: 60, counted: false));
      await repo.save(_makeSession('normal', duration: 1500, counted: true));

      final overview = await agg.overview();
      expect(overview.totalSessions, 1);
      expect(overview.totalDuration, 1500);
    });

    test('dailyStats 填充零值日期', () async {
      await repo.save(_makeSession('s1',
          duration: 600, start: DateTime(2026, 3, 14, 10, 0)));
      // 3.15 无记录
      await repo.save(_makeSession('s2',
          duration: 900, start: DateTime(2026, 3, 16, 10, 0)));

      final daily = await agg.dailyStats(
        DateTime(2026, 3, 14),
        DateTime(2026, 3, 16),
      );
      expect(daily.length, 3);
      expect(daily[0].totalDuration, 600); // 3.14
      expect(daily[1].totalDuration, 0); // 3.15 zero-fill
      expect(daily[2].totalDuration, 900); // 3.16
    });

    test('overview 支持按范围计算连续天数和最长连续天数', () async {
      await repo.save(_makeSession('s1',
          duration: 1500,
          status: SessionStatus.completed,
          start: DateTime(2026, 3, 14, 9, 0)));
      await repo.save(_makeSession('s2',
          duration: 1500,
          status: SessionStatus.completed,
          start: DateTime(2026, 3, 15, 9, 0)));
      await repo.save(_makeSession('s3',
          duration: 1500,
          status: SessionStatus.completed,
          start: DateTime(2026, 3, 16, 9, 0)));
      await repo.save(_makeSession('gap',
          duration: 1500,
          status: SessionStatus.completed,
          start: DateTime(2026, 3, 18, 9, 0)));

      final overview = await agg.overview(
        from: DateTime(2026, 3, 14),
        to: DateTime(2026, 3, 16),
      );

      expect(overview.currentStreak, 3);
      expect(overview.longestStreak, 3);
    });

    test('sessionsInRange 返回闭区间内的会话', () async {
      await repo.save(_makeSession('s1',
          duration: 600, start: DateTime(2026, 3, 14, 10, 0)));
      await repo.save(_makeSession('s2',
          duration: 600, start: DateTime(2026, 3, 15, 10, 0)));
      await repo.save(_makeSession('s3',
          duration: 600, start: DateTime(2026, 3, 16, 10, 0)));

      final sessions = await agg.sessionsInRange(
        DateTime(2026, 3, 15),
        DateTime(2026, 3, 16),
      );

      expect(sessions.length, 2);
      expect(sessions.first.sessionId, 's3');
      expect(sessions.last.sessionId, 's2');
    });

    test('sessionsForDay 返回当天会话', () async {
      await repo.save(_makeSession('s1',
          duration: 600, start: DateTime(2026, 3, 16, 10, 0)));
      await repo.save(_makeSession('s2',
          duration: 600, start: DateTime(2026, 3, 16, 14, 0)));
      await repo.save(_makeSession('s3',
          duration: 600, start: DateTime(2026, 3, 15, 10, 0)));

      final sessions = await agg.sessionsForDay(DateTime(2026, 3, 16));
      expect(sessions.length, 2);
    });

    test('跨天边界验证', () async {
      // 23:50 开始，0:10 结束的会话
      await repo.save(_makeSession('cross',
          duration: 1200, start: DateTime(2026, 3, 15, 23, 50)));

      // 按 startAt 日期归属 3.15
      final daily15 = await agg.sessionsForDay(DateTime(2026, 3, 15));
      final daily16 = await agg.sessionsForDay(DateTime(2026, 3, 16));
      expect(daily15.length, 1);
      expect(daily16.length, 0);
    });
  });

  group('FocusConstants', () {
    test('最短有效专注阈值为 120 秒', () {
      expect(FocusConstants.minEffectiveDurationSeconds, 120);
    });
  });
}

FocusSession _makeSession(
  String id, {
  double duration = 600,
  SessionStatus status = SessionStatus.completed,
  DateTime? start,
  bool counted = true,
  String? taskTag,
  ReflectionMood? mood,
}) {
  final startAt = start ?? DateTime(2026, 3, 16, 10, 0);
  return FocusSession(
    sessionId: id,
    startAt: startAt,
    endAt: startAt.add(Duration(seconds: duration.toInt())),
    actualDuration: duration,
    mode: FocusMode.countdown,
    status: status,
    createdAt: startAt,
    taskTag: taskTag,
    reflectionMood: mood,
    isCountedInHistory: counted,
  );
}
