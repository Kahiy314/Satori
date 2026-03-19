import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../services/haptic_service.dart';

/// 宣纸目录条目
enum SatoriPage {
  incense('焚香', Icons.local_fire_department_outlined),
  rain('听雨', Icons.cloud_outlined),
  qin('抚琴', Icons.music_note_outlined),
  stats('行迹', Icons.timeline_outlined),
  settings('设置', Icons.settings_outlined),
  tea('品茗', Icons.local_cafe_outlined);

  const SatoriPage(this.label, this.icon);
  final String label;
  final IconData icon;

  Color get accentColor {
    switch (this) {
      case SatoriPage.incense:
        return SatoriColors.incenseEmber;
      case SatoriPage.rain:
        return SatoriColors.rainCyan;
      case SatoriPage.qin:
        return SatoriColors.stringGold;
      case SatoriPage.stats:
        return SatoriColors.verdigris;
      case SatoriPage.settings:
        return SatoriColors.inkSmoke;
      case SatoriPage.tea:
        return SatoriColors.teaAmber;
    }
  }
}

/// 宣纸式隐藏功能栏 — U1/U2
///
/// 左侧滑出一张右侧边缘不整齐的宣纸，承载六个一级条目。
/// 右侧边缘通过 ClipPath 实现手撕纸质感。
class RicePaperDrawer extends StatelessWidget {
  final SatoriPage currentPage;
  final ValueChanged<SatoriPage> onPageSelected;
  final VoidCallback onClose;

  const RicePaperDrawer({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF2C2A26) // 暗色宣纸
        : SatoriColors.ricePaper;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor = isDark
        ? Colors.white38
        : SatoriColors.inkSmoke.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: GestureDetector(
          onTap: () {}, // 阻止冒泡关闭
          child: Align(
            alignment: Alignment.centerLeft,
            child: ClipPath(
              clipper: _TornEdgeClipper(),
              child: Container(
                width: 260,
                color: bgColor,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      // 品牌
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: SatoriTheme.spacingL),
                        child: Text(
                          'Satori',
                          style: SatoriTypography.largeTitle.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: SatoriTheme.spacingL),
                        child: Text(
                          '悟',
                          style: SatoriTypography.caption.copyWith(
                            color: subColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // 条目
                      ...SatoriPage.values.map((page) => _DrawerItem(
                            page: page,
                            isCurrent: page == currentPage,
                            textColor: textColor,
                            onTap: () {
                              HapticService.instance.lightTap();
                              onPageSelected(page);
                            },
                          )),

                      const Spacer(),

                      // 底部版本
                      Padding(
                        padding: const EdgeInsets.all(SatoriTheme.spacingL),
                        child: Text(
                          'v1.0.0',
                          style: SatoriTypography.caption.copyWith(
                            color: subColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final SatoriPage page;
  final bool isCurrent;
  final Color textColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.page,
    required this.isCurrent,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: SatoriTheme.spacingM,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SatoriTheme.spacingM,
          vertical: SatoriTheme.spacingM,
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? page.accentColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(SatoriTheme.cornerSmall),
        ),
        child: Row(
          children: [
            Icon(
              page.icon,
              size: 18,
              color: isCurrent ? page.accentColor : textColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: SatoriTheme.spacingM),
            Text(
              page.label,
              style: SatoriTypography.body.copyWith(
                color: isCurrent ? page.accentColor : textColor,
                fontWeight: isCurrent ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 右侧手撕宣纸边缘裁剪器。
/// 用伪随机锯齿模拟撕纸不整齐感。
class _TornEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);

    // 右侧不规则边缘
    final rng = Random(42); // 固定种子保证一致
    const step = 8.0;
    for (double y = 0; y <= size.height; y += step) {
      final jitter = rng.nextDouble() * 14 - 4; // -4 ~ +10
      path.lineTo(size.width + jitter, y);
    }

    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
