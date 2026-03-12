import SwiftUI

// MARK: - 底部菜单栏
// 仿 Telegram iOS 风格：液态玻璃 + 微缩放 + 触感反馈

struct SatoriTabBar: View {
    @Binding var selectedTab: SatoriTab
    var namespace: Namespace.ID
    var onTabChanged: (SatoriTab, SatoriTab) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var hapticService: HapticService

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SatoriTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, SatoriTheme.spacingM)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(tabBarBackground)
        .padding(.horizontal, SatoriTheme.spacingM)
        .padding(.bottom, 8)
    }

    // MARK: - Tab Button

    @ViewBuilder
    private func tabButton(for tab: SatoriTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            guard !isSelected else { return }
            hapticService.lightTap()
            onTabChanged(selectedTab, tab)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // 选中指示器
                    if isSelected {
                        Capsule()
                            .fill(accentColor(for: tab).opacity(0.15))
                            .frame(width: 48, height: 28)
                            .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected ? accentColor(for: tab) : .secondary
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(height: 28)

                Text(tab.rawValue)
                    .font(SatoriTypography.tabLabel)
                    .foregroundStyle(
                        isSelected ? accentColor(for: tab) : .secondary
                    )
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Background

    private var tabBarBackground: some View {
        GlassBackground(cornerRadius: SatoriTheme.cornerLarge)
            .satoriShadow(SatoriTheme.shadowMedium)
    }

    // MARK: - Accent Colors per Tab

    private func accentColor(for tab: SatoriTab) -> Color {
        switch tab {
        case .incense: return SatoriColors.incenseEmber
        case .rain:    return SatoriColors.rainCyan
        case .qin:     return SatoriColors.stringGold
        case .tea:     return SatoriColors.teaAmber
        }
    }
}

// MARK: - Tab Button Style（微缩放 + 弹性）

struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
