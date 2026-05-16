import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../services/stats_aggregator.dart';

class StatsHeatmapSection extends StatelessWidget {
  final List<DailyStats> dailyStats;
  final String rangeLabel;

  const StatsHeatmapSection({
    super.key,
    required this.dailyStats,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.82);
    final titleColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor =
        isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.6);
    final activeDays = dailyStats.where((entry) => entry.totalDuration > 0).length;
    final totalDuration = dailyStats.fold<double>(
      0,
      (sum, entry) => sum + entry.totalDuration,
    );
    final maxDuration = dailyStats.fold<double>(
      0,
      (maxValue, entry) =>
          entry.totalDuration > maxValue ? entry.totalDuration : maxValue,
    );
    final weeks = _chunkByWeek(dailyStats);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
      child: Container(
        padding: const EdgeInsets.all(SatoriTheme.spacingL),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(SatoriTheme.cornerLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '热力图',
              style: SatoriTypography.title.copyWith(color: titleColor),
            ),
            const SizedBox(height: SatoriTheme.spacingXS),
            Text(
              '$rangeLabel · $activeDays / ${dailyStats.length} 天有记录 · ${_formatDuration(totalDuration)}',
              style: SatoriTypography.caption.copyWith(color: subColor),
            ),
            const SizedBox(height: SatoriTheme.spacingM),
            if (dailyStats.isEmpty)
              Text(
                '暂无热力图数据',
                style: SatoriTypography.body.copyWith(color: subColor),
              )
            else
              SizedBox(
                height: 7 * 16 + 6 * SatoriTheme.spacingXS,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < weeks.length; index++) ...[
                        if (index > 0) const SizedBox(width: SatoriTheme.spacingXS),
                        _HeatmapWeekColumn(
                          days: weeks[index],
                          maxDuration: maxDuration,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: SatoriTheme.spacingM),
            Text(
              '色块越深，表示当天有效专注总时长越高。',
              style: SatoriTypography.caption.copyWith(color: subColor),
            ),
          ],
        ),
      ),
    );
  }

  List<List<DailyStats>> _chunkByWeek(List<DailyStats> points) {
    if (points.isEmpty) return const [];

    final weeks = <List<DailyStats>>[];
    for (var start = 0; start < points.length; start += 7) {
      weeks.add(points.sublist(start, math.min(start + 7, points.length)));
    }
    return weeks;
  }

  String _formatDuration(double seconds) {
    final totalMinutes = seconds ~/ 60;
    if (totalMinutes < 60) return '$totalMinutes 分钟';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '$hours 小时' : '$hours 小时 $minutes 分钟';
  }
}

class _HeatmapWeekColumn extends StatelessWidget {
  final List<DailyStats> days;
  final double maxDuration;

  const _HeatmapWeekColumn({
    required this.days,
    required this.maxDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < days.length; index++) ...[
          if (index > 0) const SizedBox(height: SatoriTheme.spacingXS),
          _HeatmapCell(
            day: days[index],
            maxDuration: maxDuration,
          ),
        ],
      ],
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final DailyStats day;
  final double maxDuration;

  const _HeatmapCell({
    required this.day,
    required this.maxDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final intensity = maxDuration <= 0 ? 0.0 : (day.totalDuration / maxDuration);
    final color = intensity <= 0
        ? (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : SatoriColors.ricePaper.withValues(alpha: 0.9))
        : Color.lerp(
            SatoriColors.verdigris.withValues(alpha: 0.18),
            SatoriColors.verdigris,
            intensity.clamp(0.0, 1.0),
          )!;

    return Tooltip(
      message:
          '${day.date.month}月${day.date.day}日 · ${_formatMinutes(day.totalDuration)} · ${day.sessionCount} 次',
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  String _formatMinutes(double seconds) {
    final minutes = seconds ~/ 60;
    return '$minutes 分钟';
  }
}