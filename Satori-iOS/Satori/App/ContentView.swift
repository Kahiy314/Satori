import SwiftUI

struct ContentView: View {
    @State private var selectedTab: SatoriTab = .incense
    @State private var previousTab: SatoriTab = .incense
    @State private var opacity: Double = 1.0
    @Namespace private var tabNamespace

    var body: some View {
        ZStack {
            // 背景跟随系统深浅模式
            Color(.systemBackground)
                .ignoresSafeArea()

            // 当前功能页面 —— 渐入渐出
            currentPage
                .opacity(opacity)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)

            // 底部菜单栏
            VStack {
                Spacer()
                SatoriTabBar(
                    selectedTab: $selectedTab,
                    namespace: tabNamespace,
                    onTabChanged: handleTabChange
                )
            }
        }
    }

    // MARK: - Pages

    @ViewBuilder
    private var currentPage: some View {
        switch selectedTab {
        case .incense:
            IncenseView()
        case .rain:
            RainView()
        case .qin:
            QinView()
        case .tea:
            TeaView()
        }
    }

    // MARK: - Tab Switch

    private func handleTabChange(from oldTab: SatoriTab, to newTab: SatoriTab) {
        guard oldTab != newTab else { return }
        previousTab = oldTab

        // 渐出 → 切换 → 渐入
        withAnimation(.easeOut(duration: 0.15)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            selectedTab = newTab
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Tab Enum

enum SatoriTab: String, CaseIterable, Identifiable {
    case incense = "焚香"
    case rain    = "听雨"
    case qin     = "抚琴"
    case tea     = "品茗"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .incense: return "flame"
        case .rain:    return "cloud.rain"
        case .qin:     return "music.note"
        case .tea:     return "cup.and.saucer"
        }
    }
}
