import SwiftUI

// MARK: - 会员卡片

struct MembershipCardView: View {
    let tier: TeaViewModel.MemberTier
    let points: Int

    var body: some View {
        VStack(spacing: SatoriTheme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.rawValue)
                        .font(SatoriTypography.title)
                        .foregroundStyle(.white)
                    Text("会员")
                        .font(SatoriTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                // 积分
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(points)")
                        .font(.system(size: 28, weight: .ultraLight, design: .serif))
                        .foregroundStyle(.white)
                    Text("积分")
                        .font(SatoriTypography.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(SatoriTheme.spacingL)
        .background(
            RoundedRectangle(cornerRadius: SatoriTheme.cornerLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tier.color,
                            tier.color.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .satoriShadow(SatoriTheme.shadowMedium)
    }
}
