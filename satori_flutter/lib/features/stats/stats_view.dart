import 'package:flutter/material.dart';

import '../../core/components/section_page_header.dart';
import '../../core/theme/theme.dart';
import '../../services/haptic_service.dart';
import '../../services/stats_aggregator.dart';
import 'stats_heatmap_section.dart';
import 'stats_trend_section.dart';
import 'stats_history_section.dart';
import 'stats_overview_section.dart';

/// 行迹（统计）主页面。
class StatsView extends StatefulWidget {
  final StatsAggregator aggregator;
  final Future<void> Function()? syncWithCloud;

  const StatsView({
    super.key,
    required this.aggregator,
    this.syncWithCloud,
  });

  @override
  State<StatsView> createState() => _StatsViewState();
}

enum _StatsMode { statistics, history }

enum _StatsRange { days30, days90, days365 }

extension on _StatsRange {
  int get days => switch (this) {
        _StatsRange.days30 => 30,
        _StatsRange.days90 => 90,
        _StatsRange.days365 => 365,
      };

  String get label => switch (this) {
        _StatsRange.days30 => '近 30 天',
        _StatsRange.days90 => '近 90 天',
        _StatsRange.days365 => '近 365 天',
      };
}

class _StatsViewState extends State<StatsView> {
  _StatsMode _mode = _StatsMode.statistics;
  _StatsRange _range = _StatsRange.days90;

  void _switchMode(_StatsMode mode) {
    if (_mode == mode) return;
    HapticService.instance.lightTap();
    setState(() => _mode = mode);
  }

  void _switchRange(_StatsRange range) {
    if (_range == range) return;
    HapticService.instance.lightTap();
    setState(() => _range = range);
  }

  Widget _buildCurrentPage() {
    switch (_mode) {
      case _StatsMode.statistics:
        return _StatisticsPage(
          key: const ValueKey('statistics'),
          aggregator: widget.aggregator,
          syncWithCloud: widget.syncWithCloud,
          range: _range,
          onRangeChanged: _switchRange,
        );
      case _StatsMode.history:
        return StatsHistorySection(
          key: const ValueKey('history'),
          aggregator: widget.aggregator,
          syncWithCloud: widget.syncWithCloud,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SatoriColors.inkStone : Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: SatoriTheme.animNormal,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildCurrentPage(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + SatoriTheme.spacingM,
            right: SatoriTheme.spacingM,
            child: _StatsModeSwitch(
              mode: _mode,
              onModeChanged: _switchMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsPage extends StatefulWidget {
  final StatsAggregator aggregator;
  final Future<void> Function()? syncWithCloud;
  final _StatsRange range;
  final ValueChanged<_StatsRange> onRangeChanged;

  const _StatisticsPage({
    super.key,
    required this.aggregator,
    this.syncWithCloud,
    required this.range,
    required this.onRangeChanged,
  });

  @override
  State<_StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<_StatisticsPage> {
  StatsSnapshot _overview = StatsSnapshot.empty;
  List<DailyStats> _dailyStats = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _StatisticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aggregator != widget.aggregator ||
        oldWidget.range != widget.range) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final to = _today();
    final from = to.subtract(Duration(days: widget.range.days - 1));

    await widget.syncWithCloud?.call();
    final overviewFuture = widget.aggregator.overview(from: from, to: to);
    final dailyStatsFuture = widget.aggregator.dailyStats(from, to);

    final overview = await overviewFuture;
    final dailyStats = await dailyStatsFuture;
    if (!mounted) return;
    setState(() {
      _overview = overview;
      _dailyStats = dailyStats;
      _loading = false;
    });
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: SatoriTheme.spacingXXL),
                children: [
                  const SectionPageHeader(title: '行迹'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SatoriTheme.spacingL,
                      SatoriTheme.spacingS,
                      112,
                      SatoriTheme.spacingM,
                    ),
                    child: Wrap(
                      spacing: SatoriTheme.spacingS,
                      runSpacing: SatoriTheme.spacingS,
                      children: [
                        for (final range in _StatsRange.values)
                          _StatsRangeChip(
                            label: range.label,
                            selected: widget.range == range,
                            onTap: () => widget.onRangeChanged(range),
                          ),
                      ],
                    ),
                  ),
                  StatsHeatmapSection(
                    dailyStats: _dailyStats,
                    rangeLabel: widget.range.label,
                  ),
                  const SizedBox(height: SatoriTheme.spacingL),
                  StatsTrendSection(
                    dailyStats: _dailyStats,
                    rangeLabel: widget.range.label,
                  ),
                  const SizedBox(height: SatoriTheme.spacingL),
                  StatsOverviewSection(
                    snapshot: _overview,
                    rangeLabel: widget.range.label,
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatsModeSwitch extends StatelessWidget {
  final _StatsMode mode;
  final ValueChanged<_StatsMode> onModeChanged;

  const _StatsModeSwitch({
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatsModeButton(
            text: '统计',
            isSelected: mode == _StatsMode.statistics,
            accentColor: SatoriColors.verdigris,
            onTap: () => onModeChanged(_StatsMode.statistics),
          ),
          _StatsModeButton(
            text: '历史',
            isSelected: mode == _StatsMode.history,
            accentColor: SatoriColors.sandalwood,
            onTap: () => onModeChanged(_StatsMode.history),
          ),
        ],
      ),
    );
  }
}

class _StatsModeButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _StatsModeButton({
    required this.text,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SatoriTheme.animNormal,
        width: 56,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _StatsRangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatsRangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = selected
        ? SatoriColors.verdigris.withValues(alpha: 0.18)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : SatoriColors.ricePaper.withValues(alpha: 0.72));
    final borderColor = selected
        ? SatoriColors.verdigris.withValues(alpha: 0.42)
        : Colors.transparent;
    final textColor = selected
        ? SatoriColors.verdigris
        : (isDark ? Colors.white60 : SatoriColors.inkSmoke.withValues(alpha: 0.72));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SatoriTheme.animNormal,
        padding: const EdgeInsets.symmetric(
          horizontal: SatoriTheme.spacingM,
          vertical: SatoriTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: SatoriTypography.caption.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
