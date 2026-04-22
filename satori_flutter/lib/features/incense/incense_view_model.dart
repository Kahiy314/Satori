import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/models/focus_session.dart';
import '../../core/models/focus_constants.dart';
import '../../services/focus_activity_service.dart';
import '../../services/session_repository.dart';
import '../../services/user_preferences.dart';

/// 焚香会话生命周期事件，供外部监听做 UI 响应。
enum IncenseSessionEvent {
  /// 倒计时正常完成
  completed,

  /// 用户主动放弃（running / paused 时重置）
  abandoned,

  /// 系统异常中断（后台恢复失败等）
  interrupted,

  /// 短时专注触发提示
  shortFocusPrompt,
}

/// 焚香 ViewModel（倒计时 + 正计时）
class IncenseViewModel extends ChangeNotifier {
  IncenseViewModel({
    SessionRepository? sessionRepository,
    UserPreferences? userPreferences,
    FocusActivityService? focusActivityService,
  })  : _sessionRepository = sessionRepository,
        _userPreferences = userPreferences,
        _focusActivityService = focusActivityService;

  final SessionRepository? _sessionRepository;
  final UserPreferences? _userPreferences;
  final FocusActivityService? _focusActivityService;

  // ── 计时模式 ──
  TimerMode timerMode = TimerMode.countdown;

  // ── 状态 ──
  TimerState state = TimerState.idle;

  double totalDuration = 25 * 60; // seconds
  double remainingTime = 25 * 60;
  double elapsedTime = 0;
  double burnProgress = 0; // 0 → 1

  // ── 自定义时长 ──
  bool showCustomDuration = false;
  int customMinutes = 25;

  static const minMinutes = 1;
  static const maxMinutes = 120;

  // ── 预设时长 ──
  static const presets = [
    (label: '一炷短香', minutes: 15),
    (label: '一炷香', minutes: 25),
    (label: '一炷长香', minutes: 45),
    (label: '一坐禅', minutes: 60),
  ];

  Timer? _timer;
  DateTime? _startDate;
  double _pauseAccumulated = 0;

  // ── 会话跟踪 ── Phase P2
  FocusSession? _currentSession;
  DateTime? _sessionStartAt;
  String? _currentTaskTag;

  /// 最近一次完成 / 放弃 / 中断的会话，供小结页使用。
  FocusSession? lastFinishedSession;

  /// 事件流：UI 层订阅用于弹出小结 / 短时提示等。
  final _eventController = StreamController<IncenseSessionEvent>.broadcast();
  Stream<IncenseSessionEvent> get sessionEvents => _eventController.stream;

  /// 当前任务标签
  String? get currentTaskTag => _currentTaskTag;

  /// 设置任务标签（开始前或进行中均可打标签）
  void setTaskTag(String? tag) {
    _currentTaskTag = tag;
    notifyListeners();
  }

  // MARK: - 自定义时长

  void applyCustomDuration() {
    if (state != TimerState.idle) return;
    final mins = customMinutes.clamp(minMinutes, maxMinutes);
    totalDuration = mins * 60.0;
    remainingTime = totalDuration;
    notifyListeners();
  }

  // MARK: - Actions

  void selectPreset(int minutes) {
    if (state != TimerState.idle) return;
    totalDuration = minutes * 60.0;
    remainingTime = totalDuration;
    burnProgress = 0;
    notifyListeners();
  }

