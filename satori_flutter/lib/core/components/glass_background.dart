import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// 毛玻璃背景组件
/// 三层叠加：模糊 + 颜色覆盖层（深浅模式不同）+ 细描边
class GlassBackground extends StatelessWidget {
  final double cornerRadius;
  final double opacity;

  const GlassBackground({
    super.key,
    this.cornerRadius = SatoriTheme.cornerLarge,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? SatoriColors.glassDark : SatoriColors.glassLight;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.5);

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: SatoriTheme.blurLight,
          sigmaY: SatoriTheme.blurLight,
        ),
        child: Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(cornerRadius),
              border: Border.all(color: borderColor, width: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
