import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme.dart';
import '../features/incense/incense_view.dart';
import '../features/rain/rain_qin_view.dart';
import '../features/settings/auth_sheet.dart';
import '../features/tea/tea_route.dart';
import '../features/stats/stats_view.dart';
import '../features/settings/settings_view.dart';
import '../services/auth_controller.dart';
import 'satori_tab_bar.dart';
import 'providers.dart';

enum _ContentPage {
  incense,
  rain,
  stats,
  settings,
}

/// 底部 Tab 导航
///
/// 底部四个图标 Tab：焚香、听雨、行迹、设置。
/// 品茗被整合到设置页中。
class ContentView extends ConsumerStatefulWidget {
  const ContentView({super.key});

  @override
  ConsumerState<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends ConsumerState<ContentView> {
  _ContentPage _currentPage = _ContentPage.incense;
  SatoriTab _selectedTab = SatoriTab.incense;
  double _opacity = 1.0;
  bool _isShowingPasswordRecoverySheet = false;

  void _handleTabChange(SatoriTab tab) {
    final page = _tabToPage(tab);
    if (page == _currentPage) return;

    setState(() => _opacity = 0);
    Future.delayed(SatoriTheme.animFast, () {
      if (!mounted) return;
      setState(() {
        _selectedTab = tab;
        _currentPage = page;
        _opacity = 1;
      });
    });
  }

  _ContentPage _tabToPage(SatoriTab tab) {
    switch (tab) {
      case SatoriTab.incense:
        return _ContentPage.incense;
      case SatoriTab.rain:
        return _ContentPage.rain;
      case SatoriTab.stats:
        return _ContentPage.stats;
      case SatoriTab.settings:
        return _ContentPage.settings;
    }
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case _ContentPage.incense:
        return const IncenseView();
      case _ContentPage.rain:
        return const _RainQinPageWrapper();
      case _ContentPage.stats:
        return const _StatsPageWrapper();
      case _ContentPage.settings:
        return const _SettingsPageWrapper();
    }
  }

  void _handleAuthUiEvent(AuthController authController) {
    final event = authController.takePendingUiEvent();
    if (event == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (event.type == AuthUiEventType.notice) {
        messenger?.showSnackBar(SnackBar(content: Text(event.message)));
        return;
      }

      messenger?.showSnackBar(SnackBar(content: Text(event.message)));
      if (_isShowingPasswordRecoverySheet) return;

      setState(() => _isShowingPasswordRecoverySheet = true);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => PasswordRecoverySheet(authController: authController),
      );
      if (mounted) {
        setState(() => _isShowingPasswordRecoverySheet = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = ref.read(authControllerProvider);
    _handleAuthUiEvent(authController);
    ref.read(supabaseSessionRepositoryProvider);
    ref.listen<AuthController>(authControllerProvider, (_, controller) {
      _handleAuthUiEvent(controller);
    });

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: _opacity == 0
                  ? SatoriTheme.animFast
                  : const Duration(milliseconds: 200),
              curve: _opacity == 0 ? Curves.easeOut : Curves.easeIn,
              child: _buildCurrentPage(),
            ),
          ),
          SatoriTabBar(
            selectedTab: _selectedTab,
            onTabChanged: _handleTabChange,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// 行迹页包装器 — 注入 aggregator
class _StatsPageWrapper extends ConsumerWidget {
  const _StatsPageWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StatsView(
      aggregator: ref.watch(statsAggregatorProvider),
      syncWithCloud: ref.watch(supabaseSessionRepositoryProvider).syncWithCloud,
    );
  }
}

class _RainQinPageWrapper extends ConsumerWidget {
  const _RainQinPageWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RainQinView(
      entitlementController: ref.watch(entitlementControllerProvider),
    );
  }
}

/// 设置页包装器
class _SettingsPageWrapper extends ConsumerWidget {
  const _SettingsPageWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementController = ref.watch(entitlementControllerProvider);

    return SettingsView(
      onTeaTap: () {
        unawaited(
          openTeaPage(
            context,
            entitlementController: entitlementController,
          ),
        );
      },
      authController: ref.watch(authControllerProvider),
      onAuthenticated:
          ref.watch(supabaseSessionRepositoryProvider).syncWithCloud,
      entitlementController: entitlementController,
    );
  }
}
