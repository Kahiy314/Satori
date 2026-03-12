import SwiftUI

// MARK: - 品茗 ViewModel（赞助 / 会员）

final class TeaViewModel: ObservableObject {
    // ── 会员等级 ──
    enum MemberTier: String, CaseIterable {
        case free    = "清茶"
        case silver  = "银针"
        case gold    = "龙井"
        case premium = "大红袍"

        var price: String {
            switch self {
            case .free:    return "免费"
            case .silver:  return "¥12/月"
            case .gold:    return "¥28/月"
            case .premium: return "¥68/月"
            }
        }

        var benefits: [String] {
            switch self {
            case .free:
                return ["基础焚香计时", "3种白噪音", "2首琴曲"]
            case .silver:
                return ["全部白噪音", "6首琴曲", "沉香·香料皮肤"]
            case .gold:
                return ["全部琴曲", "名贵香料皮肤", "统计报表"]
            case .premium:
                return ["全部功能", "稀有琴曲抢先听", "专属香炉外观"]
            }
        }

        var color: Color {
            switch self {
            case .free:    return .secondary
            case .silver:  return Color(hex: "A8B5C0")
            case .gold:    return SatoriColors.stringGold
            case .premium: return SatoriColors.incenseEmber
            }
        }
    }

    @Published var currentTier: MemberTier = .free
    @Published var points: Int = 0            // 积分
    @Published var showPurchaseSheet = false
    @Published var selectedTier: MemberTier?

    // MARK: - Actions

    func selectTier(_ tier: MemberTier) {
        selectedTier = tier
        showPurchaseSheet = true
    }

    func purchase() {
        guard let tier = selectedTier else { return }
        // TODO: StoreKit 2 购买流程
        currentTier = tier
        showPurchaseSheet = false
    }
}
