import SwiftUI
import AVFoundation

// MARK: - 音频服务
// 统一管理白噪音和音乐播放，支持多音源叠加 + 交叉淡化

final class AudioService: ObservableObject {
    static let shared = AudioService()

    // ── 白噪音播放器（可叠加多个）──
    private var ambientPlayers: [String: AVAudioPlayer] = [:]

    // ── 音乐播放器 ──
    private var musicPlayer: AVAudioPlayer?
    @Published var isMusicPlaying: Bool = false

    // ── 音频会话 ──
    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[AudioService] 音频会话配置失败: \(error)")
        }
    }

    // MARK: - 白噪音

    func playAmbient(_ fileName: String, volume: Float = 0.5) {
        guard ambientPlayers[fileName] == nil else { return }
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("[AudioService] 未找到文件: \(fileName).mp3")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1  // 无限循环
            player.volume = 0
            player.play()
            ambientPlayers[fileName] = player

            // 渐入
            fadeIn(player, to: volume, duration: 2.0)
        } catch {
            print("[AudioService] 播放失败: \(error)")
        }
    }

    func stopAmbient(_ fileName: String) {
        guard let player = ambientPlayers[fileName] else { return }
        fadeOut(player, duration: 1.5) { [weak self] in
            player.stop()
            self?.ambientPlayers.removeValue(forKey: fileName)
        }
    }

    func setAmbientVolume(_ fileName: String, volume: Float) {
        ambientPlayers[fileName]?.volume = volume
    }

    func stopAllAmbient() {
        for (key, player) in ambientPlayers {
            fadeOut(player, duration: 1.0) { [weak self] in
                player.stop()
                self?.ambientPlayers.removeValue(forKey: key)
            }
        }
    }

    // MARK: - 音乐

    func playMusic(_ fileName: String) {
        musicPlayer?.stop()

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("[AudioService] 未找到文件: \(fileName).mp3")
            return
        }

        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.volume = 0
            musicPlayer?.play()
            isMusicPlaying = true
            fadeIn(musicPlayer!, to: 1.0, duration: 1.5)
        } catch {
            print("[AudioService] 播放失败: \(error)")
        }
    }

    func toggleMusicPlayPause() {
        guard let player = musicPlayer else { return }
        if player.isPlaying {
            player.pause()
            isMusicPlaying = false
        } else {
            player.play()
            isMusicPlaying = true
        }
    }

    func stopMusic() {
        guard let player = musicPlayer else { return }
        fadeOut(player, duration: 1.0) { [weak self] in
            player.stop()
            self?.isMusicPlaying = false
        }
    }

    func seekMusic(to time: TimeInterval) {
        musicPlayer?.currentTime = time
    }

    // MARK: - 交叉淡化工具

    private func fadeIn(_ player: AVAudioPlayer, to targetVolume: Float, duration: TimeInterval) {
        let steps = 30
        let interval = duration / Double(steps)
        let increment = targetVolume / Float(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                player.volume = min(increment * Float(i), targetVolume)
            }
        }
    }

    private func fadeOut(_ player: AVAudioPlayer, duration: TimeInterval, completion: @escaping () -> Void) {
        let steps = 20
        let interval = duration / Double(steps)
        let startVolume = player.volume
        let decrement = startVolume / Float(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                player.volume = max(startVolume - decrement * Float(i), 0)
                if i == steps { completion() }
            }
        }
    }
}
