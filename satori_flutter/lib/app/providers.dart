import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_session_repository.dart';
import '../services/local_stats_aggregator.dart';
import '../services/local_user_preferences.dart';
import '../services/auth_controller.dart';
import '../services/platform_focus_activity_service.dart';
import '../services/platform_media_session_service.dart';
import '../services/entitlement_controller.dart';
import '../services/session_repository.dart';
import '../services/stats_aggregator.dart';
import '../services/user_preferences.dart';
import '../services/focus_activity_service.dart';
import '../services/media_session_service.dart';
import '../services/supabase_bootstrap.dart';
import '../services/supabase_session_repository.dart';
import '../features/incense/incense_view_model.dart';

// ── 服务层 Providers ──

final localSessionRepositoryProvider = Provider<LocalSessionRepository>((ref) {
  return LocalSessionRepository();
});

final supabaseSessionRepositoryProvider =
    Provider<SupabaseSessionRepository>((ref) {
  final repository = SupabaseSessionRepository(
    localRepository: ref.watch(localSessionRepositoryProvider),
    client: ref.watch(supabaseClientProvider),
  );

  ref.listen<AuthController>(authControllerProvider, (_, controller) {
    if (controller.isSignedIn) {
      unawaited(repository.syncWithCloud());
    }
  });

  return repository;
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return ref.watch(supabaseSessionRepositoryProvider);
});

final statsAggregatorProvider = Provider<StatsAggregator>((ref) {
  return LocalStatsAggregator(ref.watch(sessionRepositoryProvider));
});

final userPreferencesProvider = Provider<UserPreferences>((ref) {
  return LocalUserPreferences();
});

final focusActivityServiceProvider = Provider<FocusActivityService>((ref) {
  return PlatformFocusActivityService();
});

final mediaSessionServiceProvider = Provider<MediaSessionService>((ref) {
  return PlatformMediaSessionService();
});

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return SupabaseBootstrap.client;
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(client: ref.watch(supabaseClientProvider));
});

final entitlementControllerProvider =
    ChangeNotifierProvider<EntitlementController>((ref) {
  return EntitlementController();
});

// ── 焚香 ViewModel Provider ──

final incenseViewModelProvider =
    ChangeNotifierProvider.autoDispose<IncenseViewModel>((ref) {
  return IncenseViewModel(
    sessionRepository: ref.watch(sessionRepositoryProvider),
    userPreferences: ref.watch(userPreferencesProvider),
    focusActivityService: ref.watch(focusActivityServiceProvider),
  );
});

final incenseSummarySessionIdProvider = Provider<String?>((ref) {
  final vm = ref.watch(incenseViewModelProvider);
  if (vm.state != TimerState.completed) return null;
  return vm.lastFinishedSession?.sessionId;
});
