import SwiftUI
import Combine

// MARK: - 抚琴 ViewModel（轻音乐播放）

final class QinViewModel: ObservableObject {
    struct Track: Identifiable {
        let id: String
        let title: String
        let artist: String
        let duration: TimeInterval
        let fileName: String
        var isLocked: Bool = false  // 会员/积分解锁
    }

    @Published var tracks: [Track] = [
        Track(id: "1", title: "高山流水",   artist: "古琴",  duration: 240, fileName: "guqin_mountain"),
        Track(id: "2", title: "平沙落雁",   artist: "古琴",  duration: 300, fileName: "guqin_goose"),
        Track(id: "3", title: "梅花三弄",   artist: "箫",    duration: 270, fileName: "xiao_plum"),
        Track(id: "4", title: "渔舟唱晚",   artist: "古筝",  duration: 210, fileName: "guzheng_boat"),
        Track(id: "5", title: "春江花月夜", artist: "琵琶",  duration: 360, fileName: "pipa_spring"),
        Track(id: "6", title: "阳关三叠",   artist: "古琴",  duration: 280, fileName: "guqin_yangguan", isLocked: true),
    ]

    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var timer: AnyCancellable?

    // MARK: - Actions

    func play(_ track: Track) {
        guard !track.isLocked else { return }
        currentTrack = track
        duration = track.duration
        currentTime = 0
        isPlaying = true
        startTimer()
        // TODO: AudioService.shared.playMusic(track.fileName)
    }

    func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            startTimer()
        } else {
            timer?.cancel()
        }
        // TODO: AudioService.shared.togglePlayPause()
    }

    func stop() {
        isPlaying = false
        currentTrack = nil
        currentTime = 0
        timer?.cancel()
        // TODO: AudioService.shared.stopMusic()
    }

    func seek(to time: TimeInterval) {
        currentTime = time
        // TODO: AudioService.shared.seek(to: time)
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isPlaying else { return }
                self.currentTime = min(self.currentTime + 0.5, self.duration)
                if self.currentTime >= self.duration {
                    self.playNext()
                }
            }
    }

    func playNext() {
        guard let current = currentTrack,
              let idx = tracks.firstIndex(where: { $0.id == current.id }) else { return }
        let nextIdx = (idx + 1) % tracks.count
        let next = tracks[nextIdx]
        if !next.isLocked {
            play(next)
        }
    }

    // MARK: - Formatted

    var formattedCurrentTime: String { formatTime(currentTime) }
    var formattedDuration: String { formatTime(duration) }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
