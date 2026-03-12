import SwiftUI

// MARK: - 字体体系
// 中文主字体采用系统宋体/黑体，西文使用系统衬线体
// 标题用纤细体量呈现"留白"气质，正文用常规字重保证可读性

struct SatoriTypography {
    // ── 标题 ──
    /// 大标题 —— 页面顶部功能名，如"焚香"
    static let largeTitle = Font.system(size: 34, weight: .thin, design: .serif)
    /// 中标题 —— 卡片标题、弹窗标题
    static let title      = Font.system(size: 22, weight: .light, design: .serif)
    /// 小标题
    static let subtitle   = Font.system(size: 17, weight: .regular, design: .serif)

    // ── 正文 ──
    static let body       = Font.system(size: 15, weight: .regular, design: .default)
    static let caption    = Font.system(size: 12, weight: .regular, design: .default)

    // ── 特殊 ──
    /// 计时器数字 —— 等宽衬线
    static let timer      = Font.system(size: 56, weight: .ultraLight, design: .serif)
        .monospacedDigit()
    /// TabBar 标签
    static let tabLabel   = Font.system(size: 10, weight: .medium, design: .default)
}
