import SwiftUI

// MARK: - 香头余烬（炭火闷烧效果）
// 无火焰，仅有暗红灼热点 + 微弱光晕，模拟香的炭化燃烧
// 灰烬脱落后露出的烧红烛芯效果

struct IncenseEmberView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            // 最外层 —— 极淡的热辐射光晕
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            SatoriColors.incenseEmber.opacity(0.15),
                            SatoriColors.incenseEmber.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: 8
                    )
                )
                .scaleEffect(pulse ? 1.05 : 0.95)

            // 中间层 —— 暗红灼热圈
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            SatoriColors.incenseEmber.opacity(0.5),
                            SatoriColors.incenseEmber.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 4
                    )
                )
                .frame(width: 6, height: 4)
                .scaleEffect(pulse ? 1.03 : 0.97)

            // 核心 —— 亮橘红点（烧红的炭芯）
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "E85D3A").opacity(0.8),
                            SatoriColors.incenseEmber.opacity(0.3)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 2.5
                    )
                )
                .frame(width: 4, height: 3)
                .scaleEffect(pulse ? 0.97 : 1.03)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.6)
                .repeatForever(autoreverses: true)
            ) {
                pulse = true
            }
        }
    }
}
