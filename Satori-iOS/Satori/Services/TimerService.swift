import Foundation
import Combine
import UIKit

// MARK: - 计时器服务
// 后台保活 + 精度补偿

final class TimerService: ObservableObject {
    @Published var isRunning = false

    private var backgroundDate: Date?

    init() {
        // 监听 App 进入后台/前台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func didEnterBackground() {
        backgroundDate = Date()
        // App 进入后台 —— 记录时间戳用于回来时补偿
    }

    @objc private func willEnterForeground() {
        guard let bgDate = backgroundDate else { return }
        let elapsed = Date().timeIntervalSince(bgDate)
        backgroundDate = nil

        // 通知 ViewModel 补偿后台经过的时间
        NotificationCenter.default.post(
            name: .timerBackgroundCompensation,
            object: nil,
            userInfo: ["elapsed": elapsed]
        )
    }
}

extension Notification.Name {
    static let timerBackgroundCompensation = Notification.Name("timerBackgroundCompensation")
}
