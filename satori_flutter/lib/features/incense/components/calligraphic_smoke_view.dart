import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 书法游丝烟雾 — 从香顶升起的连续曲线烟
///
/// 参考图 2：烟呈柔和游丝状曲线，清晰可见，从香顶缓慢上升。
/// 每条烟丝由多段分别绘制，alpha 从底部到顶部渐隐。
class CalligraphicSmokeView extends StatefulWidget {
  final double opacity;
  final double burnProgress;

  const CalligraphicSmokeView({
    super.key,
    this.opacity = 1.0,
    this.burnProgress = 0,
  });

  @override
  State<CalligraphicSmokeView> createState() => _CalligraphicSmokeViewState();
}

class _CalligraphicSmokeViewState extends State<CalligraphicSmokeView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time = elapsed.inMilliseconds / 1000.0;
      setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeIn,
        opacity: widget.opacity,
        child: CustomPaint(
          painter: _CalligraphicSmokePainter(
            time: _time,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CalligraphicSmokePainter extends CustomPainter {
  final double time;
  final bool isDark;

  _CalligraphicSmokePainter({required this.time, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 三束游丝，各自有不同的摆幅、速度和粗细
    _drawStrand(canvas, cx, h, ampX: 15, speed: 0.4, phase: 0.0, baseAlpha: 0.45, strokeW: 1.8);
    _drawStrand(canvas, cx, h, ampX: 22, speed: 0.28, phase: 1.5, baseAlpha: 0.25, strokeW: 2.8);
    _drawStrand(canvas, cx, h, ampX: 30, speed: 0.18, phase: 3.2, baseAlpha: 0.12, strokeW: 4.5);
  }

  void _drawStrand(Canvas canvas, double cx, double h, {
    required double ampX,
    required double speed,
    required double phase,
    required double baseAlpha,
    required double strokeW,
  }) {
    final baseColor = isDark ? Colors.white : const Color(0xFF8A8A8A);
    const segments = 60;
    final segH = h / segments;

    // 计算所有点位
    final points = <Offset>[];
    for (var i = 0; i <= segments; i++) {
      final y = h - i * segH; // 从底向上
      final t = i / segments; // 0=底, 1=顶

      // 正弦叠加产生优雅曲线
      final s1 = sin(t * 4.0 * pi + phase + time * speed) * ampX * t;
      final s2 = sin(t * 2.5 * pi + phase * 0.7 + time * speed * 0.6) * ampX * 0.4 * t;
      final x = cx + s1 + s2;
      points.add(Offset(x, y));
    }

    // 逐段绘制，每段独立 alpha
    for (var i = 0; i < points.length - 1; i++) {
      final t = i / segments;
      // 底部不透明，顶部渐隐
      final alpha = baseAlpha * (1.0 - t * t) ; // 二次衰减
      if (alpha < 0.01) continue;

      // 笔触粗细：底部略细（刚升起），中段最粗（扩散），顶部再次变细（消散）
      final widthMult = sin(t * pi) * 0.6 + 0.4; // 0.4 ~ 1.0 ~ 0.4

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * widthMult
        ..strokeCap = StrokeCap.round
        ..color = baseColor.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeW * widthMult * 0.6);

      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(_CalligraphicSmokePainter old) => true;
}
