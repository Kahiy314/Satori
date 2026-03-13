import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// 香身（竖直渐变线条 — 仅渲染未燃段 + 顶部薄灰 + 发光线）
class IncenseStickView extends StatelessWidget {
  final double burnProgress;

  const IncenseStickView({super.key, required this.burnProgress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StickPainter(burnProgress: burnProgress),
      size: Size.infinite,
    );
  }
}

class _StickPainter extends CustomPainter {
  final double burnProgress;
  _StickPainter({required this.burnProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ashHeight = burnProgress > 0.01 ? (h * 0.08).clamp(0.0, 6.0) : 0.0;
    final bodyRadius = w / 3;

    // 未燃部分
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(bodyRadius),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [SatoriColors.sandalwood, Color(0xD98B6B4A)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(bodyRect, bodyPaint);

    // 顶端薄灰层
    if (ashHeight > 0) {
      final ashPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.withValues(alpha: 0.35), Colors.grey.withValues(alpha: 0.5)],
        ).createShader(Rect.fromLTWH(0, 0, w, ashHeight));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, ashHeight), ashPaint);

      // 发光线
      final glowPaint = Paint()
        ..color = SatoriColors.incenseEmber.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawRect(Rect.fromLTWH(0, ashHeight, w, 1.5), glowPaint);
    }
  }

  @override
  bool shouldRepaint(_StickPainter old) => old.burnProgress != burnProgress;
}

/// 香炉
class IncenseBurnerView extends StatelessWidget {
  const IncenseBurnerView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BurnerPainter(),
      size: Size.infinite,
    );
  }
}

class _BurnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 炉身
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [SatoriColors.sandalwood, Color(0xB38B6B4A)],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: size.width, height: size.height));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: size.width, height: size.height),
      bodyPaint,
    );

    // 炉口
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 15),
        width: size.width * 0.85,
        height: size.height * 0.3,
      ),
      Paint()..color = SatoriColors.inkSmoke.withValues(alpha: 0.3),
    );

    // 铜绿描边
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: size.width, height: size.height),
      Paint()
        ..color = SatoriColors.verdigris.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
