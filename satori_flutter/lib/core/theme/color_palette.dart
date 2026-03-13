import 'package:flutter/material.dart';

/// Satori 色彩体系
/// 核心色集中在焦点元素（香炉、琴、茶具），背景跟随系统浅/深
class SatoriColors {
  SatoriColors._();

  // ── 核心暖色 ──
  /// 香火橘红 — 焚香模块主色
  static const incenseEmber = Color(0xFFC45C3C);

  /// 檀木棕 — 香炉、琴身等木质元素
  static const sandalwood = Color(0xFF8B6B4A);

  /// 铜绿 — 香炉铜锈点缀
  static const verdigris = Color(0xFF5F8575);

  // ── 辅助冷色 ──
  /// 烟墨灰 — 烟雾、文字
  static const inkSmoke = Color(0xFF4A4A4A);

  /// 雨青 — 听雨模块主色
  static const rainCyan = Color(0xFF7BA7A7);

  /// 琴弦金 — 抚琴模块点缀
  static const stringGold = Color(0xFFC9A96E);

  /// 茶汤琥珀 — 品茗模块主色
  static const teaAmber = Color(0xFFC48A3F);

  // ── 中性色 ──
  /// 宣纸白（浅模式背景色的叠加层）
  static const ricePaper = Color(0xFFF5F0E8);

  /// 墨砚黑（深模式背景色的叠加层）
  static const inkStone = Color(0xFF1C1C1E);

  // ── 玻璃材质 ──
  static const glassLight = Color(0x73FFFFFF); // white 0.45
  static const glassDark = Color(0x14FFFFFF);  // white 0.08
}
