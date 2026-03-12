import SwiftUI

// MARK: - 品茗主页面

struct TeaView: View {
    @StateObject private var viewModel = TeaViewModel()
    @EnvironmentObject private var hapticService: HapticService

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: SatoriTheme.spacingL) {
                    headerSection

                    // 当前等级卡
                    currentTierCard

                    // 等级列表
                    tierSection

                    // 积分
                    pointsSection

                    // 致谢
                    acknowledgement

                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, SatoriTheme.spacingL)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("品茗")
                .font(SatoriTypography.largeTitle)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.top, SatoriTheme.spacingM)
    }

    // MARK: - Current Tier Card

    private var currentTierCard: some View {
        MembershipCardView(tier: viewModel.currentTier, points: viewModel.points)
    }

    // MARK: - Tier Section

    private var tierSection: some View {
        VStack(alignment: .leading, spacing: SatoriTheme.spacingM) {
            Text("茶品")
                .font(SatoriTypography.title)
                .foregroundStyle(.primary)

            ForEach(TeaViewModel.MemberTier.allCases, id: \.rawValue) { tier in
                tierRow(tier)
            }
        }
    }

    @ViewBuilder
    private func tierRow(_ tier: TeaViewModel.MemberTier) -> some View {
        let isCurrent = viewModel.currentTier == tier

        VStack(alignment: .leading, spacing: SatoriTheme.spacingS) {
            HStack {
                Circle()
                    .fill(tier.color)
                    .frame(width: 10, height: 10)

                Text(tier.rawValue)
                    .font(SatoriTypography.subtitle)
                    .foregroundStyle(.primary)

                Spacer()

                if isCurrent {
                    Text("当前")
                        .font(SatoriTypography.caption)
                        .foregroundStyle(tier.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(tier.color.opacity(0.12))
                        )
                } else {
                    Button {
                        hapticService.lightTap()
                        viewModel.selectTier(tier)
                    } label: {
                        Text(tier.price)
                            .font(SatoriTypography.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(tier.color)
                            )
                    }
                }
            }

            // 权益列表
            ForEach(tier.benefits, id: \.self) { benefit in
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(tier.color)
                    Text(benefit)
                        .font(SatoriTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(SatoriTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: SatoriTheme.cornerMedium, style: .continuous)
                .fill(isCurrent ? tier.color.opacity(0.05) : Color.secondary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: SatoriTheme.cornerMedium, style: .continuous)
                .strokeBorder(
                    isCurrent ? tier.color.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Points Section

    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: SatoriTheme.spacingS) {
            Text("积分")
                .font(SatoriTypography.title)

            HStack {
                Image(systemName: "leaf")
                    .foregroundStyle(SatoriColors.verdigris)
                Text("\(viewModel.points) 叶")
                    .font(SatoriTypography.body)
                Spacer()
                Text("每完成一次焚香 +10")
                    .font(SatoriTypography.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(SatoriTheme.spacingM)
            .background(
                RoundedRectangle(cornerRadius: SatoriTheme.cornerMedium, style: .continuous)
                    .fill(SatoriColors.verdigris.opacity(0.05))
            )
        }
    }

    // MARK: - Acknowledgement

    private var acknowledgement: some View {
        VStack(spacing: SatoriTheme.spacingS) {
            Divider().padding(.vertical, SatoriTheme.spacingS)

            Text("「品一盏茶，敬一份心」")
                .font(SatoriTypography.caption)
                .foregroundStyle(.tertiary)

            Text("您的支持是独立开发者继续打磨的动力")
                .font(SatoriTypography.caption)
                .foregroundStyle(.quaternary)
        }
    }
}

#Preview("Tea") {
    TeaView()
        .environmentObject(HapticService())
}
