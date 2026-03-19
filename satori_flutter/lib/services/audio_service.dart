import 'package:audioplayers/audioplayers.dart';
import 'media_session_service.dart';

/// 音频服务
/// 统一管理白噪音和音乐播放，支持多音源叠加 + 交叉淡化
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  /// 可选的系统媒体会话服务（Phase P6）。
  /// 调用者在初始化时注入，听雨和抚琴后台播放时自动同步。
  MediaSessionService? mediaSession;

  // ── 白噪音播放器（可叠加多个）──
  final Map<String, AudioPlayer> _ambientPlayers = {};

  // ── 音乐播放器 ──
  AudioPlayer? _musicPlayer;
  bool isMusicPlaying = false;

  // MARK: - 白噪音

  Future<void> playAmbient(String fileName, {double volume = 0.5}) async {
    if (_ambientPlayers.containsKey(fileName)) return;

    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(0);
    await player.play(AssetSource('audio/$fileName.mp3'));
    _ambientPlayers[fileName] = player;

    // 渐入
    _fadeIn(player, targetVolume: volume, duration: const Duration(seconds: 2));
  }

  Future<void> stopAmbient(String fileName) async {
    final player = _ambientPlayers[fileName];
    if (player == null) return;

    await _fadeOut(player, duration: const Duration(milliseconds: 1500));
    await player.stop();
    await player.dispose();
    _ambientPlayers.remove(fileName);
  }

  Future<void> setAmbientVolume(String fileName, double volume) async {
    await _ambientPlayers[fileName]?.setVolume(volume);
  }

  Future<void> stopAllAmbient() async {
    for (final entry in _ambientPlayers.entries.toList()) {
      await _fadeOut(entry.value, duration: const Duration(seconds: 1));
      await entry.value.stop();
      await entry.value.dispose();
    }
    _ambientPlayers.clear();
  }

  // MARK: - 音乐

  Future<void> playMusic(String fileName, {String? title, String? artist, Duration? duration}) async {
    await _musicPlayer?.stop();
    await _musicPlayer?.dispose();

    _musicPlayer = AudioPlayer();
    await _musicPlayer!.setVolume(0);
    await _musicPlayer!.play(AssetSource('audio/$fileName.mp3'));
    isMusicPlaying = true;
    _fadeIn(_musicPlayer!, targetVolume: 1.0, duration: const Duration(milliseconds: 1500));

    // 同步系统媒体会话
    mediaSession?.updateMetadata(
      title: title ?? fileName,
      artist: artist,
      duration: duration,
    );
    mediaSession?.updatePlaybackState(isPlaying: true);
  }

  Future<void> toggleMusicPlayPause() async {
    final player = _musicPlayer;
    if (player == null) return;

    if (isMusicPlaying) {
      await player.pause();
      isMusicPlaying = false;
    } else {
      await player.resume();
      isMusicPlaying = true;
    }
    mediaSession?.updatePlaybackState(isPlaying: isMusicPlaying);
  }

  Future<void> stopMusic() async {
    final player = _musicPlayer;
    if (player == null) return;

    await _fadeOut(player, duration: const Duration(seconds: 1));
    await player.stop();
    isMusicPlaying = false;
    mediaSession?.updatePlaybackState(isPlaying: false);
    mediaSession?.release();
  }

  Future<void> seekMusic(Duration position) async {
    await _musicPlayer?.seek(position);
  }

  Duration? get musicPosition => null; // Retrived via stream
  Stream<Duration>? get musicPositionStream => _musicPlayer?.onPositionChanged;
  Stream<void>? get musicCompleteStream => _musicPlayer?.onPlayerComplete;

  // MARK: - 交叉淡化

  Future<void> _fadeIn(
    AudioPlayer player, {
    required double targetVolume,
    required Duration duration,
  }) async {
    const steps = 30;
    final interval = duration.inMilliseconds ~/ steps;
    final increment = targetVolume / steps;

    for (var i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: interval));
      final vol = (increment * i).clamp(0.0, targetVolume);
      await player.setVolume(vol);
    }
  }

  Future<void> _fadeOut(
    AudioPlayer player, {
    required Duration duration,
  }) async {
    const steps = 20;
    final interval = duration.inMilliseconds ~/ steps;
    final startVolume = 1.0; // approximate
    final decrement = startVolume / steps;

    for (var i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: interval));
      final vol = (startVolume - decrement * i).clamp(0.0, 1.0);
      await player.setVolume(vol);
    }
  }
}
