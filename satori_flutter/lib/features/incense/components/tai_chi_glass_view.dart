import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// 太极 Liquid Glass 容器
/// 烟雾汇聚的太极形容器，匀速旋转
class TaiChiGlassView extends StatefulWidget {
  final double fillProgress;

  const TaiChiGlassView({super.key, this.fillProgress = 0});

  @override
  State<TaiChiGlassView> createState() => _TaiChiGlassViewState();
}

class _TaiChiGlassViewState extends State<TaiChiGlassView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _rotation,
      builder: (_, __) {
        return Transform.rotate(
          angle: _rotation.value * 2 * 3.14159265,
          child: CustomPaint(
            painter: _TaiChiPainter(
              fillProgress: widget.fillProgress,
              isDark: isDark,
            ),
          ),
        );
      },
    );
  }
}

class _TaiChiPainter extends CustomPainter {
  final double fillProgress;
  final bool isDark;

  _TaiChiPainter({required this.fillProgress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final r = s / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final smallR = r / 2;
    final eyeR = s * 0.07;

    final yinColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.55);
    final yangColor = isDark
        ? Colors.black.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.65);

    canvas.save();
    // 圆形裁切
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    // 1. 阴底色
    canvas.drawCircle(center, r, Paint()..color = yinColor);

    // 2. 阳右半
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(center.dx, center.dy - r, r, s));
    canvas.drawCircle(center, r, Paint()..color = yangColor);
    canvas.restore();

    // 3. 阳鱼头（上方）
    canvas.drawCircle(
      Offset(center.dx, center.dy - smallR),
      smallR,
      Paint()..color = yangColor,
    );

    // 4. 阴鱼头（下方）
    canvas.drawCircle(
      Offset(center.dx, center.dy + smallR),
      smallR,
      Paint()..color = yinColor,
    );

    // 5. 阳鱼眼
    canvas.drawCircle(
      Offset(center.dx, center.dy - smallR),
      eyeR,
      Paint()..color = yinColor,
    );

    // 6. 阴鱼眼
    canvas.drawCircle(
      Offset(center.dx, center.dy + smallR),
      eyeR,
      Paint()..color = yangColor,
    );

    // 烟雾汇聚效果
    if (fillProgress > 0) {
      final smokePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            SatoriColors.inkSmoke.withValues(alpha: 0.18 * fillProgress),
            SatoriColors.inkSmoke.withValues(alpha: 0.05 * fillProgress),
            Colors.transparent,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.85));
      canvas.drawCircle(center, r * 0.85, smokePaint);
    }

    // 玻璃高光描边
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TaiChiPainter old) =>
      old.fillProgress != fillProgress || old.isDark != isDark;
}
