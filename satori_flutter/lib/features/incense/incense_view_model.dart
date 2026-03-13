import 'dart:async';
import 'package:flutter/foundation.dart';

/// 焚香 ViewModel（倒计时 + 正计时）
class IncenseViewModel extends ChangeNotifier {
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
    (label: '一炷香',  minutes: 25),
    (label: '一炷长香', minutes: 45),
    (label: '一坐禅',  minutes: 60),
  ];

  Timer? _timer;
  DateTime? _startDate;
  double _pauseAccumulated = 0;

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
    }

    _startDate = DateTime.now();
    state = TimerState.running;
    notifyListeners();

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

  void reset() {
    state = TimerState.idle;
    _timer?.cancel();
    if (timerMode == TimerMode.countdown) {
      remainingTime = totalDuration;
    }
    elapsedTime = 0;
    burnProgress = 0;
    _pauseAccumulated = 0;
    _startDate = null;
    notifyListeners();
  }

  void switchMode(TimerMode mode) {
    if (mode == timerMode) return;
    if (state != TimerState.idle) reset();
    timerMode = mode;
    notifyListeners();
  }

  // 后台补偿：外部调用
  void compensateBackground(Duration elapsed) {
    if (state != TimerState.running) return;
    _pauseAccumulated += elapsed.inMilliseconds / 1000.0;
  }

  // MARK: - Tick

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
      }
    } else {
      elapsedTime = elapsed;
      burnProgress = (elapsed / 3600).clamp(0, 1); // 60 分钟一循环
    }
    notifyListeners();
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
      return '${hrs}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

enum TimerMode { countdown, countUp }

enum TimerState { idle, running, paused, completed }
