import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// 香头余烬（炭火闷烧效果）
/// 暗红灼热点 + 微弱光晕脉动
class IncenseEmberView extends StatefulWidget {
  const IncenseEmberView({super.key});

  @override
  State<IncenseEmberView> createState() => _IncenseEmberViewState();
}

class _IncenseEmberViewState extends State<IncenseEmberView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => CustomPaint(
        painter: _EmberPainter(scale: _pulse.value),
        size: const Size(14, 10),
      ),
    );
  }
}

class _EmberPainter extends CustomPainter {
  final double scale;
  _EmberPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 最外层光晕
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          SatoriColors.incenseEmber.withValues(alpha: 0.15),
          SatoriColors.incenseEmber.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 16 * scale, height: 16 * scale));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 16 * scale, height: 12 * scale),
      outerPaint,
    );

    // 中间灼热圈
    final midPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          SatoriColors.incenseEmber.withValues(alpha: 0.5),
          SatoriColors.incenseEmber.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 8, height: 6));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 6 * scale, height: 4 * scale),
      midPaint,
    );

    // 核心亮点
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE85D3A).withValues(alpha: 0.8),
          SatoriColors.incenseEmber.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 5, height: 4));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 4 / scale, height: 3 / scale),
      corePaint,
    );
  }

  @override
  bool shouldRepaint(_EmberPainter old) => old.scale != scale;
}
