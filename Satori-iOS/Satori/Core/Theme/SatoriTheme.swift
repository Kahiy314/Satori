import SwiftUI

// MARK: - 全局主题常量

struct SatoriTheme {
    // ── 圆角 ──
    static let cornerSmall:  CGFloat = 8
    static let cornerMedium: CGFloat = 16
    static let cornerLarge:  CGFloat = 24
    static let cornerPill:   CGFloat = 9999   // 胶囊形

    // ── 间距 ──
    static let spacingXS:  CGFloat = 4
    static let spacingS:   CGFloat = 8
    static let spacingM:   CGFloat = 16
    static let spacingL:   CGFloat = 24
    static let spacingXL:  CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // ── 动画时长 ──
    static let animFast:   Double = 0.15
    static let animNormal: Double = 0.3
    static let animSlow:   Double = 0.6

    // ── 模糊 ──
    static let blurLight:  CGFloat = 20
    static let blurHeavy:  CGFloat = 40

    // ── 阴影 ──
    static let shadowSubtle = SatoriShadow(color: .black.opacity(0.06), radius: 8, y: 2)
    static let shadowMedium = SatoriShadow(color: .black.opacity(0.12), radius: 16, y: 4)
}

struct SatoriShadow {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

// MARK: - View Modifier: 阴影

extension View {
    func satoriShadow(_ shadow: SatoriShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}
