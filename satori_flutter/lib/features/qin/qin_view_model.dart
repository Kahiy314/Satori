import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/models/member_tier.dart';
import '../../services/audio_service.dart';
import '../../services/entitlement_controller.dart';

abstract class QinAudioController {
  Future<void> play(Track track);
  Future<void> togglePlayPause();
  Future<void> stop();
  Future<void> seek(Duration position);
}

class _AudioServiceQinAudioController implements QinAudioController {
  final AudioService _audioService;

  _AudioServiceQinAudioController(this._audioService);

  @override
  Future<void> play(Track track) {
    return _audioService.playMusic(
      track.fileName,
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: (track.duration * 1000).round()),
    );
  }

  @override
  Future<void> seek(Duration position) => _audioService.seekMusic(position);

  @override
  Future<void> stop() => _audioService.stopMusic();

  @override
  Future<void> togglePlayPause() => _audioService.toggleMusicPlayPause();
}

/// 抚琴 ViewModel（轻音乐播放）
class QinViewModel extends ChangeNotifier {
  final QinAudioController _audioController;
  final EntitlementController? _entitlementController;

  QinViewModel({
    QinAudioController? audioController,
    EntitlementController? entitlementController,
  })  : _audioController = audioController ??
            _AudioServiceQinAudioController(AudioService.instance),
        _entitlementController = entitlementController {
    _entitlementController?.addListener(_handleEntitlementChanged);
  }

  final List<Track> tracks = [
    Track(
      id: 'streams_over_stone',
      title: '高山流水',
      artist: '古琴',
      duration: 176,
      fileName: 'instrumental_music/Streams_Over_Stone',
      requiredTier: MemberTier.free,
    ),
    Track(
      id: 'plum_blossom_trilogy',
      title: '梅花三弄',
      artist: '萧',
      duration: 174,
      fileName: 'instrumental_music/Plum_Blossom_Trilogy',
      requiredTier: MemberTier.free,
    ),
    Track(
      id: 'twilight_song_over_fishing_boats',
      title: '渔舟唱晚',
      artist: '古筝',
      duration: 176,
      fileName: 'instrumental_music/Twilight_Song_over_Fishing_Boats',
      requiredTier: MemberTier.silver,
    ),
    Track(
      id: 'pure_lotus',
      title: '清水芙蓉',
      artist: '古筝',
      duration: 179,
      fileName: 'instrumental_music/Pure_Lotus',
      requiredTier: MemberTier.silver,
    ),
    Track(
      id: 'misty_rain_dream',
      title: '一梦烟雨',
      artist: '扬琴',
      duration: 187,
      fileName: 'instrumental_music/Misty_Rain_Dream',
      requiredTier: MemberTier.silver,
    ),
    Track(
      id: 'shiny_spring',
      title: '春和景明',
      artist: '琵琶',
      duration: 154,
      fileName: 'instrumental_music/Shiny_Spring',
      requiredTier: MemberTier.silver,
    ),
    Track(
      id: 'rain_town',
      title: '烟雨小镇',
      artist: '中阮',
      duration: 191,
      fileName: 'instrumental_music/Rain_Town',
      requiredTier: MemberTier.gold,
    ),
    Track(
      id: 'ethereal_guzheng_music',
      title: '古筝灵音',
      artist: '古筝',
      duration: 213,
      fileName: 'instrumental_music/Ethereal_Guzheng_Music',
      requiredTier: MemberTier.gold,
    ),
    Track(
      id: 'Tranquil_Water_Town',
      title: '江南水乡',
      artist: '扬琴',
      duration: 133,
      fileName: 'instrumental_music/Tranquil_Water_Town',
      requiredTier: MemberTier.gold,
    ),
    Track(
      id: 'seeking_flowers',
      title: '寻花辞',
      artist: '萧',
      duration: 259,
      fileName: 'instrumental_music/Seeking_Flowers',
      requiredTier: MemberTier.gold,
    ),
    Track(
      id: 'spring_ode',
      title: '春颂',
      artist: '笛',
      duration: 143,
      fileName: 'instrumental_music/Spring_Ode',
      requiredTier: MemberTier.gold,
    ),
    Track(
      id: 'rainy_taoyuan_town',
      title: '雨落桃源镇',
      artist: '扬琴',
      duration: 179,
      fileName: 'instrumental_music/Rainy_Taoyuan_Town',
      requiredTier: MemberTier.gold,
    ),
  ];

