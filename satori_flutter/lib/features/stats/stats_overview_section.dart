import 'package:flutter/material.dart';

import '../../core/models/focus_session.dart';
import '../../core/theme/theme.dart';
import '../../services/stats_aggregator.dart';

/// 复盘指标卡片区。
class StatsOverviewSection extends StatelessWidget {
  final StatsSnapshot snapshot;
  final String rangeLabel;

  const StatsOverviewSection({
    super.key,
    required this.snapshot,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.82);
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor =
        isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.6);

    final metrics = [
      _MetricViewData('总时长', _formatDuration(snapshot.totalDuration)),
      _MetricViewData('专注天数', '${snapshot.totalDays} 天'),
      _MetricViewData('专注次数', '${snapshot.totalSessions} 次'),
      _MetricViewData('平均时长', _formatDuration(snapshot.avgDuration)),
      _MetricViewData('完成率', _formatPercent(snapshot.completionRate)),
      _MetricViewData('当前连续', '${snapshot.currentStreak} 天'),
      _MetricViewData('最长连续', '${snapshot.longestStreak} 天'),
      _MetricViewData('最长单次', _formatDuration(snapshot.longestSessionDuration)),
      _MetricViewData('最佳时段', _formatBestHour(snapshot.bestFocusHour)),
      _MetricViewData('常见标签', snapshot.topTag ?? '未记录'),
      _MetricViewData('常见感受', _formatMood(snapshot.topMood)),
      _MetricViewData('放弃均时', _formatDuration(snapshot.avgAbandonedDuration)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
      child: Container(
        padding: const EdgeInsets.all(SatoriTheme.spacingL),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(SatoriTheme.cornerLarge),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth =
                (constraints.maxWidth - SatoriTheme.spacingS) / 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '复盘指标',
                  style: SatoriTypography.title.copyWith(color: textColor),
                ),
                const SizedBox(height: SatoriTheme.spacingXS),
                Text(
                  '$rangeLabel · 用来回看稳定性、节奏和习惯偏好',
                  style: SatoriTypography.caption.copyWith(color: subColor),
                ),
                const SizedBox(height: SatoriTheme.spacingL),
                Wrap(
                  spacing: SatoriTheme.spacingS,
                  runSpacing: SatoriTheme.spacingS,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: itemWidth,
                        child: _StatCard(
                          label: metric.label,
                          value: metric.value,
                          cardColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : SatoriColors.ricePaper.withValues(alpha: 0.68),
                          textColor: textColor,
                          subColor: subColor,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final totalMinutes = seconds ~/ 60;
    if (totalMinutes < 60) return '$totalMinutes 分';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return mins > 0 ? '$hours 时 $mins 分' : '$hours 时';
  }

  String _formatPercent(double value) {
    return '${(value * 100).round()}%';
  }

  String _formatBestHour(int? hour) {
    if (hour == null) return '未形成';
    final nextHour = (hour + 1) % 24;
    return '${hour.toString().padLeft(2, '0')}:00-$nextHour:00';
  }

  String _formatMood(ReflectionMood? mood) {
    return switch (mood) {
      ReflectionMood.focused => '专注',
      ReflectionMood.distracted => '分心',
      ReflectionMood.productive => '高效',
      ReflectionMood.calm => '平静',
      ReflectionMood.tired => '疲惫',
      null => '未记录',
    };
  }
}

class _MetricViewData {
  final String label;
  final String value;

  const _MetricViewData(this.label, this.value);
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
        horizontal: SatoriTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: SatoriTypography.subtitle.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
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
