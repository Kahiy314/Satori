import SwiftUI
import Combine

// MARK: - 听雨 ViewModel（白噪音）

final class RainViewModel: ObservableObject {
    // ── 音源 ──
    struct SoundSource: Identifiable {
        let id: String
        let name: String
        let icon: String
        let fileName: String
        var volume: Float = 0.5
        var isPlaying: Bool = false
    }

    @Published var sources: [SoundSource] = [
        SoundSource(id: "rain",      name: "细雨",   icon: "cloud.drizzle",    fileName: "rain_light"),
        SoundSource(id: "storm",     name: "暴雨",   icon: "cloud.heavyrain",  fileName: "rain_heavy"),
        SoundSource(id: "thunder",   name: "雷声",   icon: "cloud.bolt",       fileName: "thunder"),
        SoundSource(id: "stream",    name: "溪流",   icon: "water.waves",      fileName: "stream"),
        SoundSource(id: "wind",      name: "松风",   icon: "wind",             fileName: "wind_pine"),
        SoundSource(id: "night",     name: "虫鸣",   icon: "moon.stars",       fileName: "night_insects"),
    ]

    @Published var isAnyPlaying: Bool = false

    // MARK: - Actions

    func toggleSource(_ id: String) {
        guard let idx = sources.firstIndex(where: { $0.id == id }) else { return }
        sources[idx].isPlaying.toggle()
        isAnyPlaying = sources.contains(where: \.isPlaying)
        // TODO: AudioService.shared.toggle(sources[idx])
    }

    func setVolume(_ id: String, volume: Float) {
        guard let idx = sources.firstIndex(where: { $0.id == id }) else { return }
        sources[idx].volume = volume
        // TODO: AudioService.shared.setVolume(id, volume)
    }

    func stopAll() {
        for i in sources.indices {
            sources[i].isPlaying = false
        }
        isAnyPlaying = false
        // TODO: AudioService.shared.stopAll()
    }
}