  Track? currentTrack;
  bool isPlaying = false;
  double currentTime = 0; // seconds
  double duration = 0;

  Timer? _timer;
  int _requestId = 0;
  bool _isDisposed = false;

  EntitlementController? get entitlementController => _entitlementController;

  bool canAccessTrack(Track track) =>
      _entitlementController?.hasAccess(track.requiredTier) ??
      track.requiredTier == MemberTier.free;

  bool isTrackLocked(Track track) => !canAccessTrack(track);

  Future<void> play(Track track) async {
    if (_isDisposed || isTrackLocked(track)) return;

    final requestId = ++_requestId;
    currentTrack = track;
    duration = track.duration;
    currentTime = 0;
    isPlaying = true;
    _startTimer();
    notifyListeners();

    try {
      await _audioController.play(track);
    } catch (_) {
      if (_isStaleRequest(requestId)) return;
      _timer?.cancel();
      currentTrack = null;
      currentTime = 0;
      duration = 0;
      isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isDisposed || currentTrack == null) return;

    final nextIsPlaying = !isPlaying;
    isPlaying = nextIsPlaying;
    if (nextIsPlaying) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
    notifyListeners();

    try {
      await _audioController.togglePlayPause();
    } catch (_) {
      if (_isDisposed || currentTrack == null) return;
      isPlaying = !nextIsPlaying;
      if (isPlaying) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_isDisposed) return;

    _requestId += 1;
    isPlaying = false;
    currentTrack = null;
    currentTime = 0;
    duration = 0;
    _timer?.cancel();
    notifyListeners();

    try {
      await _audioController.stop();
    } catch (_) {
      // Ignore teardown errors so the UI can still reset immediately.
    }
  }

  Future<void> seek(double time) async {
    if (_isDisposed || currentTrack == null) return;

    currentTime = (time.clamp(0.0, duration) as num).toDouble();
    notifyListeners();

    try {
      await _audioController.seek(
        Duration(milliseconds: (currentTime * 1000).round()),
      );
    } catch (_) {
      // Keep the local slider responsive even if the player seek fails.
    }
  }

  Future<void> playNext() async {
    if (_isDisposed || currentTrack == null) return;

    final idx = tracks.indexWhere((t) => t.id == currentTrack!.id);
    if (idx < 0) return;

    for (var offset = 1; offset <= tracks.length; offset++) {
      final nextTrack = tracks[(idx + offset) % tracks.length];
      if (canAccessTrack(nextTrack)) {
        await play(nextTrack);
        return;
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_isDisposed || !isPlaying) return;

      currentTime =
          ((currentTime + 0.5).clamp(0.0, duration) as num).toDouble();
      if (currentTime >= duration) {
        unawaited(playNext());
        return;
      }
      notifyListeners();
    });
  }

  bool _isStaleRequest(int requestId) => _isDisposed || requestId != _requestId;

  void _handleEntitlementChanged() {
    final track = currentTrack;
    if (track != null && isTrackLocked(track)) {
      unawaited(stop());
      return;
    }
    notifyListeners();
  }

  String get formattedCurrentTime => formatTime(currentTime);
  String get formattedDuration => formatTime(duration);

  String formatTime(double t) {
    final total = t.toInt();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestId += 1;
    _timer?.cancel();
    _entitlementController?.removeListener(_handleEntitlementChanged);
    unawaited(_audioController.stop());
    super.dispose();
  }
}

class Track {
  final String id;
  final String title;
  final String artist;
  final double duration;
  final String fileName;
  final MemberTier requiredTier;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.fileName,
    required this.requiredTier,
  });
}
