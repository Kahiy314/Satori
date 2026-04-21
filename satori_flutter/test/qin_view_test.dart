import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satori/core/models/member_tier.dart';
import 'package:satori/features/qin/qin_view.dart';
import 'package:satori/features/qin/qin_view_model.dart';
import 'package:satori/services/entitlement_controller.dart';

class _FakeQinAudioController implements QinAudioController {
  final List<String> playedFileNames = [];
  int toggleCalls = 0;
  int stopCalls = 0;
  final List<Duration> seekPositions = [];

  @override
  Future<void> play(Track track) async {
    playedFileNames.add(track.fileName);
  }

  @override
  Future<void> seek(Duration position) async {
    seekPositions.add(position);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> togglePlayPause() async {
    toggleCalls += 1;
  }
}

void main() {
  testWidgets('点击曲目后会显示播放器并切到真实音乐资源', (tester) async {
    final audioController = _FakeQinAudioController();
    final entitlementController = EntitlementController(loadFromStorage: false);
    final vm = QinViewModel(
      audioController: audioController,
      entitlementController: entitlementController,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QinView(viewModel: vm),
        ),
      ),
    );

    expect(find.text('高山流水'), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_filled), findsNothing);

    await tester.tap(find.text('高山流水'));
    await tester.pump();

    expect(audioController.playedFileNames,
        ['instrumental_music/Streams_Over_Stone']);
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);

    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pump();

    expect(
      audioController.playedFileNames.last,
      'instrumental_music/Plum_Blossom_Trilogy',
    );

    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pump();

    expect(
      audioController.playedFileNames.last,
      'instrumental_music/Streams_Over_Stone',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    vm.dispose();
    entitlementController.dispose();
    await tester.pump();
  });

  testWidgets('开发者模式未开启时点击锁定曲目不会播放', (tester) async {
    final audioController = _FakeQinAudioController();
    final entitlementController = EntitlementController(loadFromStorage: false);
    final vm = QinViewModel(
      audioController: audioController,
      entitlementController: entitlementController,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QinView(viewModel: vm),
        ),
      ),
    );

    await tester.tap(find.text('渔舟唱晚'));
    await tester.pumpAndSettle();

    expect(audioController.playedFileNames, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    vm.dispose();
    entitlementController.dispose();
    await tester.pump();
  });

  testWidgets('开发者模式开启后可以播放锁定曲目', (tester) async {
    final audioController = _FakeQinAudioController();
    final entitlementController = EntitlementController(
      initialPurchasedTier: MemberTier.free,
      initialDeveloperMode: true,
      loadFromStorage: false,
    );
    final vm = QinViewModel(
      audioController: audioController,
      entitlementController: entitlementController,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QinView(viewModel: vm),
        ),
      ),
    );

    await tester.tap(find.text('渔舟唱晚'));
    await tester.pump();

    expect(
      audioController.playedFileNames,
      ['instrumental_music/Twilight_Song_over_Fishing_Boats'],
    );
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    vm.dispose();
    entitlementController.dispose();
    await tester.pump();
  });
}
