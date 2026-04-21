import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:satori/core/models/member_tier.dart';
import 'package:satori/features/rain/rain_view_model.dart';
import 'package:satori/services/entitlement_controller.dart';

class _FakeRainPlayerHandle implements RainPlayerHandle {
  final List<String> sourcePaths = [];
  final List<double> volumes = [];
  final List<bool> loopFlags = [];
  int playCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> setLooping(bool enabled) async {
    loopFlags.add(enabled);
  }

  @override
  Future<void> setAsset(String path) async {
    sourcePaths.add(path);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> play() async {
    playCalls += 1;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _BlockingRainPlayerHandle extends _FakeRainPlayerHandle {
  final Completer<void>? assetStarted;
  final Completer<void>? assetGate;

  _BlockingRainPlayerHandle({
    this.assetStarted,
    this.assetGate,
  });

  @override
  Future<void> setAsset(String path) async {
    await super.setAsset(path);
    if (assetStarted != null && !assetStarted!.isCompleted) {
      assetStarted!.complete();
    }
    if (assetGate != null) {
      await assetGate!.future;
    }
  }
}

class _PendingPlayRainPlayerHandle extends _FakeRainPlayerHandle {
  final Completer<void> playGate = Completer<void>();

  @override
  Future<void> play() async {
    playCalls += 1;
    await playGate.future;
  }
}

void main() {
  group('RainViewModel 单声音播放', () {
    late List<_FakeRainPlayerHandle> createdPlayers;
    late RainViewModel vm;
    late EntitlementController entitlementController;

    setUp(() {
      createdPlayers = [];
      entitlementController = EntitlementController(
        initialPurchasedTier: MemberTier.premium,
        loadFromStorage: false,
      );
      vm = RainViewModel(
        playerFactory: () {
          final player = _FakeRainPlayerHandle();
          createdPlayers.add(player);
          return player;
        },
        entitlementController: entitlementController,
      );
    });

    tearDown(() {
      vm.dispose();
      entitlementController.dispose();
    });

    test('首次选择音源时只启动当前声音', () async {
      await vm.toggleSource('rain');

      expect(vm.isAnyPlaying, true);
      expect(
        vm.sources
            .where((source) => source.isPlaying)
            .map((source) => source.id),
        ['rain'],
      );
      expect(createdPlayers, hasLength(1));
      expect(createdPlayers.single.sourcePaths,
          ['assets/audio/white_noise/rain.mp3']);
      expect(createdPlayers.single.loopFlags, [true]);
      expect(createdPlayers.single.volumes, [0.5]);
      expect(createdPlayers.single.playCalls, 1);
    });

    test('切换到新音源时会停止并释放旧音源', () async {
      await vm.toggleSource('rain');
      final firstPlayer = createdPlayers.single;

      await vm.toggleSource('wave');

      expect(
        vm.sources
            .where((source) => source.isPlaying)
            .map((source) => source.id),
        ['wave'],
      );
      expect(firstPlayer.stopCalls, 1);
      expect(firstPlayer.disposeCalls, 1);
      expect(createdPlayers, hasLength(2));
      expect(createdPlayers.last.sourcePaths,
          ['assets/audio/white_noise/wave.mp3']);
    });

    test('再次点击当前音源会停止播放', () async {
      await vm.toggleSource('wind');
      final activePlayer = createdPlayers.single;

      await vm.toggleSource('wind');

      expect(vm.isAnyPlaying, false);
      expect(vm.sources.where((source) => source.isPlaying), isEmpty);
      expect(activePlayer.stopCalls, 1);
      expect(activePlayer.disposeCalls, 1);
    });

    test('调节当前播放项音量会同步到活跃播放器', () async {
      await vm.toggleSource('underwater');

      await vm.setVolume('underwater', 0.8);

      expect(createdPlayers.single.volumes, [0.5, 0.8]);
    });

    test('首个音源仍在加载时切到新音源，不会被旧请求反向覆盖', () async {
      final firstAssetStarted = Completer<void>();
      final firstAssetGate = Completer<void>();
      late _BlockingRainPlayerHandle firstPlayer;
      late _FakeRainPlayerHandle secondPlayer;
      var createdCount = 0;

      vm.dispose();
      vm = RainViewModel(
        playerFactory: () {
          createdCount += 1;
          if (createdCount == 1) {
            firstPlayer = _BlockingRainPlayerHandle(
              assetStarted: firstAssetStarted,
              assetGate: firstAssetGate,
            );
            return firstPlayer;
          }
          secondPlayer = _FakeRainPlayerHandle();
          return secondPlayer;
        },
        entitlementController: entitlementController,
      );

      final firstToggle = vm.toggleSource('rain');
      await firstAssetStarted.future;

      final secondToggle = vm.toggleSource('wave');
      await secondToggle;

      firstAssetGate.complete();
      await firstToggle;

      expect(
        vm.sources
            .where((source) => source.isPlaying)
            .map((source) => source.id),
        ['wave'],
      );
      expect(firstPlayer.playCalls, 0);
      expect(firstPlayer.stopCalls, 1);
      expect(firstPlayer.disposeCalls, 1);
      expect(secondPlayer.playCalls, 1);
      expect(secondPlayer.sourcePaths, ['assets/audio/white_noise/wave.mp3']);
    });

    test('播放 Future 未完成时仍会立即更新当前音源状态', () async {
      late _PendingPlayRainPlayerHandle player;

      vm.dispose();
      vm = RainViewModel(
        playerFactory: () {
          player = _PendingPlayRainPlayerHandle();
          return player;
        },
        entitlementController: entitlementController,
      );

      final toggleFuture = vm.toggleSource('rain');
      await expectLater(toggleFuture, completes);

      expect(vm.isAnyPlaying, true);
      expect(
        vm.sources
            .where((source) => source.isPlaying)
            .map((source) => source.id),
        ['rain'],
      );
      expect(player.playCalls, 1);

      player.playGate.complete();
    });

    test('未解锁音源不会创建播放器', () async {
      vm.dispose();
      entitlementController.dispose();
      entitlementController = EntitlementController(loadFromStorage: false);
      vm = RainViewModel(
        playerFactory: () {
          final player = _FakeRainPlayerHandle();
          createdPlayers.add(player);
          return player;
        },
        entitlementController: entitlementController,
      );

      await vm.toggleSource('wave');

      expect(createdPlayers, isEmpty);
      expect(vm.isAnyPlaying, false);
    });
  });
}
