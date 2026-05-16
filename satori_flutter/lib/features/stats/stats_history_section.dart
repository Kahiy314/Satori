import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/components/section_page_header.dart';
import '../../core/models/focus_session.dart';
import '../../core/theme/theme.dart';
import '../../services/stats_aggregator.dart';
import 'stats_day_timeline_view.dart';
import 'stats_session_detail_view.dart';

/// 历史记录页。
///
/// - 默认按时间窗口动态加载，避免一次性拉满整段历史。
/// - 搜索时再按更长范围做全文匹配。
/// - 页面切离后由父级 AnimatedSwitcher 销毁，主动释放已加载列表。
class StatsHistorySection extends StatefulWidget {
  final StatsAggregator aggregator;
  final Future<void> Function()? syncWithCloud;

  const StatsHistorySection({
    super.key,
    required this.aggregator,
    this.syncWithCloud,
  });

  @override
  State<StatsHistorySection> createState() => _StatsHistorySectionState();
}

class _StatsHistorySectionState extends State<StatsHistorySection> {
  static const _windowDays = 21;
  static const _maxLookbackDays = 3650;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;
  List<FocusSession> _sessions = [];
  List<FocusSession> _searchResults = [];
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _searching = false;
  bool _hasMore = true;
  int _expectedTotalCount = 0;
  DateTime? _nextWindowEnd;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _refresh();
  }

  @override
  void didUpdateWidget(covariant StatsHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aggregator != widget.aggregator) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _sessions = const [];
    _searchResults = const [];
    super.dispose();
  }

  Future<void> _refresh() async {
    final today = _today();
    setState(() {
      _loadingInitial = true;
      _loadingMore = false;
      _searching = _query.isNotEmpty;
      _hasMore = true;
      _sessions = [];
      _searchResults = [];
      _expectedTotalCount = 0;
      _nextWindowEnd = today;
    });

    await widget.syncWithCloud?.call();
    final overview = await widget.aggregator.overview();
    if (!mounted) return;

    setState(() {
      _expectedTotalCount = overview.totalSessions;
      _hasMore = overview.totalSessions > 0;
    });

    if (_query.isNotEmpty) {
      setState(() => _loadingInitial = false);
      await _performSearch(_query);
      return;
    }

    if (overview.totalSessions == 0) {
      setState(() => _loadingInitial = false);
      return;
    }

    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _query.isNotEmpty) return;

    final end = _nextWindowEnd ?? _today();
    if (_today().difference(end).inDays > _maxLookbackDays) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() => _loadingMore = true);
    final start = end.subtract(const Duration(days: _windowDays - 1));
    final chunk = await widget.aggregator.sessionsInRange(start, end);
    if (!mounted) return;

    final merged = [..._sessions, ...chunk]
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
    final nextWindowEnd = start.subtract(const Duration(days: 1));

    setState(() {
      _sessions = merged;
      _nextWindowEnd = nextWindowEnd;
      _loadingInitial = false;
      _loadingMore = false;
      _hasMore = merged.length < _expectedTotalCount &&
          _today().difference(nextWindowEnd).inDays <= _maxLookbackDays;
    });
  }

  void _handleScroll() {
    if (_query.isNotEmpty || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 480) {
      unawaited(_loadMore());
    }
  }

  void _handleQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      final query = value.trim();
      if (!mounted || query == _query) return;

      setState(() {
        _query = query;
      });

      if (query.isEmpty) {
        setState(() {
          _searching = false;
          _searchResults = [];
        });
        return;
      }

      unawaited(_performSearch(query));
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searching = true;
      _searchResults = [];
    });

    final to = _today();
    final from = to.subtract(const Duration(days: _maxLookbackDays));
    final sessions = await widget.aggregator.sessionsInRange(from, to);
    if (!mounted || query != _query) return;

    final normalized = query.toLowerCase();
    final results = sessions.where((session) {
      return _buildSearchableText(session).contains(normalized);
    }).toList();

    setState(() {
      _searching = false;
      _searchResults = results;
    });
  }

  String _buildSearchableText(FocusSession session) {
    final buffer = StringBuffer()
      ..write(session.taskTag?.toLowerCase() ?? '')
      ..write(' ')
      ..write(session.summaryNote?.toLowerCase() ?? '')
      ..write(' ')
      ..write(_statusLabel(session.status).toLowerCase())
      ..write(' ')
      ..write(_modeLabel(session.mode).toLowerCase())
      ..write(' ')
      ..write(_moodLabel(session.reflectionMood).toLowerCase())
      ..write(' ')
      ..write('${session.startAt.month}/${session.startAt.day} ')
      ..write('${session.startAt.year}');
    return buffer.toString();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<FocusSession> get _activeSessions =>
      _query.isEmpty ? _sessions : _searchResults;

  bool get _showStatusBlock =>
      _loadingInitial || _searching || _activeSessions.isEmpty;

  @override
  Widget build(BuildContext context) {
    final activeSessions = _activeSessions;
    final loaderCount = !_showStatusBlock && _query.isEmpty && (_loadingMore || _hasMore)
        ? 1
        : 0;
    final itemCount = 3 +
        (_showStatusBlock ? 1 : 0) +
        activeSessions.length +
        loaderCount;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          controller: _scrollController,
          cacheExtent: 720,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: SatoriTheme.spacingXXL),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const SectionPageHeader(title: '行迹');
            }
            if (index == 1) {
              return _HistorySearchBar(
                controller: _searchController,
                query: _query,
                onChanged: _handleQueryChanged,
                onClear: () {
                  _searchController.clear();
                  _handleQueryChanged('');
                },
              );
            }
            if (index == 2) {
              return _HistoryMeta(
                text: _query.isNotEmpty
                    ? (_searching
                        ? '正在检索历史记录…'
                        : '共找到 ${activeSessions.length} 条匹配记录')
                    : (_expectedTotalCount == 0
                        ? '暂无历史记录'
                        : '已加载 ${activeSessions.length} / $_expectedTotalCount 条，继续下滑可加载更早记录'),
              );
            }

            var currentIndex = index - 3;
            if (_showStatusBlock) {
              if (currentIndex == 0) {
                return _HistoryStatusBlock(
                  loading: _loadingInitial || _searching,
                  message: _query.isNotEmpty ? '没有匹配的历史记录' : '暂无专注记录',
                );
              }
              currentIndex -= 1;
            }

            if (currentIndex < activeSessions.length) {
              final session = activeSessions[currentIndex];
              return _HistoryTile(
                session: session,
                onTap: () => _showSessionDetail(session),
                onTimelineTap: () => _showDayTimeline(session.startAt),
              );
            }

            return const Padding(
              padding: EdgeInsets.symmetric(vertical: SatoriTheme.spacingL),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          },
        ),
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

  String _statusLabel(SessionStatus status) {
    return switch (status) {
      SessionStatus.completed => '已完成',
      SessionStatus.abandoned => '已放弃',
      SessionStatus.interrupted => '已中断',
    };
  }

  String _modeLabel(FocusMode mode) {
    return switch (mode) {
      FocusMode.countdown => '倒计时',
      FocusMode.countUp => '正计时',
    };
  }

  String _moodLabel(ReflectionMood? mood) {
    return switch (mood) {
      ReflectionMood.focused => '专注',
      ReflectionMood.distracted => '分心',
      ReflectionMood.productive => '高效',
      ReflectionMood.calm => '平静',
      ReflectionMood.tired => '疲惫',
      null => '',
    };
  }
}

