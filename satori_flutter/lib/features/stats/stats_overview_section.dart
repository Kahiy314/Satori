import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../services/stats_aggregator.dart';

/// 统计概览卡片区。
class StatsOverviewSection extends StatelessWidget {
  final StatsSnapshot snapshot;

  const StatsOverviewSection({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.8);
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor = isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
      child: Column(
        children: [
          // 主数据行
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '总时长',
                  value: _formatDuration(snapshot.totalDuration),
                  cardColor: cardColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ),
              const SizedBox(width: SatoriTheme.spacingS),
              Expanded(
                child: _StatCard(
                  label: '专注天数',
                  value: '${snapshot.totalDays}',
                  cardColor: cardColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ),
              const SizedBox(width: SatoriTheme.spacingS),
              Expanded(
                child: _StatCard(
                  label: '专注次数',
                  value: '${snapshot.totalSessions}',
                  cardColor: cardColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: SatoriTheme.spacingS),
          // 辅助数据行
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '平均时长',
                  value: _formatDuration(snapshot.avgDuration),
                  cardColor: cardColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ),
              const SizedBox(width: SatoriTheme.spacingS),
              Expanded(
                child: _StatCard(
                  label: '放弃次数',
                  value: '${snapshot.abandonedCount}',
                  cardColor: cardColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ),
              const SizedBox(width: SatoriTheme.spacingS),
              Expanded(
                child: _StatCard(
                  label: '平均放弃',
                  value: _formatDuration(snapshot.avgAbandonedDuration),
                  cardColor: cardColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(double seconds) {
    final totalMinutes = seconds ~/ 60;
    if (totalMinutes < 60) return '${totalMinutes}分';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return mins > 0 ? '$hours时${mins}分' : '$hours时';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: SatoriTheme.spacingM,
        horizontal: SatoriTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: SatoriTypography.title.copyWith(color: textColor),
          ),
          const SizedBox(height: SatoriTheme.spacingXS),
          Text(
            label,
            style: SatoriTypography.caption.copyWith(color: subColor),
          ),
        ],
      ),
    );
  }
}
