import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/models/member_tier.dart';
import '../../services/entitlement_controller.dart';

abstract class RainPlayerHandle {
  Future<void> setLooping(bool enabled);
  Future<void> setAsset(String path);
  Future<void> setVolume(double volume);
  Future<void> play();
  Future<void> stop();
  Future<void> dispose();
}

class _AudioPlayerHandle implements RainPlayerHandle {
  final AudioPlayer _player;

  _AudioPlayerHandle(this._player);

  @override
  Future<void> setLooping(bool enabled) =>
      _player.setLoopMode(enabled ? LoopMode.one : LoopMode.off);

  @override
  Future<void> setAsset(String path) => _player.setAsset(path);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

typedef RainPlayerFactory = RainPlayerHandle Function();

/// 听雨 ViewModel（白噪音 — 单声音播放 + 动态加载）
class RainViewModel extends ChangeNotifier {
  final RainPlayerFactory _playerFactory;
  final EntitlementController? _entitlementController;
  RainPlayerHandle? _activePlayer;
  String? _activeSourceId;
  int _requestId = 0;
  bool _isDisposed = false;

  RainViewModel({
    RainPlayerFactory? playerFactory,
    EntitlementController? entitlementController,
  })  : _playerFactory = playerFactory ?? _defaultPlayerFactory,
        _entitlementController = entitlementController {
    _entitlementController?.addListener(_handleEntitlementChanged);
  }

  static RainPlayerHandle _defaultPlayerFactory() =>
      _AudioPlayerHandle(AudioPlayer());

  final List<SoundSource> sources = [
    SoundSource(
        id: 'rain',
        name: '细雨',
        icon: 'cloud.drizzle',
        fileName: 'white_noise/rain',
        requiredTier: MemberTier.free),
    SoundSource(
        id: 'stream_rain',
        name: '溪雨',
        icon: 'stream',
        fileName: 'white_noise/stream_rain',
        requiredTier: MemberTier.free),
    SoundSource(
        id: 'thunderstorm',
        name: '雷暴',
        icon: 'cloud.bolt',
        fileName: 'white_noise/thunderstorm',
        requiredTier: MemberTier.free),
    SoundSource(
        id: 'wave',
        name: '海浪',
        icon: 'water.waves.2',
        fileName: 'white_noise/wave',
        requiredTier: MemberTier.silver),
    SoundSource(
        id: 'wind',
        name: '松风',
        icon: 'wind',
        fileName: 'white_noise/wind',
        requiredTier: MemberTier.silver),
    SoundSource(
        id: 'night_fire',
        name: '篝火',
        icon: 'flame',
        fileName: 'white_noise/night_fire',
        requiredTier: MemberTier.silver),
    SoundSource(
        id: 'underwater',
        name: '水下',
        icon: 'bubble',
        fileName: 'white_noise/underwater',
        requiredTier: MemberTier.silver),
  ];

  EntitlementController? get entitlementController => _entitlementController;
  bool get isAnyPlaying => sources.any((s) => s.isPlaying);

  bool canAccessSource(SoundSource source) =>
      _entitlementController?.hasAccess(source.requiredTier) ??
      source.requiredTier == MemberTier.free;

  bool isSourceLocked(SoundSource source) => !canAccessSource(source);

  String _assetPathFor(SoundSource source) =>
      'assets/audio/${source.fileName}.mp3';

  Future<void> toggleSource(String id) async {
    if (_isDisposed) return;
    final idx = sources.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    final src = sources[idx];
    if (!canAccessSource(src)) return;
    final requestId = ++_requestId;

    try {
      // _activeSourceId 既表示当前播放项，也表示正在加载的目标项。
      if (_activeSourceId == src.id) {
        await _stopSource(src);
      } else {
        await _stopOtherSources(exceptId: src.id);
        if (_isStaleRequest(requestId)) return;
        await _playSource(src, requestId);
      }
    } finally {
      if (!_isStaleRequest(requestId)) {
        notifyListeners();
      }
    }
  }

