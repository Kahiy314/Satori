/// 系统媒体会话接口 — Phase P6。
///
/// 为听雨与抚琴的后台播放提供系统级媒体提示能力。
/// 支持基础的播放、暂停、曲目或进度状态同步。
abstract class MediaSessionService {
  /// 更新系统媒体会话的元数据。
  Future<void> updateMetadata({
    required String title,
    String? artist,
    Duration? duration,
  });

  /// 更新播放状态。
  Future<void> updatePlaybackState({
    required bool isPlaying,
    Duration? position,
  });

  /// 释放媒体会话。
  Future<void> release();

  /// 设置播放/暂停回调（系统媒体控制按钮触发）。
  void onPlayPauseRequested(void Function() callback);

  /// 设置停止回调。
  void onStopRequested(void Function() callback);

  /// 设置下一曲回调。
  void onNextRequested(void Function() callback);
}
