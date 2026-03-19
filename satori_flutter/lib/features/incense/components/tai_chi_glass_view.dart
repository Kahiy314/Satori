import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 太极烟雾意象 — 烟雾粒子聚成的太极
///
/// 参考图 1：太极由烟丝缠绕、流体勾勒、朦胧汇聚而成。
/// 实现：上千个烟雾粒子沿阴阳鱼轨迹运动，用粒子密度差来
/// 表达阴阳明暗，而不是色块叠加。
/// 整体缓慢旋转 + 呼吸脉动。
class TaiChiGlassView extends StatefulWidget {
  final double fillProgress;

  const TaiChiGlassView({super.key, this.fillProgress = 0});

  @override
  State<TaiChiGlassView> createState() => _TaiChiGlassViewState();
}

class _TaiChiGlassViewState extends State<TaiChiGlassView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final _TaiChiParticleEngine _engine;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _engine = _TaiChiParticleEngine();
    _ticker = createTicker((elapsed) {
      _time = elapsed.inMilliseconds / 1000.0;
      _engine.update(_time);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _TaiChiSmokePainter(
        engine: _engine,
        time: _time,
        isDark: isDark,
        fillProgress: widget.fillProgress,
      ),
      size: Size.infinite,
    );
  }
}

// ══════════════════════════════════════════════════════════
// 粒子引擎 — 维护 ~800 个烟雾粒子
// ══════════════════════════════════════════════════════════

class _TaiChiParticle {
  double x, y;       // 归一化坐标 [-1, 1]
  double vx, vy;     // 速度
  double life;        // 剩余生命 0→1
  double maxLife;
  double radius;
  bool isYin;         // 属于阴面还是阳面
  double orbitAngle;  // 在太极内的公转角
  double orbitRadius; // 距中心距离
  double drift;       // 个体随机漂移

  _TaiChiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.radius,
    required this.isYin,
    required this.orbitAngle,
    required this.orbitRadius,
    required this.drift,
  });
}

class _TaiChiParticleEngine {
  static const maxParticles = 800;
  static const spawnRate = 8; // 每帧生成

  final List<_TaiChiParticle> particles = [];
  final _rng = Random(42);
  double _rotation = 0; // 整体旋转角

  void update(double time) {
    // 整体旋转：60 秒一圈
    _rotation = time * 2 * pi / 60;

    // 生成新粒子
    for (var i = 0; i < spawnRate && particles.length < maxParticles; i++) {
      _spawn();
    }

    // 更新所有粒子
    for (var i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];

      // 生命衰减
      p.life -= 0.003 + _rng.nextDouble() * 0.002;

      if (p.life <= 0) {
        particles.removeAt(i);
        continue;
      }

      // 公转运动（跟随太极旋转）
      p.orbitAngle += 0.008 + p.drift * 0.004;

      // 轻微径向呼吸
      final breathOffset = sin(time * 0.8 + p.orbitAngle) * 0.02;

      // 计算目标位置（在旋转后的太极场中）
      final targetAngle = p.orbitAngle + _rotation;
      final targetR = p.orbitRadius + breathOffset;
      final targetX = cos(targetAngle) * targetR;
      final targetY = sin(targetAngle) * targetR;

      // 粒子向目标位置柔性移动（模拟烟雾的流体感）
      p.x += (targetX - p.x) * 0.06 + sin(time * 2 + p.drift * 10) * 0.003;
      p.y += (targetY - p.y) * 0.06 + cos(time * 1.5 + p.drift * 8) * 0.003;

      // 烟雾膨胀
      p.radius += 0.0005;
    }
  }

  void _spawn() {
    // 决定这个粒子属于阴面还是阳面
    final isYin = _rng.nextBool();

    // 在太极的阴阳鱼形状内生成
    // 太极的阴阳鱼：上半部一侧，下半部另一侧，各自有鱼头（小圆）
    // 根据 isYin 确定粒子应该聚集的区域
    // 阳面：angle 在右半+上方鱼头区域
    // 阴面：angle 在左半+下方鱼头区域
    double orbitAngle;
    double orbitR;

    if (isYin) {
      // 阴面粒子：主要在右半→下方区域
      orbitAngle = _rng.nextDouble() * pi + pi; // π ~ 2π (下半)
      orbitR = _rng.nextDouble() * 0.42 + 0.05;

      // 鱼头（在上方中心偏右）
      if (_rng.nextDouble() < 0.2) {
        orbitAngle = -pi / 2 + (_rng.nextDouble() - 0.5) * 0.8;
        orbitR = _rng.nextDouble() * 0.22 + 0.15;
      }
    } else {
      // 阳面粒子：主要在左半→上方区域
      orbitAngle = _rng.nextDouble() * pi; // 0 ~ π (上半)
      orbitR = _rng.nextDouble() * 0.42 + 0.05;

      // 鱼头（在下方中心偏左）
      if (_rng.nextDouble() < 0.2) {
        orbitAngle = pi / 2 + (_rng.nextDouble() - 0.5) * 0.8;
        orbitR = _rng.nextDouble() * 0.22 + 0.15;
      }
    }

    // 鱼眼：在对方区域内放一些反色粒子
    bool actualYin = isYin;
    if (_rng.nextDouble() < 0.06) {
      // 少量粒子出现在对侧（形成鱼眼）
      actualYin = !isYin;
      orbitR = _rng.nextDouble() * 0.08 + 0.18; // 在鱼头中心附近
    }

    final startAngle = orbitAngle + _rotation;
    final px = cos(startAngle) * orbitR;
    final py = sin(startAngle) * orbitR;

    particles.add(_TaiChiParticle(
      x: px,
      y: py,
      vx: 0,
      vy: 0,
      life: 1.0,
      maxLife: 1.0,
      radius: 0.015 + _rng.nextDouble() * 0.025,
      isYin: actualYin,
      orbitAngle: orbitAngle,
      orbitRadius: orbitR,
      drift: _rng.nextDouble(),
    ));
  }
}

