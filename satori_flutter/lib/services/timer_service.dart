import 'package:flutter/widgets.dart';

/// 计时器服务
/// 后台保活 + 精度补偿
class TimerService with WidgetsBindingObserver {
  TimerService._();
  static final instance = TimerService._();

  DateTime? _backgroundDate;

  /// 后台经过时间补偿回调
  void Function(Duration elapsed)? onBackgroundCompensation;

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundDate = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        if (_backgroundDate != null) {
          final elapsed = DateTime.now().difference(_backgroundDate!);
          _backgroundDate = null;
          onBackgroundCompensation?.call(elapsed);
        }
        break;
      default:
        break;
    }
  }
}
