import SwiftUI

// MARK: - 太极 Liquid Glass 容器
// 正计时模式的核心视觉元素：烟雾汇聚的太极形容器
// 使用圆形叠加法构建阴阳图案，避免路径绕组问题

struct TaiChiGlassView: View {
    var fillProgress: CGFloat  // 0 → 1，控制内部烟雾浓度
    @State private var rotation: Double = 0

    private let yinColor = Color.primary.opacity(0.55)
    private let yangColor = Color.white.opacity(0.65)

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let r = size / 2
            let smallR = r / 2
            let eyeR = size * 0.07

            ZStack {
                // 毛玻璃底层
                Circle()
                    .fill(.ultraThinMaterial)

                // ─── 阴阳图案 ───

                // 1. 阴（暗）底色 — 铺满整圆
                Circle()
                    .fill(yinColor)

                // 2. 阳（亮）右半 — 用裁切矩形露出右侧
                Circle()
                    .fill(yangColor)
                    .clipShape(
                        Rectangle().offset(x: r / 2)
                    )

                // 3. 阳鱼头 — 上方小亮圆（凸入阴区域）
                Circle()
                    .fill(yangColor)
                    .frame(width: size / 2, height: size / 2)
                    .offset(y: -smallR)

                // 4. 阴鱼头 — 下方小暗圆（凸入阳区域）
                Circle()
                    .fill(yinColor)
                    .frame(width: size / 2, height: size / 2)
                    .offset(y: smallR)

                // 5. 阳鱼眼（暗点，位于亮半上方）
                Circle()
                    .fill(yinColor)
                    .frame(width: eyeR * 2, height: eyeR * 2)
                    .offset(y: -smallR)

                // 6. 阴鱼眼（亮点，位于暗半下方）
                Circle()
                    .fill(yangColor)
                    .frame(width: eyeR * 2, height: eyeR * 2)
                    .offset(y: smallR)

                // ─── 装饰 ───

                // 烟雾汇聚效果
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                SatoriColors.inkSmoke.opacity(0.18 * fillProgress),
                                SatoriColors.inkSmoke.opacity(0.05 * fillProgress),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: r * 0.85
                        )
                    )

                // 玻璃高光描边
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .clipShape(Circle())
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(
                .linear(duration: 60)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}
