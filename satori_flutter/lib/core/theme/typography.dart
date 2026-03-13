import 'package:flutter/material.dart';

/// Satori 字体体系
/// 标题用纤细体量呈现"留白"气质，正文用常规字重保证可读性
class SatoriTypography {
  SatoriTypography._();

  // ── 标题 ──
  /// 大标题 — 页面顶部功能名，如"焚香"
  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w100,
    height: 1.2,
  );

  /// 中标题 — 卡片标题、弹窗标题
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w300,
    height: 1.3,
  );

  /// 小标题
  static const subtitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ── 正文 ──
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ── 特殊 ──
  /// 计时器数字 — 等宽衬线
  static const timer = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w100,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// TabBar 标签
  static const tabLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}
