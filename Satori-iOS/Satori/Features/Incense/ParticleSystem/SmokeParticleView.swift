import SwiftUI

// MARK: - 烟雾粒子系统
// 轻量级粒子：200–300 个半透明圆点，缓慢上升 + 水平漂移 + 渐隐
// 使用引用类型引擎管理粒子状态，避免在 Canvas 渲染中修改 @State

struct SmokeParticleView: View {
    var burnProgress: CGFloat = 0

    @StateObject private var engine = SmokeParticleEngine()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                engine.update(canvasSize: size, burnProgress: burnProgress)
                engine.draw(context: context, size: size)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 粒子引擎（引用类型，安全地在 Canvas 闭包中使用）

final class SmokeParticleEngine: ObservableObject {
    private var particles: [SmokeParticle] = []
    private let maxParticles = 300
    /// 每帧持续生成粒子数（保证烟雾连贯不断）
    private let spawnPerFrame: Int = 2

    func update(canvasSize: CGSize, burnProgress: CGFloat) {
        // 持续生成粒子 —— 每帧固定生成，保证烟雾不间断
        for _ in 0..<spawnPerFrame where particles.count < maxParticles {
            let p = SmokeParticle(
                x: canvasSize.width / 2 + CGFloat.random(in: -4...4),
                y: canvasSize.height,
                vx: CGFloat.random(in: -0.3...0.3),
                vy: CGFloat.random(in: -1.5 ... -0.5),
                radius: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.08...0.2),
                life: 1.0,
                decay: Double.random(in: 0.003...0.008)
            )
            particles.append(p)
        }

        // 更新已有粒子
        for i in particles.indices.reversed() {
            particles[i].x += particles[i].vx + sin(particles[i].y * 0.02) * 0.15
            particles[i].y += particles[i].vy
            particles[i].life -= particles[i].decay
            particles[i].radius += 0.03

            if particles[i].life <= 0 {
                particles.remove(at: i)
            }
        }
    }

    func draw(context: GraphicsContext, size: CGSize) {
        for p in particles {
            let alpha = p.opacity * p.life
            guard alpha > 0.005 else { continue }

            let rect = CGRect(
                x: p.x - p.radius,
                y: p.y - p.radius,
                width: p.radius * 2,
                height: p.radius * 2
            )

            var ctx = context
            ctx.opacity = alpha
            ctx.addFilter(.blur(radius: p.radius * 0.5))
            ctx.fill(
                Path(ellipseIn: rect),
                with: .color(.gray.opacity(0.6))
            )
        }
    }
}

// MARK: - 粒子数据

struct SmokeParticle {
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var radius: CGFloat
    var opacity: Double
    var life: Double       // 1.0 → 0.0
    var decay: Double      // 每帧衰减量
}