class _HistorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _HistorySearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : SatoriColors.ricePaper.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SatoriTheme.spacingL,
        SatoriTheme.spacingS,
        112,
        SatoriTheme.spacingS,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: SatoriTypography.body.copyWith(
          color: isDark ? Colors.white : SatoriColors.inkSmoke,
        ),
        decoration: InputDecoration(
          hintText: '搜索标签、备注、状态、模式',
          hintStyle: SatoriTypography.body.copyWith(
            color: isDark ? Colors.white38 : SatoriColors.inkSmoke.withValues(alpha: 0.38),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.48),
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
            borderSide: BorderSide(
              color: SatoriColors.verdigris.withValues(alpha: 0.42),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryMeta extends StatelessWidget {
  final String text;

  const _HistoryMeta({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.58);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SatoriTheme.spacingL,
        SatoriTheme.spacingS,
        SatoriTheme.spacingL,
        SatoriTheme.spacingS,
      ),
      child: Text(
        text,
        style: SatoriTypography.caption.copyWith(color: color),
      ),
    );
  }
}

class _HistoryStatusBlock extends StatelessWidget {
  final bool loading;
  final String message;

  const _HistoryStatusBlock({
    required this.loading,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white38 : SatoriColors.inkSmoke.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.all(SatoriTheme.spacingXL),
      child: Center(
        child: loading
            ? const CircularProgressIndicator.adaptive()
            : Text(
                message,
                style: SatoriTypography.body.copyWith(color: color),
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
    final timeLabel =
        '${session.startAt.month.toString().padLeft(2, '0')}-${session.startAt.day.toString().padLeft(2, '0')} '
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
        '$timeLabel · ${_modeLabel(session.mode)} · ${_statusLabel(session.status)}',
        style: SatoriTypography.caption.copyWith(color: subColor),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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

  String _statusLabel(SessionStatus status) {
    return switch (status) {
      SessionStatus.completed => '已完成',
      SessionStatus.abandoned => '已放弃',
      SessionStatus.interrupted => '已中断',
    };
  }

  String _modeLabel(FocusMode mode) {
    return switch (mode) {
      FocusMode.countdown => '倒计时',
      FocusMode.countUp => '正计时',
    };
  }
}