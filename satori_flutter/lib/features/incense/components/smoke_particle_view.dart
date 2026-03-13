import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 烟雾粒子系统
/// 轻量级粒子：最多 300 个半透明圆点，缓慢上升 + 水平漂移 + 渐隐
class SmokeParticleView extends StatefulWidget {
  final double burnProgress;
  final double opacity;

  const SmokeParticleView({
    super.key,
    this.burnProgress = 0,
    this.opacity = 1.0,
  });

  @override
  State<SmokeParticleView> createState() => _SmokeParticleViewState();
}

class _SmokeParticleViewState extends State<SmokeParticleView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _engine = _SmokeEngine();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      _engine.burnProgress = widget.burnProgress;
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
    return Opacity(
      opacity: widget.opacity,
      child: CustomPaint(
        painter: _SmokePainter(_engine),
        size: Size.infinite,
      ),
    );
  }
}

class _SmokeEngine {
  final List<_SmokeParticle> particles = [];
  static const _maxParticles = 300;
  static const _spawnPerFrame = 2;
  double burnProgress = 0;
  final _rng = Random();

  void update(Size size) {
    // 生成
    for (var i = 0; i < _spawnPerFrame && particles.length < _maxParticles; i++) {
      particles.add(_SmokeParticle(
        x: size.width / 2 + _rng.nextDouble() * 8 - 4,
        y: size.height,
        vx: _rng.nextDouble() * 0.6 - 0.3,
        vy: -(_rng.nextDouble() * 1.0 + 0.5),
        radius: _rng.nextDouble() * 4 + 2,
        opacity: _rng.nextDouble() * 0.12 + 0.08,
        life: 1.0,
        decay: _rng.nextDouble() * 0.005 + 0.003,
      ));
    }

    // 更新
    for (var i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.x += p.vx + sin(p.y * 0.02) * 0.15;
      p.y += p.vy;
      p.life -= p.decay;
      p.radius += 0.03;
      if (p.life <= 0) {
        particles.removeAt(i);
      }
    }
  }
}

class _SmokeParticle {
  double x, y, vx, vy, radius, opacity, life, decay;
  _SmokeParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
    required this.life,
    required this.decay,
  });
}

class _SmokePainter extends CustomPainter {
  final _SmokeEngine engine;
  _SmokePainter(this.engine);

  @override
  void paint(Canvas canvas, Size size) {
    engine.update(size);

    final paint = Paint()..maskFilter = null;

    for (final p in engine.particles) {
      final alpha = p.opacity * p.life;
      if (alpha < 0.005) continue;

      paint
        ..color = Colors.grey.withValues(alpha: (0.6 * alpha))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.5);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(p.x, p.y),
          width: p.radius * 2,
          height: p.radius * 2,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
