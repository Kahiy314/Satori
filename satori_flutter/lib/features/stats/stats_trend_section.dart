import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../services/stats_aggregator.dart';

class StatsTrendSection extends StatelessWidget {
  final List<DailyStats> dailyStats;
  final String rangeLabel;

  const StatsTrendSection({
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
    final bins = _buildBins(dailyStats, maxBins: 12);
    final maxValue = bins.fold<double>(
      0,
      (maxBin, bin) => bin.totalDuration > maxBin ? bin.totalDuration : maxBin,
    );
    final avgDuration = dailyStats.isEmpty
        ? 0.0
        : dailyStats.fold<double>(0, (sum, point) => sum + point.totalDuration) /
            dailyStats.length;

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
              '趋势',
              style: SatoriTypography.title.copyWith(color: titleColor),
            ),
            const SizedBox(height: SatoriTheme.spacingXS),
            Text(
              '$rangeLabel · 日均 ${_formatDuration(avgDuration)} · 峰值 ${_formatDuration(maxValue)}',
              style: SatoriTypography.caption.copyWith(color: subColor),
            ),
            const SizedBox(height: SatoriTheme.spacingL),
            if (bins.isEmpty)
              Text(
                '暂无趋势数据',
                style: SatoriTypography.body.copyWith(color: subColor),
              )
            else
              SizedBox(
                height: 176,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var index = 0; index < bins.length; index++) ...[
                      if (index > 0) const SizedBox(width: SatoriTheme.spacingS),
                      Expanded(
                        child: _TrendBar(
                          bin: bins[index],
                          maxValue: maxValue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_TrendBin> _buildBins(List<DailyStats> points, {required int maxBins}) {
    if (points.isEmpty) return const [];

    final binSize = math.max(1, (points.length / maxBins).ceil());
    final bins = <_TrendBin>[];

    for (var start = 0; start < points.length; start += binSize) {
      final end = math.min(start + binSize, points.length);
      final slice = points.sublist(start, end);
      final totalDuration = slice.fold<double>(
        0,
        (sum, point) => sum + point.totalDuration,
      );
      final sessionCount = slice.fold<int>(
        0,
        (sum, point) => sum + point.sessionCount,
      );
      bins.add(_TrendBin(
        label: '${slice.first.date.month}/${slice.first.date.day}',
        totalDuration: totalDuration,
        sessionCount: sessionCount,
      ));
    }

    return bins;
  }

  String _formatDuration(double seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes 分';
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    return remainMinutes == 0 ? '$hours 时' : '$hours 时 $remainMinutes 分';
  }
}

class _TrendBar extends StatelessWidget {
  final _TrendBin bin;
  final double maxValue;

  const _TrendBar({
    required this.bin,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.56);
    final ratio = maxValue <= 0 ? 0.0 : (bin.totalDuration / maxValue).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          message: '${bin.label} · ${bin.sessionCount} 次 · ${_formatMinutes(bin.totalDuration)}',
          child: Container(
            width: double.infinity,
            height: 132,
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: SatoriTheme.animNormal,
              width: double.infinity,
              height: math.max(10, 132 * ratio),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SatoriTheme.cornerSmall),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SatoriColors.verdigris.withValues(alpha: 0.42),
                    SatoriColors.verdigris,
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: SatoriTheme.spacingS),
        Text(
          bin.label,
          style: SatoriTypography.caption.copyWith(color: labelColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatMinutes(double seconds) {
    final minutes = seconds ~/ 60;
    return '$minutes 分钟';
  }
}

class _TrendBin {
  final String label;
  final double totalDuration;
  final int sessionCount;

  const _TrendBin({
    required this.label,
    required this.totalDuration,
    required this.sessionCount,
  });
}