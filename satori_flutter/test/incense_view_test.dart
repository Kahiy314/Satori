import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satori/app/providers.dart';
import 'package:satori/core/models/focus_session.dart';
import 'package:satori/features/incense/incense_view.dart';
import 'package:satori/services/focus_activity_service.dart';
import 'package:satori/services/session_repository.dart';
import 'package:satori/services/user_preferences.dart';

class _TestSessionRepository implements SessionRepository {
  @override
  Future<int> count() async => 0;

  @override
  Future<void> delete(String sessionId) async {}

  @override
  Future<List<FocusSession>> findAllCounted() async => [];

  @override
  Future<List<FocusSession>> findByDateRange(DateTime from, DateTime to) async => [];

  @override
  Future<FocusSession?> findById(String sessionId) async => null;

  @override
  Future<List<FocusSession>> findUncounted() async => [];

  @override
  Future<void> save(FocusSession session) async {}
}

class _TestUserPreferences implements UserPreferences {
  @override
  Future<void> addRecentTag(String tag) async {}

  @override
  Future<bool> isShortFocusPromptDismissed() async => false;

  @override
  Future<List<String>> recentTags() async => [];

  @override
  Future<void> setShortFocusPromptDismissed(bool dismissed) async {}
}

class _TestFocusActivityService implements FocusActivityService {
  bool _isActive = false;

  @override
  bool get isActive => _isActive;

  @override
  Future<void> startActivity({
    required bool isCountdown,
    double? totalSeconds,
  }) async {
    _isActive = true;
  }

  @override
  Future<void> stopActivity() async {
    _isActive = false;
  }

  @override
  Future<void> updateActivity({required double remainingOrElapsed}) async {}
}

void main() {
  testWidgets('点击开始后焚香界面立即切换到运行态', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(_TestSessionRepository()),
          userPreferencesProvider.overrideWithValue(_TestUserPreferences()),
          focusActivityServiceProvider.overrideWithValue(
            _TestFocusActivityService(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: IncenseView(),
          ),
        ),
      ),
    );

    expect(find.text('正计时'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);

    await tester.tap(find.byIcon(Icons.local_fire_department));
    await tester.pump();

    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.text('正计时'), findsNothing);
  });
}
