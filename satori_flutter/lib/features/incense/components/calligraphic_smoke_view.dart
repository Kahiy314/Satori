import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 公式型游丝烟雾
///
/// 基于 x = a * y * sin(y + φ) 构建烟丝轮廓，其中：
/// - a(t) = 0.5 * sin(2πt / T)，控制左右轻微摆动
/// - φ 随时间推进，让烟看起来像持续上升，而不是原地晃动
/// - y 从 0 到 2π 映射到烟雾的整体高度，并在上升过程中逐渐透明
class CalligraphicSmokeView extends StatefulWidget {
  final double opacity;
  final Color color;
  final Duration swayPeriod;
  final double riseSpeed;

  const CalligraphicSmokeView({
    super.key,
    this.opacity = 1.0,
    this.color = const Color(0xFF8C8882),
    this.swayPeriod = const Duration(seconds: 3),
    this.riseSpeed = 1.1,
  });

  @override
  State<CalligraphicSmokeView> createState() => _CalligraphicSmokeViewState();
}

class _CalligraphicSmokeViewState extends State<CalligraphicSmokeView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _timeSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      _timeSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
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
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          opacity: widget.opacity,
          child: CustomPaint(
            painter: _CalligraphicSmokePainter(
              timeSeconds: _timeSeconds,
              baseColor: widget.color,
              swayPeriod: widget.swayPeriod,
              riseSpeed: widget.riseSpeed,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _CalligraphicSmokePainter extends CustomPainter {
  final double timeSeconds;
  final Color baseColor;
  final Duration swayPeriod;
  final double riseSpeed;

  _CalligraphicSmokePainter({
    required this.timeSeconds,
    required this.baseColor,
    required this.swayPeriod,
    required this.riseSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawStrand(
      canvas,
      size,
      lateralShift: 0,
      phaseOffset: 0,
      widthFactor: 1.0,
      alphaFactor: 0.34,
    );
  }

  void _drawStrand(
    Canvas canvas,
    Size size, {
    required double lateralShift,
    required double phaseOffset,
    required double widthFactor,
    required double alphaFactor,
  }) {
    const maxParamY = math.pi * 2;
    const segments = 64;
    final swayCycleSeconds = swayPeriod.inMilliseconds / 1000.0;
    final amplitude = 0.5 *
        math.sin((2 * math.pi * timeSeconds / swayCycleSeconds) +
            phaseOffset * 0.35);
    final animatedPhase = timeSeconds * riseSpeed + phaseOffset;
    final origin = Offset(size.width / 2 + lateralShift, size.height * 0.90);
    final verticalExtent = size.height * 0.84;
    final horizontalScale = size.width * 0.065 * widthFactor;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset? previous;
    for (var i = 0; i <= segments; i++) {
      final progress = i / segments;
      final yValue = progress * maxParamY;
      final x = origin.dx +
          amplitude *
              yValue *
              math.sin(yValue + animatedPhase) *
              horizontalScale;
      final y = origin.dy - progress * verticalExtent;
      final current = Offset(x, y);

      if (previous != null) {
        final fade = math.pow(1 - progress, 1.8).toDouble();
        final strokeWidth = (2.2 - 1.5 * progress) * widthFactor;
        paint
          ..strokeWidth = strokeWidth
          ..color = baseColor.withValues(alpha: alphaFactor * fade)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.7);
        canvas.drawLine(previous, current, paint);
      }

      previous = current;
    }
  }

  @override
  bool shouldRepaint(_CalligraphicSmokePainter old) =>
      old.timeSeconds != timeSeconds ||
      old.baseColor != baseColor ||
      old.swayPeriod != swayPeriod ||
      old.riseSpeed != riseSpeed;
}
