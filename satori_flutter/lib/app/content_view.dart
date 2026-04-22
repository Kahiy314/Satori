import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme.dart';
import '../features/incense/incense_view.dart';
import '../features/rain/rain_qin_view.dart';
import '../features/tea/tea_view.dart';
import '../features/stats/stats_view.dart';
import '../features/settings/settings_view.dart';
import 'satori_tab_bar.dart';
import 'providers.dart';

enum _ContentPage {
  incense,
  rain,
  stats,
  settings,
  tea,
}

/// 底部 Tab 导航
///
/// 底部四个图标 Tab：焚香、听雨、行迹、设置。
/// 品茗被整合到设置页中。
class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  _ContentPage _currentPage = _ContentPage.incense;
  SatoriTab _selectedTab = SatoriTab.incense;
  double _opacity = 1.0;

  void _handlePageChange(_ContentPage page) {
    if (page == _currentPage) {
      return;
    }

    // 渐出 → 切换 → 渐入
    setState(() => _opacity = 0);
    Future.delayed(SatoriTheme.animFast, () {
      if (!mounted) return;
      setState(() {
        _currentPage = page;
        _selectedTab = _pageToTab(page);
        _opacity = 1;
      });
    });
  }

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

  SatoriTab _pageToTab(_ContentPage page) {
    switch (page) {
      case _ContentPage.incense:
        return SatoriTab.incense;
      case _ContentPage.rain:
        return SatoriTab.rain;
      case _ContentPage.stats:
        return SatoriTab.stats;
      case _ContentPage.settings:
        return SatoriTab.settings;
      case _ContentPage.tea:
        return SatoriTab.settings;
    }
  }

  /// 从设置页跳转品茗（双重露出 U6）
  void _goToTea() {
    _handlePageChange(_ContentPage.tea);
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
        return _SettingsPageWrapper(onTeaTap: _goToTea);
      case _ContentPage.tea:
        return const _TeaPageWrapper();
    }
  }

  @override
  Widget build(BuildContext context) {
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
  final VoidCallback onTeaTap;
  const _SettingsPageWrapper({required this.onTeaTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsView(
      onTeaTap: onTeaTap,
      authController: ref.watch(authControllerProvider),
      onAuthenticated:
          ref.watch(supabaseSessionRepositoryProvider).syncWithCloud,
      entitlementController: ref.watch(entitlementControllerProvider),
    );
  }
}

class _TeaPageWrapper extends ConsumerWidget {
  const _TeaPageWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TeaView(
      entitlementController: ref.watch(entitlementControllerProvider),
    );
  }
}
