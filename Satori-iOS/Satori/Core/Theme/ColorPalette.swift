import SwiftUI

// MARK: - 色彩体系
// 核心色集中在焦点元素（香炉、琴、茶具），背景跟随系统浅/深

struct SatoriColors {
    // ── 核心暖色 ──
    /// 香火橘红 —— 焚香模块主色
    static let incenseEmber   = Color(hex: "C45C3C")
    /// 檀木棕   —— 香炉、琴身等木质元素
    static let sandalwood     = Color(hex: "8B6B4A")
    /// 铜绿     —— 香炉铜锈点缀
    static let verdigris      = Color(hex: "5F8575")

    // ── 辅助冷色 ──
    /// 烟墨灰   —— 烟雾、文字
    static let inkSmoke       = Color(hex: "4A4A4A")
    /// 雨青     —— 听雨模块主色
    static let rainCyan       = Color(hex: "7BA7A7")
    /// 琴弦金   —— 抚琴模块点缀
    static let stringGold     = Color(hex: "C9A96E")
    /// 茶汤琥珀 —— 品茗模块主色
    static let teaAmber       = Color(hex: "C48A3F")

    // ── 中性色 ──
    /// 宣纸白（浅模式背景色的叠加层）
    static let ricePaper      = Color(hex: "F5F0E8")
    /// 墨砚黑（深模式背景色的叠加层）
    static let inkStone       = Color(hex: "1C1C1E")

    // ── 玻璃材质 ──
    static let glassLight = Color.white.opacity(0.45)
    static let glassDark  = Color.white.opacity(0.08)
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: .alphanumerics.inverted))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}
