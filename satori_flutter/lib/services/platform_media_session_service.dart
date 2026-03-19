import 'package:flutter/services.dart';
import 'media_session_service.dart';

/// 基于平台通道的 [MediaSessionService] 实现。
///
/// iOS 端对接 MPNowPlayingInfoCenter / MPRemoteCommandCenter，
/// Android 端对接 MediaSession。
class PlatformMediaSessionService implements MediaSessionService {
  static const _channel = MethodChannel('dev.satori/media_session');

  void Function()? _onPlayPause;
  void Function()? _onStop;
  void Function()? _onNext;

  PlatformMediaSessionService() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onPlayPause':
        _onPlayPause?.call();
        break;
      case 'onStop':
        _onStop?.call();
        break;
      case 'onNext':
        _onNext?.call();
        break;
    }
  }

  @override
  Future<void> updateMetadata({
    required String title,
    String? artist,
    Duration? duration,
  }) async {
    try {
      await _channel.invokeMethod('updateMetadata', {
        'title': title,
        'artist': artist,
        'durationMs': duration?.inMilliseconds,
      });
    } on PlatformException {
      // 平台不支持，静默降级
    } on MissingPluginException {
      // 未实现
    }
  }

  @override
  Future<void> updatePlaybackState({
    required bool isPlaying,
    Duration? position,
  }) async {
    try {
      await _channel.invokeMethod('updatePlaybackState', {
        'isPlaying': isPlaying,
        'positionMs': position?.inMilliseconds,
      });
    } on PlatformException {
      // 降级
    } on MissingPluginException {
      // 未实现
    }
  }

  @override
  Future<void> release() async {
    try {
      await _channel.invokeMethod('release');
    } on PlatformException {
      // 降级
    } on MissingPluginException {
      // 未实现
    }
  }

  @override
  void onPlayPauseRequested(void Function() callback) {
    _onPlayPause = callback;
  }

  @override
  void onStopRequested(void Function() callback) {
    _onStop = callback;
  }

  @override
  void onNextRequested(void Function() callback) {
    _onNext = callback;
  }
}