  Future<void> setVolume(String id, double volume) async {
    if (_isDisposed) return;
    final idx = sources.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    sources[idx].volume = volume.clamp(0.0, 1.0);
    if (_activeSourceId == id) {
      await _activePlayer?.setVolume(sources[idx].volume);
    }
    notifyListeners();
  }

  Future<void> stopAll() async {
    if (_isDisposed) return;
    final requestId = ++_requestId;
    await _stopActivePlayer();
    if (!_isStaleRequest(requestId)) {
      notifyListeners();
    }
  }

  // ── 内部：按需加载 ──

  Future<void> _stopOtherSources({required String exceptId}) async {
    if (_activeSourceId != null && _activeSourceId != exceptId) {
      await _stopActivePlayer();
    }
  }

  Future<void> _playSource(SoundSource src, int requestId) async {
    final player = _playerFactory();
    _activePlayer = player;
    _activeSourceId = src.id;

    try {
      await player.setLooping(true);
      if (_isStalePlayerRequest(player, requestId)) return;
      await player.setAsset(_assetPathFor(src));
      if (_isStalePlayerRequest(player, requestId)) return;
      await player.setVolume(src.volume);
      if (_isStalePlayerRequest(player, requestId)) return;
      _setActiveSource(src.id);
      unawaited(_playWithoutBlocking(player, requestId));
    } catch (_) {
      if (!_isDisposed && !_isStalePlayerRequest(player, requestId)) {
        await _disposePlayer(player);
        _activePlayer = null;
        _activeSourceId = null;
      }
      _setActiveSource(null);
      rethrow;
    }
  }

  Future<void> _playWithoutBlocking(
    RainPlayerHandle player,
    int requestId,
  ) async {
    try {
      await player.play();
    } catch (_) {
      if (_isStalePlayerRequest(player, requestId)) return;
      await _disposePlayer(player);
      _activePlayer = null;
      _activeSourceId = null;
      _setActiveSource(null);
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  /// 停止并立即释放播放器，回收内存
  Future<void> _stopSource(SoundSource src) async {
    if (_activeSourceId == src.id) {
      await _stopActivePlayer();
      return;
    }
    src.isPlaying = false;
  }

  Future<void> _stopActivePlayer() async {
    final player = _activePlayer;
    _activePlayer = null;
    _activeSourceId = null;
    _setActiveSource(null);

    if (player == null) return;
    await _disposePlayer(player);
  }

  Future<void> _disposePlayer(RainPlayerHandle player) async {
    await player.stop();
    await player.dispose();
  }

  void _setActiveSource(String? sourceId) {
    for (final source in sources) {
      source.isPlaying = source.id == sourceId;
    }
  }

  void _handleEntitlementChanged() {
    final activeSourceId = _activeSourceId;
    if (activeSourceId == null) {
      notifyListeners();
      return;
    }

    final activeIndex =
        sources.indexWhere((source) => source.id == activeSourceId);
    if (activeIndex >= 0 && isSourceLocked(sources[activeIndex])) {
      unawaited(_stopActivePlayer());
    }
    notifyListeners();
  }

  bool _isStaleRequest(int requestId) => _isDisposed || requestId != _requestId;

  bool _isStalePlayerRequest(RainPlayerHandle player, int requestId) =>
      _isStaleRequest(requestId) || !identical(_activePlayer, player);

  @override
  void dispose() {
    _isDisposed = true;
    _requestId++;
    _entitlementController?.removeListener(_handleEntitlementChanged);
    unawaited(_stopActivePlayer());
    super.dispose();
  }
}

class SoundSource {
  final String id;
  final String name;
  final String icon;
  final String fileName;
  final MemberTier requiredTier;
  double volume;
  bool isPlaying;

  SoundSource({
    required this.id,
    required this.name,
    required this.icon,
    required this.fileName,
    required this.requiredTier,
    this.volume = 0.5,
    this.isPlaying = false,
  });
}
