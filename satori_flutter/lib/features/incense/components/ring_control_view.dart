import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// 圆环控制点 — 焚香界面的低干扰操作元素
///
/// 参考图中时间下方的圆环形按钮：
/// - 视觉上像"暂停/继续/确认"的低干扰控制点
/// - 静态时只是极细的圆环
/// - 运行时内部有极淡的进度弧
/// - 不破坏安静感
class RingControlView extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double progress; // 0→1, 用于进度弧
  final bool isActive;

  const RingControlView({
    super.key,
    required this.onTap,
    required this.icon,
    this.progress = 0,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isActive
        ? SatoriColors.incenseEmber.withValues(alpha: 0.6)
        : (isDark ? Colors.white : SatoriColors.inkSmoke)
            .withValues(alpha: 0.2);
    final iconColor = isActive
        ? SatoriColors.incenseEmber.withValues(alpha: 0.8)
        : (isDark ? Colors.white : SatoriColors.inkSmoke)
            .withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 52,
        child: CustomPaint(
          painter: _RingPainter(
            ringColor: ringColor,
            progress: progress,
            isActive: isActive,
          ),
          child: Center(
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color ringColor;
  final double progress;
  final bool isActive;

  _RingPainter({
    required this.ringColor,
    required this.progress,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 1;

    // 底圈
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ringColor,
    );

    // 进度弧
    if (progress > 0 && isActive) {
      final arcRect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(
        arcRect,
        -1.5708, // -π/2, 从顶部开始
        progress * 6.2832, // 2π
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..color = SatoriColors.incenseEmber.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ringColor != ringColor ||
      old.progress != progress ||
      old.isActive != isActive;
}
