import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../services/haptic_service.dart';
import 'tea_view_model.dart';
import 'components/membership_card_view.dart';

/// 品茗主页面
class TeaView extends StatefulWidget {
  const TeaView({super.key});

  @override
  State<TeaView> createState() => _TeaViewState();
}

class _TeaViewState extends State<TeaView> {
  final _vm = TeaViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SatoriTheme.spacingM),
            Text('品茗', style: SatoriTypography.largeTitle),
            const SizedBox(height: SatoriTheme.spacingL),

            // 当前等级卡
            MembershipCardView(tier: _vm.currentTier, points: _vm.points),
            const SizedBox(height: SatoriTheme.spacingL),

            // 茶品列表
            Text('茶品', style: SatoriTypography.title),
            const SizedBox(height: SatoriTheme.spacingM),
            ...MemberTier.values.map((tier) => _buildTierRow(tier)),
            const SizedBox(height: SatoriTheme.spacingL),

            // 积分
            _buildPointsSection(),
            const SizedBox(height: SatoriTheme.spacingL),

            // 致谢
            _buildAcknowledgement(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(MemberTier tier) {
    final isCurrent = _vm.currentTier == tier;

    return Container(
      margin: const EdgeInsets.only(bottom: SatoriTheme.spacingM),
      padding: const EdgeInsets.all(SatoriTheme.spacingM),
      decoration: BoxDecoration(
        color: isCurrent
            ? tier.color.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
        border: Border.all(
          color: isCurrent ? tier.color.withValues(alpha: 0.2) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tier.color,
                ),
              ),
              const SizedBox(width: 8),
              Text(tier.label, style: SatoriTypography.subtitle),
              const Spacer(),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tier.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
                  ),
                  child: Text('当前',
                      style: SatoriTypography.caption.copyWith(color: tier.color)),
                )
              else
                GestureDetector(
                  onTap: () {
                    HapticService.instance.lightTap();
                    _vm.selectTier(tier);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: tier.color,
                      borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
                    ),
                    child: Text(tier.price,
                        style: SatoriTypography.caption
                            .copyWith(color: Colors.white)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SatoriTheme.spacingS),
          ...tier.benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check, size: 10, color: tier.color),
                  const SizedBox(width: 6),
                  Text(b,
                      style: SatoriTypography.caption
                          .copyWith(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('积分', style: SatoriTypography.title),
        const SizedBox(height: SatoriTheme.spacingS),
        Container(
          padding: const EdgeInsets.all(SatoriTheme.spacingM),
          decoration: BoxDecoration(
            color: SatoriColors.verdigris.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
          ),
          child: Row(
            children: [
              const Icon(Icons.eco, color: SatoriColors.verdigris),
              const SizedBox(width: 8),
              Text('${_vm.points} 叶', style: SatoriTypography.body),
              const Spacer(),
              Text('每完成一次焚香 +10',
                  style: SatoriTypography.caption
                      .copyWith(color: Colors.grey.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcknowledgement() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: SatoriTheme.spacingS),
        Text('「品一盏茶，敬一份心」',
            style: SatoriTypography.caption
                .copyWith(color: Colors.grey.withValues(alpha: 0.5))),
        const SizedBox(height: 4),
        Text('您的支持是独立开发者继续打磨的动力',
            style: SatoriTypography.caption
                .copyWith(color: Colors.grey.withValues(alpha: 0.3))),
      ],
    );
  }
}
