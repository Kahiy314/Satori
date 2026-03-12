import SwiftUI

// MARK: - 底部音乐播放器条

struct MusicPlayerView: View {
    @ObservedObject var viewModel: QinViewModel
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: SatoriTheme.spacingS) {
            // 进度条
            ProgressSlider(
                value: $viewModel.currentTime,
                range: 0...max(viewModel.duration, 1),
                isDragging: $isDragging
            ) { newValue in
                viewModel.seek(to: newValue)
            }
            .tint(SatoriColors.stringGold)

            // 时间标签
            HStack {
                Text(viewModel.formattedCurrentTime)
                Spacer()
                Text(viewModel.formattedDuration)
            }
            .font(SatoriTypography.caption)
            .foregroundStyle(.tertiary)

            // 标题 + 控制
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentTrack?.title ?? "")
                        .font(SatoriTypography.subtitle)
                        .foregroundStyle(.primary)
                    Text(viewModel.currentTrack?.artist ?? "")
                        .font(SatoriTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 播放/暂停
                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(SatoriColors.stringGold)
                }

                // 下一曲
                Button {
                    viewModel.playNext()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, SatoriTheme.spacingS)
            }
        }
        .padding(.horizontal, SatoriTheme.spacingL)
        .padding(.vertical, SatoriTheme.spacingM)
        .background(GlassBackground(cornerRadius: SatoriTheme.cornerLarge))
        .padding(.horizontal, SatoriTheme.spacingM)
    }
}

// MARK: - 自定义进度滑块

struct ProgressSlider: View {
    @Binding var value: TimeInterval
    var range: ClosedRange<TimeInterval>
    @Binding var isDragging: Bool
    var onEnded: (TimeInterval) -> Void

    var body: some View {
        GeometryReader { geo in
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let clampedFraction = min(max(fraction, 0), 1)

            ZStack(alignment: .leading) {
                // 轨道
                Capsule()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 3)

                // 已播放
                Capsule()
                    .fill(SatoriColors.stringGold)
                    .frame(width: geo.size.width * clampedFraction, height: 3)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let frac = min(max(drag.location.x / geo.size.width, 0), 1)
                        value = range.lowerBound + frac * (range.upperBound - range.lowerBound)
                    }
                    .onEnded { drag in
                        isDragging = false
                        onEnded(value)
                    }
            )
        }
        .frame(height: 20)
    }
}
