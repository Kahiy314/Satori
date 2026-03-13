import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// 声波动画 — 多条正弦波叠加
class AudioWaveView extends StatelessWidget {
  final double phase;

  const AudioWaveView({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavePainter(phase: phase),
      size: Size.infinite,
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  _WavePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;

    final waves = [
      (amp: 12.0, freq: 1.5, phaseOffset: 0.0, alpha: 0.3),
      (amp: 8.0, freq: 2.5, phaseOffset: pi / 3, alpha: 0.2),
      (amp: 5.0, freq: 4.0, phaseOffset: pi / 1.5, alpha: 0.15),
    ];

    for (final wave in waves) {
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 1) {
        final relX = x / size.width;
        final y = midY +
            wave.amp *
                sin(relX * wave.freq * pi * 2 + phase + wave.phaseOffset);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = SatoriColors.rainCyan.withValues(alpha: wave.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}
