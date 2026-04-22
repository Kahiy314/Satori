import 'package:flutter/material.dart';
import '../../core/models/focus_session.dart';
import '../../core/theme/theme.dart';
import '../../services/stats_aggregator.dart';
import 'stats_day_timeline_view.dart';
import 'stats_session_detail_view.dart';

/// 历史记录列表（Sliver 形式）。
class StatsHistorySection extends StatefulWidget {
  final StatsAggregator aggregator;

  const StatsHistorySection({super.key, required this.aggregator});

  @override
  State<StatsHistorySection> createState() => _StatsHistorySectionState();
}

class _StatsHistorySectionState extends State<StatsHistorySection> {
  List<FocusSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StatsHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    // 最近 90 天
    final now = DateTime.now();
    final allSessions = <FocusSession>[];
    for (var d = 0; d < 90; d++) {
      final day = now.subtract(Duration(days: d));
      final daySessions = await widget.aggregator.sessionsForDay(day);
      allSessions.addAll(daySessions);
    }
    if (!mounted) return;
    setState(() {
      _sessions = allSessions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(SatoriTheme.spacingXL),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      );
    }

    if (_sessions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(SatoriTheme.spacingXL),
          child: Center(
            child: Text(
              '暂无专注记录',
              style: SatoriTypography.body.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : SatoriColors.inkSmoke.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final session = _sessions[index];
          return _HistoryTile(
            session: session,
            onTap: () => _showSessionDetail(session),
            onTimelineTap: () => _showDayTimeline(session.startAt),
          );
        },
        childCount: _sessions.length,
      ),
    );
  }

  void _showSessionDetail(FocusSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatsSessionDetailView(session: session),
      ),
    );
  }

  void _showDayTimeline(DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatsDayTimelineView(
          day: day,
          aggregator: widget.aggregator,
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final FocusSession session;
  final VoidCallback onTap;
  final VoidCallback onTimelineTap;

  const _HistoryTile({
    required this.session,
    required this.onTap,
    required this.onTimelineTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor =
        isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.6);

    final statusIcon = switch (session.status) {
      SessionStatus.completed => Icons.check_circle_outline,
      SessionStatus.abandoned => Icons.cancel_outlined,
      SessionStatus.interrupted => Icons.error_outline,
    };

    final statusColor = switch (session.status) {
      SessionStatus.completed => SatoriColors.verdigris,
      SessionStatus.abandoned => SatoriColors.incenseEmber,
      SessionStatus.interrupted => SatoriColors.teaAmber,
    };

    final minutes = (session.actualDuration / 60).round();
    final timeStr =
        '${session.startAt.hour.toString().padLeft(2, '0')}:${session.startAt.minute.toString().padLeft(2, '0')}';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SatoriTheme.spacingL,
        vertical: SatoriTheme.spacingXS,
      ),
      leading: Icon(statusIcon, color: statusColor, size: 20),
      title: Row(
        children: [
          Text(
            '$minutes 分钟',
            style: SatoriTypography.body.copyWith(color: textColor),
          ),
          if (session.taskTag != null && session.taskTag!.isNotEmpty) ...[
            const SizedBox(width: SatoriTheme.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: SatoriColors.verdigris.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                session.taskTag!,
                style: SatoriTypography.caption.copyWith(
                  color: SatoriColors.verdigris,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        timeStr,
        style: SatoriTypography.caption.copyWith(color: subColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (session.summaryNote != null && session.summaryNote!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.note_outlined, size: 16, color: subColor),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onTimelineTap,
            icon: Icon(Icons.timeline, size: 18, color: subColor),
            tooltip: '查看当日时间轴',
          ),
        ],
      ),
    );
  }
}
