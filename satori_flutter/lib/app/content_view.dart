import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme.dart';
import '../features/incense/incense_view.dart';
import '../features/rain/rain_view.dart';
import '../features/qin/qin_view.dart';
import '../features/tea/tea_view.dart';
import '../features/stats/stats_view.dart';
import '../features/settings/settings_view.dart';
import 'rice_paper_drawer.dart';
import 'providers.dart';

/// 宣纸导航架构 — U1/U2
///
/// 默认直达焚香主界面，左上角隐藏式入口展开宣纸目录。
/// 不再使用底部 tab 导航。
class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  SatoriPage _currentPage = SatoriPage.incense;
  double _opacity = 1.0;
  bool _drawerOpen = false;

  void _openDrawer() {
    setState(() => _drawerOpen = true);
  }

  void _closeDrawer() {
    setState(() => _drawerOpen = false);
  }

  void _handlePageChange(SatoriPage page) {
    if (page == _currentPage) {
      _closeDrawer();
      return;
    }

    _closeDrawer();
    // 渐出 → 切换 → 渐入
    setState(() => _opacity = 0);
    Future.delayed(SatoriTheme.animFast, () {
      if (!mounted) return;
      setState(() {
        _currentPage = page;
        _opacity = 1;
      });
    });
  }

  /// 从设置页跳转品茗（双重露出 U6）
  void _goToTea() {
    _handlePageChange(SatoriPage.tea);
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case SatoriPage.incense:
        return IncenseView(onDrawerTap: _openDrawer);
      case SatoriPage.rain:
        return RainView(onDrawerTap: _openDrawer);
      case SatoriPage.qin:
        return QinView(onDrawerTap: _openDrawer);
      case SatoriPage.stats:
        return _StatsPageWrapper(onDrawerTap: _openDrawer);
      case SatoriPage.settings:
        return _SettingsPageWrapper(
            onDrawerTap: _openDrawer, onTeaTap: _goToTea);
      case SatoriPage.tea:
        return TeaView(onDrawerTap: _openDrawer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 当前功能页面
          AnimatedOpacity(
            opacity: _opacity,
            duration: _opacity == 0
                ? SatoriTheme.animFast
                : const Duration(milliseconds: 200),
            curve: _opacity == 0 ? Curves.easeOut : Curves.easeIn,
            child: _buildCurrentPage(),
          ),

          // 宣纸抽屉
          if (_drawerOpen)
            AnimatedOpacity(
              opacity: _drawerOpen ? 1.0 : 0.0,
              duration: SatoriTheme.animNormal,
              child: RicePaperDrawer(
                currentPage: _currentPage,
                onPageSelected: _handlePageChange,
                onClose: _closeDrawer,
              ),
            ),
        ],
      ),
    );
  }
}

/// 行迹页包装器 — 注入 aggregator 并添加左上角入口
class _StatsPageWrapper extends ConsumerWidget {
  final VoidCallback onDrawerTap;
  const _StatsPageWrapper({required this.onDrawerTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        StatsView(aggregator: ref.watch(statsAggregatorProvider)),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: SatoriTheme.spacingM,
          child: _DrawerButton(onTap: onDrawerTap),
        ),
      ],
    );
  }
}

/// 设置页包装器 — 添加左上角入口
class _SettingsPageWrapper extends StatelessWidget {
  final VoidCallback onDrawerTap;
  final VoidCallback onTeaTap;
  const _SettingsPageWrapper(
      {required this.onDrawerTap, required this.onTeaTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SettingsView(onTeaTap: onTeaTap),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: SatoriTheme.spacingM,
          child: _DrawerButton(onTap: onDrawerTap),
        ),
      ],
    );
  }
}

class _DrawerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DrawerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : SatoriColors.inkSmoke.withValues(alpha: 0.35);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(SatoriTheme.spacingS),
        child: Icon(Icons.menu, size: 20, color: color),
      ),
    );
  }
}
