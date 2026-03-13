import 'package:flutter/foundation.dart';

/// 听雨 ViewModel（白噪音）
class RainViewModel extends ChangeNotifier {
  final List<SoundSource> sources = [
    SoundSource(id: 'rain',    name: '细雨', icon: 'cloud.drizzle',   fileName: 'rain_light'),
    SoundSource(id: 'storm',   name: '暴雨', icon: 'cloud.heavyrain', fileName: 'rain_heavy'),
    SoundSource(id: 'thunder', name: '雷声', icon: 'cloud.bolt',      fileName: 'thunder'),
    SoundSource(id: 'stream',  name: '溪流', icon: 'water.waves',     fileName: 'stream'),
    SoundSource(id: 'wind',    name: '松风', icon: 'wind',            fileName: 'wind_pine'),
    SoundSource(id: 'night',   name: '虫鸣', icon: 'moon.stars',      fileName: 'night_insects'),
  ];

  bool get isAnyPlaying => sources.any((s) => s.isPlaying);

  void toggleSource(String id) {
    final idx = sources.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    sources[idx].isPlaying = !sources[idx].isPlaying;
    notifyListeners();
    // TODO: AudioService.instance.toggle
  }

  void setVolume(String id, double volume) {
    final idx = sources.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    sources[idx].volume = volume;
    notifyListeners();
    // TODO: AudioService.instance.setAmbientVolume
  }

  void stopAll() {
    for (final s in sources) {
      s.isPlaying = false;
    }
    notifyListeners();
    // TODO: AudioService.instance.stopAllAmbient
  }
}

class SoundSource {
  final String id;
  final String name;
  final String icon;
  final String fileName;
  double volume;
  bool isPlaying;

  SoundSource({
    required this.id,
    required this.name,
    required this.icon,
    required this.fileName,
    this.volume = 0.5,
    this.isPlaying = false,
  });
}
