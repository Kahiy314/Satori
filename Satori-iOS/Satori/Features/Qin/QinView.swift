import SwiftUI

// MARK: - 抚琴主页面

struct QinView: View {
    @StateObject private var viewModel = QinViewModel()
    @EnvironmentObject private var hapticService: HapticService

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                Text("建议佩戴耳机")
                    .font(SatoriTypography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, SatoriTheme.spacingXS)

                Spacer().frame(height: SatoriTheme.spacingL)

                // 曲目列表
                trackList

                Spacer()

                // 底部播放器
                if viewModel.currentTrack != nil {
                    MusicPlayerView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 100)
            }
        }
        .animation(.easeInOut(duration: SatoriTheme.animNormal), value: viewModel.currentTrack?.id)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("抚琴")
                .font(SatoriTypography.largeTitle)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, SatoriTheme.spacingL)
        .padding(.top, SatoriTheme.spacingM)
    }

    // MARK: - Track List

    private var trackList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: SatoriTheme.spacingS) {
                ForEach(viewModel.tracks) { track in
                    trackRow(track)
                }
            }
            .padding(.horizontal, SatoriTheme.spacingL)
        }
    }

    @ViewBuilder
    private func trackRow(_ track: QinViewModel.Track) -> some View {
        let isCurrent = viewModel.currentTrack?.id == track.id

        Button {
            if track.isLocked {
                hapticService.warningTap()
            } else {
                hapticService.lightTap()
                viewModel.play(track)
            }
        } label: {
            HStack(spacing: SatoriTheme.spacingM) {
                // 播放指示
                ZStack {
                    Circle()
                        .fill(isCurrent
                              ? SatoriColors.stringGold.opacity(0.15)
                              : Color.secondary.opacity(0.05))
                        .frame(width: 40, height: 40)

                    if track.isLocked {
                        Image(systemName: "lock")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    } else if isCurrent && viewModel.isPlaying {
                        // 简易均衡器动画（3条竖线）
                        EqualizerBars()
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 14))
                            .foregroundStyle(
                                isCurrent ? SatoriColors.stringGold : .secondary
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(SatoriTypography.body)
                        .foregroundStyle(
                            track.isLocked ? .secondary : .primary
                        )
                    Text(track.artist)
                        .font(SatoriTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formatDuration(track.duration))
                    .font(SatoriTypography.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, SatoriTheme.spacingS)
            .padding(.horizontal, SatoriTheme.spacingM)
            .background(
                RoundedRectangle(cornerRadius: SatoriTheme.cornerMedium, style: .continuous)
                    .fill(isCurrent ? SatoriColors.stringGold.opacity(0.05) : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - 均衡器动画条

struct EqualizerBars: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(SatoriColors.stringGold)
                    .frame(width: 3, height: animate ? CGFloat.random(in: 6...16) : 4)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

#Preview("Qin") {
    QinView()
        .environmentObject(HapticService())
}