// ══════════════════════════════════════════════════════════
// 渲染器
// ══════════════════════════════════════════════════════════

class _TaiChiSmokePainter extends CustomPainter {
  final _TaiChiParticleEngine engine;
  final double time;
  final bool isDark;
  final double fillProgress;

  _TaiChiSmokePainter({
    required this.engine,
    required this.time,
    required this.isDark,
    required this.fillProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final r = s / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // 呼吸缩放
    final breathScale = 0.97 + sin(time * 0.5) * 0.03;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(breathScale);

    // 圆形裁切（太极外轮廓）
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 1.05)),
    );

    // ── 极淡的底色光晕（让整体有存在感） ──
    final haloColor = (isDark ? Colors.white : Colors.grey)
        .withValues(alpha: 0.04);
    canvas.drawCircle(
      Offset.zero,
      r * 1.1,
      Paint()
        ..shader = RadialGradient(
          colors: [haloColor, Colors.transparent],
          stops: const [0.3, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.1)),
    );

    // ── 绘制所有粒子 ──
    for (final p in engine.particles) {
      final px = p.x * r;
      final py = p.y * r;
      final particleR = p.radius * r;

      // 透明度基于生命值
      final lifeAlpha = p.life * p.life; // 平方衰减更自然

      // 阴面粒子更亮（在深色模式中更白，浅色模式更深）
      // 阳面粒子更暗
      Color particleColor;
      if (p.isYin) {
        // 阴面 = 深色/浓烟
        particleColor = isDark
            ? Colors.white.withValues(alpha: 0.42 * lifeAlpha)
            : const Color(0xFF3A3A3A).withValues(alpha: 0.38 * lifeAlpha);
      } else {
        // 阳面 = 浅色/淡烟
        particleColor = isDark
            ? Colors.white.withValues(alpha: 0.15 * lifeAlpha)
            : const Color(0xFF8A8A8A).withValues(alpha: 0.15 * lifeAlpha);
      }

      // 烟雾模糊
      final paint = Paint()
        ..color = particleColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particleR * 1.2);

      canvas.drawCircle(Offset(px, py), particleR, paint);
    }

    // ── 极淡圆形轮廓（让太极有边界感） ──
    canvas.drawCircle(
      Offset.zero,
      r * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = (isDark ? Colors.white : Colors.grey)
            .withValues(alpha: 0.06),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TaiChiSmokePainter old) => true;
}