  void start() {
    if (state != TimerState.idle && state != TimerState.paused) return;

    if (state == TimerState.idle) {
      if (timerMode == TimerMode.countdown) {
        remainingTime = totalDuration;
      } else {
        elapsedTime = 0;
      }
      _pauseAccumulated = 0;
      burnProgress = 0;

      // ── 创建新会话 ──
      _sessionStartAt = DateTime.now();
      _currentSession = FocusSession(
        sessionId: _generateSessionId(),
        startAt: _sessionStartAt!,
        actualDuration: 0,
        mode: timerMode == TimerMode.countdown
            ? FocusMode.countdown
            : FocusMode.countUp,
        status: SessionStatus.completed, // 临时，终态在结束时更新
        createdAt: _sessionStartAt!,
        plannedDuration:
            timerMode == TimerMode.countdown ? totalDuration : null,
        taskTag: _currentTaskTag,
      );
    }

    _startDate = DateTime.now();
    state = TimerState.running;
    notifyListeners();

    // ── 后台可见性 ──
    _focusActivityService?.startActivity(
      isCountdown: timerMode == TimerMode.countdown,
      totalSeconds: timerMode == TimerMode.countdown ? totalDuration : null,
    );

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void pause() {
    if (state != TimerState.running) return;
    state = TimerState.paused;
    if (_startDate != null) {
      _pauseAccumulated +=
          DateTime.now().difference(_startDate!).inMilliseconds / 1000.0;
    }
    _timer?.cancel();
    notifyListeners();
  }

  /// 用户主动放弃 → abandoned
  void reset() {
    if (state == TimerState.running || state == TimerState.paused) {
      _finalizeSession(SessionStatus.abandoned);
    }

    state = TimerState.idle;
    _timer?.cancel();
    if (timerMode == TimerMode.countdown) {
      remainingTime = totalDuration;
    }
    elapsedTime = 0;
    burnProgress = 0;
    _pauseAccumulated = 0;
    _startDate = null;
    _sessionStartAt = null;
    notifyListeners();
  }

  /// 正计时模式下用户主动停止 → completed
  void stopCountUp() {
    if (state != TimerState.running && state != TimerState.paused) return;
    if (timerMode != TimerMode.countUp) return;
    _timer?.cancel();
    state = TimerState.completed;
    _finalizeSession(SessionStatus.completed);
    notifyListeners();
  }

  /// 倒计时模式下用户主动完成本次专注 → completed
  void completeCountdown() {
    if (state != TimerState.running && state != TimerState.paused) return;
    if (timerMode != TimerMode.countdown) return;
    if (_startDate != null && state == TimerState.paused) {
      _startDate = DateTime.now();
    }
    _timer?.cancel();
    state = TimerState.completed;
    _finalizeSession(SessionStatus.completed);
    notifyListeners();
  }

  void switchMode(TimerMode mode) {
    if (mode == timerMode) return;
    if (state != TimerState.idle) reset();
    timerMode = mode;
    notifyListeners();
  }

  /// 后台补偿：外部调用
  void compensateBackground(Duration elapsed) {
    if (state != TimerState.running) return;
    _pauseAccumulated += elapsed.inMilliseconds / 1000.0;
  }

  /// 后台恢复失败 → interrupted
  void markInterrupted() {
    if (state != TimerState.running && state != TimerState.paused) return;
    _timer?.cancel();
    _finalizeSession(SessionStatus.interrupted);
    state = TimerState.idle;
    _resetTimerValues();
    notifyListeners();
  }

  // MARK: - Tick

  int _activityUpdateCounter = 0;

  void _tick() {
    if (_startDate == null) return;
    final elapsed = _pauseAccumulated +
        DateTime.now().difference(_startDate!).inMilliseconds / 1000.0;

    if (timerMode == TimerMode.countdown) {
      remainingTime = (totalDuration - elapsed).clamp(0, totalDuration);
      burnProgress = (elapsed / totalDuration).clamp(0, 1);
      if (remainingTime <= 0) {
        state = TimerState.completed;
        _timer?.cancel();
        _finalizeSession(SessionStatus.completed);
      }
    } else {
      elapsedTime = elapsed;
      burnProgress = (elapsed / 3600).clamp(0, 1); // 60 分钟一循环
    }

    // 每 ~1 秒更新后台可见性（20 ticks × 50ms）
    _activityUpdateCounter++;
    if (_activityUpdateCounter >= 20) {
      _activityUpdateCounter = 0;
      _focusActivityService?.updateActivity(
        remainingOrElapsed:
            timerMode == TimerMode.countdown ? remainingTime : elapsedTime,
      );
    }

    notifyListeners();
  }

  // MARK: - 会话落账 (Phase P2)

  /// 当前实际已专注时间（秒）
  double get _currentActualDuration {
    if (timerMode == TimerMode.countdown) {
      return totalDuration - remainingTime;
    }
    return elapsedTime;
  }

  /// 判定是否低于最短有效阈值
  bool get _isBelowMinThreshold =>
      _currentActualDuration < FocusConstants.minEffectiveDurationSeconds;

  /// 结束会话并落账
  Future<void> _finalizeSession(SessionStatus status) async {
    if (_currentSession == null || _sessionStartAt == null) return;

    // 停止后台可见性
    _focusActivityService?.stopActivity();

    final now = DateTime.now();
    final actualDuration = _currentActualDuration;
    final isCounted = !_isBelowMinThreshold;

    final session = _currentSession!.copyWith(
      endAt: now,
      actualDuration: actualDuration,
      status: status,
      taskTag: _currentTaskTag,
      isCountedInHistory: isCounted,
    );

    lastFinishedSession = session;
    _currentSession = null;

    // 持久化
    await _sessionRepository?.save(session);

    // 保存标签到最近列表
    if (_currentTaskTag != null && _currentTaskTag!.isNotEmpty) {
      await _userPreferences?.addRecentTag(_currentTaskTag!);
    }

    // 事件分发
    if (!isCounted && status != SessionStatus.interrupted) {
      // 短时专注：先检查用户是否关闭了提示
      final dismissed =
          await _userPreferences?.isShortFocusPromptDismissed() ?? false;
      if (!dismissed) {
        _eventController.add(IncenseSessionEvent.shortFocusPrompt);
      }
    }

    // 根据终态分发事件
    switch (status) {
      case SessionStatus.completed:
        _eventController.add(IncenseSessionEvent.completed);
        break;
      case SessionStatus.abandoned:
        _eventController.add(IncenseSessionEvent.abandoned);
        break;
      case SessionStatus.interrupted:
        _eventController.add(IncenseSessionEvent.interrupted);
        break;
    }

    _currentTaskTag = null;
  }

  /// 为小结页更新备注和感受
  Future<void> updateSessionSummary({
    String? summaryNote,
    ReflectionMood? reflectionMood,
  }) async {
    if (lastFinishedSession == null) return;
    lastFinishedSession = lastFinishedSession!.copyWith(
      summaryNote: summaryNote,
      reflectionMood: reflectionMood,
    );
    await _sessionRepository?.save(lastFinishedSession!);
  }

  void _resetTimerValues() {
    if (timerMode == TimerMode.countdown) {
      remainingTime = totalDuration;
    }
    elapsedTime = 0;
    burnProgress = 0;
    _pauseAccumulated = 0;
    _startDate = null;
    _sessionStartAt = null;
  }

  static int _idCounter = 0;
  String _generateSessionId() {
    _idCounter++;
    return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  // MARK: - Formatted Time

  String get formattedTime {
    final seconds = timerMode == TimerMode.countdown
        ? remainingTime.toInt()
        : elapsedTime.toInt();
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hrs > 0) {
      return '$hrs:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _eventController.close();
    super.dispose();
  }
}

enum TimerMode { countdown, countUp }

enum TimerState { idle, running, paused, completed }
