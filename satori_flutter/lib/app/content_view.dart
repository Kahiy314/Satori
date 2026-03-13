import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../features/incense/incense_view.dart';
import '../features/rain/rain_view.dart';
import '../features/qin/qin_view.dart';
import '../features/tea/tea_view.dart';
import 'satori_tab_bar.dart';

/// 四 tab 信息架构 — 渐入渐出页面切换
class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  SatoriTab _selectedTab = SatoriTab.incense;
  double _opacity = 1.0;

  // 预构建四页面避免切换时重建
  final _pages = const <SatoriTab, Widget>{
    SatoriTab.incense: IncenseView(),
    SatoriTab.rain: RainView(),
    SatoriTab.qin: QinView(),
    SatoriTab.tea: TeaView(),
  };

  void _handleTabChange(SatoriTab newTab) {
    if (newTab == _selectedTab) return;

    // 渐出 → 切换 → 渐入
    setState(() => _opacity = 0);
    Future.delayed(SatoriTheme.animFast, () {
      if (!mounted) return;
      setState(() {
        _selectedTab = newTab;
        _opacity = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 当前功能页面
          AnimatedOpacity(
            opacity: _opacity,
            duration: _opacity == 0 ? SatoriTheme.animFast : const Duration(milliseconds: 200),
            curve: _opacity == 0 ? Curves.easeOut : Curves.easeIn,
            child: _pages[_selectedTab],
          ),

          // 底部菜单栏
          Positioned(
            left: SatoriTheme.spacingM,
            right: SatoriTheme.spacingM,
            bottom: 8,
            child: SatoriTabBar(
              selectedTab: _selectedTab,
              onTabChanged: _handleTabChange,
            ),
          ),
        ],
      ),
    );
  }
}
