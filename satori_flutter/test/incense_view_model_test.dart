import 'package:flutter_test/flutter_test.dart';
import 'package:satori/features/incense/incense_view_model.dart';
import 'package:satori/core/models/focus_session.dart';
import 'package:satori/core/models/focus_constants.dart';
import 'package:satori/services/session_repository.dart';
import 'package:satori/services/user_preferences.dart';

/// In-memory mock repository
class _MockRepo implements SessionRepository {
  final List<FocusSession> saved = [];

  @override
  Future<void> save(FocusSession session) async => saved.add(session);
  @override
  Future<FocusSession?> findById(String id) async => null;
  @override
  Future<List<FocusSession>> findAllCounted() async => [];
  @override
  Future<List<FocusSession>> findByDateRange(DateTime f, DateTime t) async => [];
  @override
  Future<List<FocusSession>> findUncounted() async => [];
  @override
  Future<void> delete(String id) async {}
  @override
  Future<int> count() async => saved.length;
}

class _MockPrefs implements UserPreferences {
  bool dismissed = false;
  final List<String> tags = [];

  @override
  Future<bool> isShortFocusPromptDismissed() async => dismissed;
  @override
  Future<void> setShortFocusPromptDismissed(bool d) async => dismissed = d;
  @override
  Future<List<String>> recentTags() async => tags;
  @override
  Future<void> addRecentTag(String tag) async => tags.add(tag);
}

void main() {
  group('IncenseViewModel 生命周期事件', () {
    late _MockRepo repo;
    late _MockPrefs prefs;
    late IncenseViewModel vm;

    setUp(() {
      repo = _MockRepo();
      prefs = _MockPrefs();
      vm = IncenseViewModel(
        sessionRepository: repo,
        userPreferences: prefs,
      );
    });

    tearDown(() {
      vm.dispose();
    });

    test('start 创建会话', () {
      vm.start();
      expect(vm.state, TimerState.running);
    });

    test('reset 在 running 时触发 abandoned', () async {
      final events = <IncenseSessionEvent>[];
      vm.sessionEvents.listen(events.add);

      vm.start();
      // 等待一小段时间让 tick 运行
      await Future.delayed(const Duration(milliseconds: 200));
      vm.reset();

      // 等事件分发
      await Future.delayed(const Duration(milliseconds: 100));

      expect(vm.state, TimerState.idle);
      expect(events, contains(IncenseSessionEvent.abandoned));
      expect(repo.saved.isNotEmpty, true);
      expect(repo.saved.last.status, SessionStatus.abandoned);
    });

    test('markInterrupted 触发 interrupted', () async {
      final events = <IncenseSessionEvent>[];
      vm.sessionEvents.listen(events.add);

      vm.start();
      await Future.delayed(const Duration(milliseconds: 200));
      vm.markInterrupted();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(events, contains(IncenseSessionEvent.interrupted));
      expect(repo.saved.last.status, SessionStatus.interrupted);
    });

    test('短时专注（低于阈值）标记为未计入历史', () async {
      // 使用 1 秒倒计时（远低于 120s 阈值）
      vm.selectPreset(1); // 1 分钟 = 60s
      vm.start();
      await Future.delayed(const Duration(milliseconds: 200));
      vm.reset();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(repo.saved.isNotEmpty, true);
      // 实际时长 ~200ms，远低于阈值
      expect(repo.saved.last.isCountedInHistory, false);
    });

    test('任务标签保存正确', () async {
      vm.setTaskTag('阅读');
      vm.start();
      await Future.delayed(const Duration(milliseconds: 200));
      vm.reset();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(repo.saved.last.taskTag, '阅读');
      expect(prefs.tags, contains('阅读'));
    });

    test('updateSessionSummary 更新最后完成的会话', () async {
      vm.start();
      await Future.delayed(const Duration(milliseconds: 200));
      vm.reset();
      await Future.delayed(const Duration(milliseconds: 100));

      await vm.updateSessionSummary(
        summaryNote: '今天很专注',
        reflectionMood: ReflectionMood.focused,
      );

      expect(vm.lastFinishedSession!.summaryNote, '今天很专注');
      expect(vm.lastFinishedSession!.reflectionMood, ReflectionMood.focused);
    });

    test('正计时 stopCountUp 触发 completed', () async {
      final events = <IncenseSessionEvent>[];
      vm.sessionEvents.listen(events.add);

      vm.switchMode(TimerMode.countUp);
      vm.start();
      await Future.delayed(const Duration(milliseconds: 200));
      vm.stopCountUp();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(events, contains(IncenseSessionEvent.completed));
      expect(repo.saved.last.status, SessionStatus.completed);
      expect(repo.saved.last.mode, FocusMode.countUp);
    });
  });
}
