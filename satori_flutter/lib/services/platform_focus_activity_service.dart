import 'package:flutter/services.dart';
import 'focus_activity_service.dart';

/// 基于平台通道的 [FocusActivityService] 实现。
///
/// iOS 端对接 ActivityKit（Live Activity），
/// Android 端对接通知栏前台服务。
/// 若平台不支持或调用失败，静默降级。
class PlatformFocusActivityService implements FocusActivityService {
  static const _channel = MethodChannel('dev.satori/focus_activity');

  bool _isActive = false;

  @override
  bool get isActive => _isActive;

  @override
  Future<void> startActivity({
    required bool isCountdown,
    double? totalSeconds,
  }) async {
    try {
      await _channel.invokeMethod('startActivity', {
        'isCountdown': isCountdown,
        'totalSeconds': totalSeconds,
      });
      _isActive = true;
    } on PlatformException {
      // 平台不支持，静默降级
      _isActive = false;
    } on MissingPluginException {
      _isActive = false;
    }
  }

  @override
  Future<void> updateActivity({required double remainingOrElapsed}) async {
    if (!_isActive) return;
    try {
      await _channel.invokeMethod('updateActivity', {
        'remainingOrElapsed': remainingOrElapsed,
      });
    } on PlatformException {
      // 降级
    }
  }

  @override
  Future<void> stopActivity() async {
    if (!_isActive) return;
    try {
      await _channel.invokeMethod('stopActivity');
    } on PlatformException {
      // 降级
    } finally {
      _isActive = false;
    }
  }
}
