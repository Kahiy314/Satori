import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// 纸纹材质背景 — 焚香专用
///
/// 设计要点：
/// - 深色主题：暗色织物或纸纤维质感，非纯黑
/// - 浅色主题：温暖米白色纸面，非纯白
/// - 同一器物在晨昏两种光线下的状态
/// - 通过极淡的噪点纹理模拟纸张纤维
class PaperTextureBackground extends StatelessWidget {
  const PaperTextureBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _PaperTexturePainter(isDark: isDark),
      size: Size.infinite,
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  final bool isDark;
  _PaperTexturePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // ── 底色 ──
    final baseColor = isDark
        ? const Color(0xFF1A1A1C) // 暖黑，微带棕调
        : SatoriColors.ricePaper; // 宣纸米白

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = baseColor,
    );

    // ── 纸纤维纹理（极淡噪点） ──
    final rng = Random(42); // 固定 seed，每帧一致
    final dotPaint = Paint();
    final dotCount = (size.width * size.height / 80).toInt().clamp(0, 6000);

    for (var i = 0; i < dotCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final alpha = rng.nextDouble() * (isDark ? 0.06 : 0.04);
      final radius = rng.nextDouble() * 1.2 + 0.3;

      dotPaint.color = isDark
          ? Colors.white.withValues(alpha: alpha)
          : SatoriColors.sandalwood.withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }

    // ── 中央径向暗角（聚焦视线到中轴） ──
    final vignetteRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.15), // 偏上，因为主视觉在中上
        radius: 0.85,
        colors: [
          Colors.transparent,
          (isDark ? Colors.black : SatoriColors.sandalwood)
              .withValues(alpha: isDark ? 0.25 : 0.06),
        ],
        stops: const [0.5, 1.0],
      ).createShader(vignetteRect);
    canvas.drawRect(vignetteRect, vignettePaint);
  }

  @override
  bool shouldRepaint(_PaperTexturePainter old) => old.isDark != isDark;
}
