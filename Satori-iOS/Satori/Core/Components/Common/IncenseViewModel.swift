import SwiftUI
import Combine

// MARK: - 焚香 ViewModel（倒计时 + 正计时）

final class IncenseViewModel: ObservableObject {
    // ── 计时模式 ──
    enum TimerMode: String, CaseIterable {
        case countdown = "倒"
        case countUp   = "正"
    }

    // ── 状态 ──
    enum TimerState { case idle, running, paused, completed }

    @Published var timerMode: TimerMode = .countdown
    @Published var state: TimerState = .idle
    @Published var totalDuration: TimeInterval = 25 * 60
    @Published var remainingTime: TimeInterval = 25 * 60
    @Published var elapsedTime: TimeInterval = 0
    @Published var burnProgress: CGFloat = 0   // 0 → 1，香燃烧进度

    // ── 自定义时长弹窗 ──
    @Published var showCustomDuration = false
    @Published var customMinutes: Int = 25  // 弹窗中的滑块值

    static let minMinutes: Int = 1
    static let maxMinutes: Int = 120

    // ── 预设时长 ──
    let presets: [(label: String, minutes: Int)] = [
        ("一炷短香", 15),
        ("一炷香",   25),
        ("一炷长香", 45),
        ("一坐禅",   60),
    ]

    private var timer: AnyCancellable?
    private var startDate: Date?
    private var pauseAccumulated: TimeInterval = 0

    // MARK: - 自定义时长

    /// 从弹窗应用自定义时长
    func applyCustomDuration() {
        guard state == .idle else { return }
        let mins = max(Self.minMinutes, min(Self.maxMinutes, customMinutes))
        totalDuration = TimeInterval(mins * 60)
        remainingTime = totalDuration
    }

    // MARK: - Actions

    func selectPreset(minutes: Int) {
        guard state == .idle else { return }
        totalDuration = TimeInterval(minutes * 60)
        remainingTime = totalDuration
        burnProgress = 0
    }

    func start() {
        guard state == .idle || state == .paused else { return }

        if state == .idle {
            if timerMode == .countdown {
                remainingTime = totalDuration
            } else {
                elapsedTime = 0
            }
            pauseAccumulated = 0
            burnProgress = 0
        }

        startDate = Date()
        state = .running

        timer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        if let start = startDate {
            pauseAccumulated += Date().timeIntervalSince(start)
        }
        timer?.cancel()
    }

    func reset() {
        state = .idle
        timer?.cancel()
        if timerMode == .countdown {
            remainingTime = totalDuration
        }
        elapsedTime = 0
        burnProgress = 0
        pauseAccumulated = 0
        startDate = nil
    }

    // MARK: - Tick

    private func tick() {
        guard let start = startDate else { return }
        let elapsed = pauseAccumulated + Date().timeIntervalSince(start)

        if timerMode == .countdown {
            remainingTime = max(0, totalDuration - elapsed)
            burnProgress = min(1, CGFloat(elapsed / totalDuration))
            if remainingTime <= 0 {
                state = .completed
                timer?.cancel()
            }
        } else {
            elapsedTime = elapsed
            // 正计时模式：burnProgress 按 60 分钟一循环，用于视觉效果
            burnProgress = min(1, CGFloat(elapsed / (60 * 60)))
        }
    }

    // MARK: - Formatted Time

    var formattedTime: String {
        let seconds: Int
        if timerMode == .countdown {
            seconds = Int(remainingTime)
        } else {
            seconds = Int(elapsedTime)
        }
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
}
