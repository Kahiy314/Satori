import 'package:flutter/material.dart';

/// 全局主题常量
class SatoriTheme {
  SatoriTheme._();

  // ── 圆角 ──
  static const cornerSmall = 8.0;
  static const cornerMedium = 16.0;
  static const cornerLarge = 24.0;
  static const cornerPill = 9999.0;

  // ── 间距 ──
  static const spacingXS = 4.0;
  static const spacingS = 8.0;
  static const spacingM = 16.0;
  static const spacingL = 24.0;
  static const spacingXL = 32.0;
  static const spacingXXL = 48.0;

  // ── 动画时长 ──
  static const animFast = Duration(milliseconds: 150);
  static const animNormal = Duration(milliseconds: 300);
  static const animSlow = Duration(milliseconds: 600);

  // ── 模糊 ──
  static const blurLight = 20.0;
  static const blurHeavy = 40.0;

  // ── 阴影 ──
  static const shadowSubtle = BoxShadow(
    color: Color(0x0F000000), // 0.06
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const shadowMedium = BoxShadow(
    color: Color(0x1F000000), // 0.12
    blurRadius: 16,
    offset: Offset(0, 4),
  );
}
