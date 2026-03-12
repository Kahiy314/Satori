import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 触感反馈服务

final class HapticService: ObservableObject {
#if canImport(UIKit)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
#endif

    init() {
#if canImport(UIKit)
        // 预热引擎
        lightGenerator.prepare()
        mediumGenerator.prepare()
#endif
    }

    /// 轻触 —— Tab 切换、选项选择
    func lightTap() {
#if canImport(UIKit)
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
#endif
    }

    /// 中等 —— 开始计时、确认操作
    func mediumTap() {
#if canImport(UIKit)
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
#endif
    }

    /// 成功 —— 完成一次焚香
    func successTap() {
#if canImport(UIKit)
        notificationGenerator.notificationOccurred(.success)
#endif
    }

    /// 警告 —— 尝试访问锁定内容
    func warningTap() {
#if canImport(UIKit)
        notificationGenerator.notificationOccurred(.warning)
#endif
    }
}
