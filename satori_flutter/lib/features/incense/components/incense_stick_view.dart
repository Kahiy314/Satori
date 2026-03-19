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

/// 香炉 — 文人案头青瓷/青铜器物
///
/// 参考图中的香炉：矮胖圆腹，有明确的炉口沿、鼓腹、收底、底足。
/// 用贝塞尔曲线画出真正的器型剖面，而不是椭圆。
/// 浅色模式：青灰绿瓷釉质感；深色模式：暗铜绿。
class IncenseBurnerView extends StatelessWidget {
  const IncenseBurnerView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BurnerPainter(
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      size: Size.infinite,
    );
  }
}

class _BurnerPainter extends CustomPainter {
  final bool isDark;
  _BurnerPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── 色彩体系 ──
    final bodyLight = isDark ? const Color(0xFF5E7068) : const Color(0xFF8BA89A);
    final bodyDark = isDark ? const Color(0xFF3A4D42) : const Color(0xFF607B6C);
    final rimColor = isDark ? const Color(0xFF6E8377) : const Color(0xFF9AB8A8);
    final innerColor = isDark
        ? Colors.black.withValues(alpha: 0.50)
        : const Color(0xFF3A4A40).withValues(alpha: 0.45);
    final highlightAlpha = isDark ? 0.06 : 0.20;

    // ── 关键点位（相对于 size） ──
    // 参考图：矮胖圆腹，宽高比约 2:1
    final rimTop = h * 0.08;       // 炉口上沿
    final rimBot = h * 0.18;       // 炉口下沿（口沿厚度）
    final bellyTop = h * 0.30;     // 腹部开始鼓出
    final bellyPeak = h * 0.52;    // 腹部最宽处
    final bellyBot = h * 0.72;     // 腹部收窄
    final footTop = h * 0.80;      // 底足开始
    final footBot = h * 0.92;      // 底足底面

    final rimW = w * 0.72;         // 炉口宽度
    final bellyW = w * 0.92;       // 腹部最宽处
    final footW = w * 0.45;        // 底足宽度
    final neckW = w * 0.65;        // 颈部（口沿下方）

    // ── 1. 炉身主体路径（左剖面 → 右剖面，闭合） ──
    final bodyPath = Path();

    // 从左侧炉口开始，顺时针
    bodyPath.moveTo(cx - rimW / 2, rimBot);

    // 左侧：口沿下 → 颈部收窄 → 腹部膨出 → 底部收窄 → 底足
    bodyPath.cubicTo(
      cx - neckW / 2, bellyTop,    // 控制点1：颈部收窄
      cx - bellyW / 2, bellyTop,   // 控制点2：向外膨出
      cx - bellyW / 2, bellyPeak,  // 终点：腹部最宽
    );
    bodyPath.cubicTo(
      cx - bellyW / 2, bellyBot,   // 控制点1
      cx - footW / 2 - 4, footTop, // 控制点2：收底
      cx - footW / 2, footBot,     // 终点：底足左
    );

    // 底部
    bodyPath.lineTo(cx + footW / 2, footBot);

    // 右侧：底足 → 收窄 → 腹部膨出 → 颈部 → 口沿（镜像）
    bodyPath.cubicTo(
      cx + footW / 2 + 4, footTop,
      cx + bellyW / 2, bellyBot,
      cx + bellyW / 2, bellyPeak,
    );
    bodyPath.cubicTo(
      cx + bellyW / 2, bellyTop,
      cx + neckW / 2, bellyTop,
      cx + rimW / 2, rimBot,
    );

    bodyPath.close();

    // ── 2. 绘制炉身（渐变填充） ──
    final bodyRect = Rect.fromLTWH(0, rimBot, w, footBot - rimBot);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bodyLight, bodyDark],
        stops: const [0.2, 0.9],
      ).createShader(bodyRect);
    canvas.drawPath(bodyPath, bodyPaint);

    // ── 3. 左侧高光条（模拟瓷釉反光，沿炉身弧面） ──
    final hlPath = Path();
    final hlLeft = cx - bellyW / 2 + bellyW * 0.12;
    hlPath.moveTo(hlLeft, bellyTop + 4);
    hlPath.quadraticBezierTo(
      hlLeft - 3, bellyPeak,
      hlLeft + 6, bellyBot - 4,
    );
    canvas.drawPath(
      hlPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bellyW * 0.06
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: highlightAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── 4. 炉口（椭圆开口 — 俯视椭圆 + 口沿厚度） ──
    // 口沿外圈
    final rimOuter = Rect.fromCenter(
      center: Offset(cx, rimTop + (rimBot - rimTop) / 2),
      width: rimW + 4,
      height: (rimBot - rimTop) * 1.8,
    );
    canvas.drawOval(rimOuter, Paint()..color = rimColor);

    // 口沿内暗面（炉口内部看进去是暗的）
    final rimInner = Rect.fromCenter(
      center: Offset(cx, rimTop + (rimBot - rimTop) / 2 + 1),
      width: rimW - 6,
      height: (rimBot - rimTop) * 1.2,
    );
    canvas.drawOval(rimInner, Paint()..color = innerColor);

    // 口沿顶部细高光线
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, rimTop + (rimBot - rimTop) * 0.3),
        width: rimW - 2,
        height: (rimBot - rimTop) * 0.5,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: highlightAlpha * 0.8),
    );

    // ── 5. 底足横线 ──
    canvas.drawLine(
      Offset(cx - footW / 2 + 2, footBot),
      Offset(cx + footW / 2 - 2, footBot),
      Paint()
        ..color = bodyDark.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // ── 6. 整体轮廓描边（极细铜绿线，增加器物感） ──
    canvas.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = SatoriColors.verdigris.withValues(alpha: isDark ? 0.20 : 0.30),
    );
  }

  @override
  bool shouldRepaint(_BurnerPainter old) => old.isDark != isDark;
}

/// 香炉前沿 — 仅绘制近侧（下半）炉口弧
///
/// 在 Stack 中覆盖于香身之上，实现"香身穿过炉口，
/// 远侧炉口沿在香身后、近侧炉口沿在香身前"的正确透视遮挡。
class IncenseBurnerFrontRim extends StatelessWidget {
  const IncenseBurnerFrontRim({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FrontRimPainter(
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      size: Size.infinite,
    );
  }
}

class _FrontRimPainter extends CustomPainter {
  final bool isDark;
  _FrontRimPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final rimColor = isDark ? const Color(0xFF6E8377) : const Color(0xFF9AB8A8);
    final highlightAlpha = isDark ? 0.06 : 0.20;

    // 与 _BurnerPainter 完全一致的炉口几何
    final rimTop = h * 0.08;
    final rimBot = h * 0.18;
    final rimW = w * 0.72;
    final rimCenterY = rimTop + (rimBot - rimTop) / 2;

    // 只绘制椭圆的下半（近侧/前沿）
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, rimCenterY, w, h - rimCenterY));

    // 外沿弧
    final rimOuter = Rect.fromCenter(
      center: Offset(cx, rimCenterY),
      width: rimW + 4,
      height: (rimBot - rimTop) * 1.8,
    );
    canvas.drawOval(rimOuter, Paint()..color = rimColor);

    // 前沿高光
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, rimCenterY + 1),
        width: rimW,
        height: (rimBot - rimTop) * 1.4,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(alpha: highlightAlpha * 0.7),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FrontRimPainter old) => old.isDark != isDark;
}
