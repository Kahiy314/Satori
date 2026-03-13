import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../core/components/glass_background.dart';
import '../services/haptic_service.dart';

// ── Tab 枚举 ──

enum SatoriTab {
  incense('焚香', Icons.local_fire_department_outlined),
  rain('听雨', Icons.cloud_outlined),
  qin('抚琴', Icons.music_note_outlined),
  tea('品茗', Icons.local_cafe_outlined);

  const SatoriTab(this.label, this.icon);
  final String label;
  final IconData icon;

  Color get accentColor {
    switch (this) {
      case SatoriTab.incense:
        return SatoriColors.incenseEmber;
      case SatoriTab.rain:
        return SatoriColors.rainCyan;
      case SatoriTab.qin:
        return SatoriColors.stringGold;
      case SatoriTab.tea:
        return SatoriColors.teaAmber;
    }
  }
}

// ── 底部菜单栏 ──
// 仿 Telegram iOS 风格：液态玻璃 + 微缩放 + 触感反馈

class SatoriTabBar extends StatelessWidget {
  final SatoriTab selectedTab;
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
                  child: Icon(
                    widget.tab.icon,
                    size: 18,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.tab.label,
              style: SatoriTypography.tabLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
