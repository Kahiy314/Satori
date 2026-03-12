import SwiftUI

// MARK: - 声波动画
// 多条正弦波叠加，用于听雨页面底部

struct AudioWaveView: View {
    var phase: CGFloat

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2

            // 绘制 3 条波形，不同频率 / 振幅 / 透明度
            let waves: [(amp: CGFloat, freq: CGFloat, phaseOffset: CGFloat, alpha: Double)] = [
                (12, 1.5, 0,           0.3),
                (8,  2.5, .pi / 3,     0.2),
                (5,  4.0, .pi / 1.5,   0.15),
            ]

            for wave in waves {
                var path = Path()
                for x in stride(from: 0, through: size.width, by: 1) {
                    let relX = x / size.width
                    let y = midY + wave.amp * sin(relX * wave.freq * .pi * 2 + phase + wave.phaseOffset)
                    if x == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                context.stroke(
                    path,
                    with: .color(SatoriColors.rainCyan.opacity(wave.alpha)),
                    lineWidth: 1.5
                )
            }
        }
    }
}
