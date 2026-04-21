import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../core/theme/theme.dart';
import '../core/components/glass_background.dart';
import '../services/haptic_service.dart';

// ── Tab 枚举 ──

enum SatoriTab {
  incense(Symbols.self_improvement, Symbols.self_improvement),
  rain(Symbols.noise_control_off, Symbols.noise_aware),
  stats(Icons.timeline_outlined, Icons.timeline),
  settings(Symbols.account_circle, Symbols.account_circle);

  const SatoriTab(this.icon, this.activeIcon);
  final IconData icon;
  final IconData activeIcon;

  Color get accentColor {
    switch (this) {
      case SatoriTab.incense:
        return SatoriColors.incenseEmber;
      case SatoriTab.rain:
        return SatoriColors.rainCyan;
      case SatoriTab.stats:
        return SatoriColors.verdigris;
      case SatoriTab.settings:
        return SatoriColors.inkSmoke;
    }
  }
}

// ── 底部菜单栏 ──
// 仿 Telegram iOS 风格：液态玻璃 + 微缩放 + 触感反馈

class SatoriTabBar extends StatelessWidget {
  final SatoriTab? selectedTab;
  final ValueChanged<SatoriTab> onTabChanged;

  const SatoriTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 玻璃背景
        const Positioned.fill(
          child: GlassBackground(cornerRadius: SatoriTheme.cornerLarge),
        ),
        // 按钮行
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SatoriTheme.spacingM,
            8,
            SatoriTheme.spacingM,
            4,
          ),
          child: Row(
            children: SatoriTab.values.map((tab) {
              return Expanded(
                child: _TabButton(
                  tab: tab,
                  isSelected: selectedTab == tab,
                  onTap: () => onTabChanged(tab),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatefulWidget {
  final SatoriTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  double _scale = 1.0;

  Widget _buildIcon(Color color) {
    // 焚香选中态使用自定义 SVG
    if (widget.tab == SatoriTab.incense && widget.isSelected) {
      return SvgPicture.asset(
        'assets/images/ic_incense_active.svg',
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(
      widget.isSelected ? widget.tab.activeIcon : widget.tab.icon,
      fill: widget.isSelected ? 1 : 0,
      size: 22,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? widget.tab.accentColor : Colors.grey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.88),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        if (!widget.isSelected) {
          HapticService.instance.lightTap();
          widget.onTap();
        }
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 指示器 + 图标
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.tab.accentColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: AnimatedScale(
                  scale: widget.isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 350),
                  child: _buildIcon(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
