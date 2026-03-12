import ActivityKit
import SwiftUI

// MARK: - 实时活动服务（iOS 16.1+ 锁屏专注状态）

@available(iOS 16.1, *)
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var activity: Activity<SatoriActivityAttributes>?

    /// 开始实时活动 —— 焚香计时开始时调用
    func startActivity(totalMinutes: Int, endDate: Date) {
        let attributes = SatoriActivityAttributes(
            presetName: "\(totalMinutes)分钟",
            totalDuration: TimeInterval(totalMinutes * 60)
        )
        let state = SatoriActivityAttributes.ContentState(
            remainingTime: TimeInterval(totalMinutes * 60),
            endDate: endDate
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
        } catch {
            print("[LiveActivity] 启动失败: \(error)")
        }
    }

    /// 更新实时活动状态
    func updateActivity(remainingTime: TimeInterval, endDate: Date) {
        let state = SatoriActivityAttributes.ContentState(
            remainingTime: remainingTime,
            endDate: endDate
        )
        Task {
            await activity?.update(using: state)
        }
    }

    /// 结束实时活动
    func endActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
        }
    }
}

// MARK: - Activity Attributes

struct SatoriActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingTime: TimeInterval
        var endDate: Date
    }

    var presetName: String
    var totalDuration: TimeInterval
}
