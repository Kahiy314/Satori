import 'package:flutter/material.dart';
import '../../../core/models/member_tier.dart';
import '../../../core/theme/theme.dart';

/// 会员卡片
class MembershipCardView extends StatelessWidget {
  final MemberTier tier;
  final int points;

  const MembershipCardView({
    super.key,
    required this.tier,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SatoriTheme.spacingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SatoriTheme.cornerLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tier.color, tier.color.withValues(alpha: 0.7)],
        ),
        boxShadow: const [SatoriTheme.shadowMedium],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier.label,
                    style:
                        SatoriTypography.title.copyWith(color: Colors.white)),
                Text('会员',
                    style: SatoriTypography.caption
                        .copyWith(color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w100,
                  color: Colors.white,
                ),
              ),
              Text('积分',
                  style: SatoriTypography.caption
                      .copyWith(color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }
}
