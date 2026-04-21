import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_session_repository.dart';
import '../services/local_stats_aggregator.dart';
import '../services/local_user_preferences.dart';
import '../services/platform_focus_activity_service.dart';
import '../services/platform_media_session_service.dart';
import '../services/entitlement_controller.dart';
import '../services/session_repository.dart';
import '../services/stats_aggregator.dart';
import '../services/user_preferences.dart';
import '../services/focus_activity_service.dart';
import '../services/media_session_service.dart';
import '../features/incense/incense_view_model.dart';

// ── 服务层 Providers ──

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return LocalSessionRepository();
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
