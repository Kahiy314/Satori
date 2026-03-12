import SwiftUI

// MARK: - 听雨主页面

struct RainView: View {
    @StateObject private var viewModel = RainViewModel()
    @EnvironmentObject private var hapticService: HapticService

    // 动画波纹
    @State private var wavePhase: CGFloat = 0

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                headerSection

                // 提示
                if !viewModel.isAnyPlaying {
                    Text("建议佩戴耳机  ·  可叠加多种声音")
                        .font(SatoriTypography.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, SatoriTheme.spacingS)
                }

                Spacer()

                // 音源网格
                soundGrid

                Spacer()

                // 波形动画
                if viewModel.isAnyPlaying {
                    AudioWaveView(phase: wavePhase)
                        .frame(height: 60)
                        .padding(.horizontal, SatoriTheme.spacingL)
                        .transition(.opacity)
                }

                // 全部停止
                if viewModel.isAnyPlaying {
                    Button {
                        hapticService.lightTap()
                        viewModel.stopAll()
                    } label: {
                        Text("止息")
                            .font(SatoriTypography.subtitle)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, SatoriTheme.spacingL)
                            .padding(.vertical, SatoriTheme.spacingS)
                            .background(Capsule().fill(Color.secondary.opacity(0.08)))
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: 100)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("听雨")
                .font(SatoriTypography.largeTitle)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, SatoriTheme.spacingL)
        .padding(.top, SatoriTheme.spacingM)
    }

    // MARK: - Sound Grid

    private var soundGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: SatoriTheme.spacingM),
                GridItem(.flexible(), spacing: SatoriTheme.spacingM),
                GridItem(.flexible(), spacing: SatoriTheme.spacingM),
            ],
            spacing: SatoriTheme.spacingM
        ) {
            ForEach(viewModel.sources) { source in
                SoundSourceCard(source: source) {
                    hapticService.lightTap()
                    viewModel.toggleSource(source.id)
                } onVolumeChange: { vol in
                    viewModel.setVolume(source.id, volume: vol)
                }
            }
        }
        .padding(.horizontal, SatoriTheme.spacingL)
        .animation(.easeInOut(duration: SatoriTheme.animNormal), value: viewModel.sources.map(\.isPlaying))
    }
}

// MARK: - 音源卡片

struct SoundSourceCard: View {
    let source: RainViewModel.SoundSource
    let onToggle: () -> Void
    let onVolumeChange: (Float) -> Void

    @State private var localVolume: Float = 0.5

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onToggle) {
                VStack(spacing: 6) {
                    Image(systemName: source.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(
                            source.isPlaying ? SatoriColors.rainCyan : .secondary
                        )

                    Text(source.name)
                        .font(SatoriTypography.caption)
                        .foregroundStyle(
                            source.isPlaying ? .primary : .secondary
                        )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SatoriTheme.spacingM)
                .background(
                    RoundedRectangle(cornerRadius: SatoriTheme.cornerMedium, style: .continuous)
                        .fill(
                            source.isPlaying
                                ? SatoriColors.rainCyan.opacity(0.1)
                                : Color.secondary.opacity(0.05)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SatoriTheme.cornerMedium, style: .continuous)
                        .strokeBorder(
                            source.isPlaying
                                ? SatoriColors.rainCyan.opacity(0.3)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)

            // 音量滑块（仅播放中显示）
            if source.isPlaying {
                Slider(
                    value: Binding(
                        get: { localVolume },
                        set: { newVal in
                            localVolume = newVal
                            onVolumeChange(newVal)
                        }
                    ),
                    in: 0...1
                )
                .tint(SatoriColors.rainCyan)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .onAppear { localVolume = source.volume }
        .animation(.easeInOut(duration: 0.25), value: source.isPlaying)
    }
}

#Preview("Rain") {
    RainView()
        .environmentObject(HapticService())
}
