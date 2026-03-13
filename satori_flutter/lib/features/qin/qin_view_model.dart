import 'dart:async';
import 'package:flutter/foundation.dart';

/// 抚琴 ViewModel（轻音乐播放）
class QinViewModel extends ChangeNotifier {
  final List<Track> tracks = [
    Track(id: '1', title: '高山流水',   artist: '古琴', duration: 240, fileName: 'guqin_mountain'),
    Track(id: '2', title: '平沙落雁',   artist: '古琴', duration: 300, fileName: 'guqin_goose'),
    Track(id: '3', title: '梅花三弄',   artist: '箫',   duration: 270, fileName: 'xiao_plum'),
    Track(id: '4', title: '渔舟唱晚',   artist: '古筝', duration: 210, fileName: 'guzheng_boat'),
    Track(id: '5', title: '春江花月夜', artist: '琵琶', duration: 360, fileName: 'pipa_spring'),
    Track(id: '6', title: '阳关三叠',   artist: '古琴', duration: 280, fileName: 'guqin_yangguan', isLocked: true),
  ];

  Track? currentTrack;
  bool isPlaying = false;
  double currentTime = 0; // seconds
  double duration = 0;

  Timer? _timer;

  void play(Track track) {
    if (track.isLocked) return;
    currentTrack = track;
    duration = track.duration;
    currentTime = 0;
    isPlaying = true;
    _startTimer();
    notifyListeners();
    // TODO: AudioService.instance.playMusic(track.fileName);
  }

  void togglePlayPause() {
    isPlaying = !isPlaying;
    if (isPlaying) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
    notifyListeners();
    // TODO: AudioService.instance.toggleMusicPlayPause();
  }

  void stop() {
    isPlaying = false;
    currentTrack = null;
    currentTime = 0;
    _timer?.cancel();
    notifyListeners();
  }

  void seek(double time) {
    currentTime = time;
    notifyListeners();
    // TODO: AudioService.instance.seekMusic
  }

  void playNext() {
    if (currentTrack == null) return;
    final idx = tracks.indexWhere((t) => t.id == currentTrack!.id);
    if (idx < 0) return;
    final nextIdx = (idx + 1) % tracks.length;
    if (!tracks[nextIdx].isLocked) {
      play(tracks[nextIdx]);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!isPlaying) return;
      currentTime = (currentTime + 0.5).clamp(0.0, duration);
      if (currentTime >= duration) {
        playNext();
      }
      notifyListeners();
    });
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
    _timer?.cancel();
    super.dispose();
  }
}

class Track {
  final String id;
  final String title;
  final String artist;
  final double duration;
  final String fileName;
  final bool isLocked;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.fileName,
    this.isLocked = false,
  });
}
