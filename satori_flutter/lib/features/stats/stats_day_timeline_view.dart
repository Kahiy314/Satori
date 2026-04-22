import 'package:flutter/material.dart';
import '../../core/models/focus_session.dart';
import '../../core/theme/theme.dart';
import '../../services/stats_aggregator.dart';
import 'stats_session_detail_view.dart';

/// 单日时间轴页面。
/// 交互：顶部横向日期选择 + 主体纵向小时刻度。
class StatsDayTimelineView extends StatefulWidget {
  final DateTime day;
  final StatsAggregator aggregator;

  const StatsDayTimelineView({
    super.key,
    required this.day,
    required this.aggregator,
  });

  @override
  State<StatsDayTimelineView> createState() => _StatsDayTimelineViewState();
}

class _StatsDayTimelineViewState extends State<StatsDayTimelineView> {
  late DateTime _selectedDay;
  List<FocusSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.day;
    _loadDay();
  }

  Future<void> _loadDay() async {
    setState(() => _loading = true);
    final sessions = await widget.aggregator.sessionsForDay(_selectedDay);
    if (!mounted) return;
    setState(() {
      _sessions = sessions..sort((a, b) => a.startAt.compareTo(b.startAt));
      _loading = false;
    });
  }

  void _switchDay(int delta) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: delta));
    });
    _loadDay();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;

    return Scaffold(
      backgroundColor: isDark ? SatoriColors.inkStone : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_selectedDay.month}月${_selectedDay.day}日',
          style: SatoriTypography.subtitle.copyWith(color: textColor),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: textColor),
            onPressed: () => _switchDay(-1),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: textColor),
            onPressed: () => _switchDay(1),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _sessions.isEmpty
              ? Center(
                  child: Text(
                    '当日无专注记录',
                    style: SatoriTypography.body.copyWith(
                      color: isDark
                          ? Colors.white38
                          : SatoriColors.inkSmoke.withValues(alpha: 0.4),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SatoriTheme.spacingL,
                    vertical: SatoriTheme.spacingM,
                  ),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    return _TimelineEntry(
                      session: _sessions[index],
                      onTap: () => _showSessionDetail(_sessions[index]),
                    );
                  },
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
}

class _TimelineEntry extends StatelessWidget {
  final FocusSession session;
  final VoidCallback onTap;

  const _TimelineEntry({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor =
        isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.6);

    final startTime =
        '${session.startAt.hour.toString().padLeft(2, '0')}:${session.startAt.minute.toString().padLeft(2, '0')}';
    final endTime = session.endAt != null
        ? '${session.endAt!.hour.toString().padLeft(2, '0')}:${session.endAt!.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final minutes = (session.actualDuration / 60).round();

    final barColor = switch (session.status) {
      SessionStatus.completed => SatoriColors.verdigris,
      SessionStatus.abandoned => SatoriColors.incenseEmber,
      SessionStatus.interrupted => SatoriColors.teaAmber,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: SatoriTheme.spacingM),
      child: InkWell(
        borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 时间轴线
              SizedBox(
                width: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(startTime,
                        style: SatoriTypography.caption
                            .copyWith(color: textColor)),
                    const Spacer(),
                    Text(endTime,
                        style:
                            SatoriTypography.caption.copyWith(color: subColor)),
                  ],
                ),
              ),
              const SizedBox(width: SatoriTheme.spacingS),
              // 竖线
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: SatoriTheme.spacingM),
              // 内容
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(SatoriTheme.spacingM),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius:
                        BorderRadius.circular(SatoriTheme.cornerMedium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$minutes 分钟 · ${session.mode == FocusMode.countdown ? '倒计时' : '正计时'}',
                        style: SatoriTypography.body.copyWith(color: textColor),
                      ),
                      if (session.taskTag != null &&
                          session.taskTag!.isNotEmpty) ...[
                        const SizedBox(height: SatoriTheme.spacingXS),
                        Text(
                          session.taskTag!,
                          style: SatoriTypography.caption.copyWith(
                            color: SatoriColors.verdigris,
                          ),
                        ),
                      ],
                      if (session.summaryNote != null &&
                          session.summaryNote!.isNotEmpty) ...[
                        const SizedBox(height: SatoriTheme.spacingXS),
                        Text(
                          session.summaryNote!,
                          style: SatoriTypography.caption
                              .copyWith(color: subColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (session.reflectionMood != null) ...[
                        const SizedBox(height: SatoriTheme.spacingXS),
                        Text(
                          _moodLabel(session.reflectionMood!),
                          style: SatoriTypography.caption.copyWith(
                            color: SatoriColors.stringGold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _moodLabel(ReflectionMood mood) {
    return switch (mood) {
      ReflectionMood.focused => '专注',
      ReflectionMood.distracted => '分心',
      ReflectionMood.productive => '高效',
      ReflectionMood.calm => '平静',
      ReflectionMood.tired => '疲惫',
    };
  }
}
