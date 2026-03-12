import SwiftUI

// MARK: - 毛玻璃背景组件

struct GlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var cornerRadius: CGFloat = SatoriTheme.cornerLarge
    var opacity: Double = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? SatoriColors.glassDark
                            : SatoriColors.glassLight
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.white.opacity(0.5),
                        lineWidth: 0.5
                    )
            )
            .opacity(opacity)
    }
}
