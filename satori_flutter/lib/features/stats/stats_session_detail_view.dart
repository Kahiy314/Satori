import 'package:flutter/material.dart';

import '../../core/models/focus_session.dart';
import '../../core/theme/theme.dart';

class StatsSessionDetailView extends StatelessWidget {
  const StatsSessionDetailView({super.key, required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor =
        isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.6);

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
          '专注详情',
          style: SatoriTypography.subtitle.copyWith(color: textColor),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(SatoriTheme.spacingL),
        children: [
          _SummaryCard(session: session),
          const SizedBox(height: SatoriTheme.spacingL),
          _InfoSection(
            title: '时间信息',
            children: [
              _InfoRow(label: '开始', value: _formatDateTime(session.startAt)),
              _InfoRow(
                label: '结束',
                value: session.endAt != null
                    ? _formatDateTime(session.endAt!)
                    : '未记录',
              ),
              _InfoRow(
                  label: '实际时长',
                  value: _formatDuration(session.actualDuration)),
              _InfoRow(
                label: '计划时长',
                value: session.plannedDuration != null
                    ? _formatDuration(session.plannedDuration!)
                    : '正计时',
              ),
            ],
          ),
          const SizedBox(height: SatoriTheme.spacingL),
          _InfoSection(
            title: '会话信息',
            children: [
              _InfoRow(label: '模式', value: _modeLabel(session.mode)),
              _InfoRow(label: '状态', value: _statusLabel(session.status)),
              _InfoRow(
                label: '标签',
                value: session.taskTag?.isNotEmpty == true
                    ? session.taskTag!
                    : '未填写',
              ),
              _InfoRow(
                label: '感受',
                value: session.reflectionMood != null
                    ? _moodLabel(session.reflectionMood!)
                    : '未填写',
              ),
              _InfoRow(
                label: '计入历史',
                value: session.isCountedInHistory ? '是' : '否',
              ),
            ],
          ),
          const SizedBox(height: SatoriTheme.spacingL),
          _InfoSection(
            title: '小结备注',
            children: [
              Padding(
                padding: const EdgeInsets.all(SatoriTheme.spacingM),
                child: Text(
                  session.summaryNote?.isNotEmpty == true
                      ? session.summaryNote!
                      : '本次未填写小结备注。',
                  style: SatoriTypography.body.copyWith(color: textColor),
                ),
              ),
            ],
          ),
          if (session.updatedAt != null || session.userId != null) ...[
            const SizedBox(height: SatoriTheme.spacingL),
            _InfoSection(
              title: '同步信息',
              children: [
                _InfoRow(
                  label: '用户',
                  value: session.userId?.isNotEmpty == true
                      ? session.userId!
                      : '本地记录',
                ),
                _InfoRow(
                  label: '更新时间',
                  value: session.updatedAt != null
                      ? _formatDateTime(session.updatedAt!)
                      : '未同步',
                ),
              ],
            ),
          ],
          const SizedBox(height: SatoriTheme.spacingXXL),
          Text(
            '若本条记录来自多端同步，详情页展示的是当前本地缓存中的最新版本。',
            style: SatoriTypography.caption.copyWith(color: subColor),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  String _formatDuration(double seconds) {
    final totalSeconds = seconds.round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final remainSeconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    }
    if (minutes > 0) {
      return '$minutes分$remainSeconds秒';
    }
    return '$remainSeconds秒';
  }

  String _modeLabel(FocusMode mode) {
    return switch (mode) {
      FocusMode.countdown => '倒计时',
      FocusMode.countUp => '正计时',
    };
  }

  String _statusLabel(SessionStatus status) {
    return switch (status) {
      SessionStatus.completed => '已完成',
      SessionStatus.abandoned => '已放弃',
      SessionStatus.interrupted => '已中断',
    };
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.8);
    final statusColor = switch (session.status) {
      SessionStatus.completed => SatoriColors.verdigris,
      SessionStatus.abandoned => SatoriColors.incenseEmber,
      SessionStatus.interrupted => SatoriColors.teaAmber,
    };

    return Container(
      padding: const EdgeInsets.all(SatoriTheme.spacingL),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(SatoriTheme.cornerLarge),
      ),
      child: Column(
        children: [
          Icon(Icons.self_improvement, size: 32, color: statusColor),
          const SizedBox(height: SatoriTheme.spacingM),
          Text(
            '${(session.actualDuration / 60).round()} 分钟',
            style: SatoriTypography.timer.copyWith(color: statusColor),
          ),
          const SizedBox(height: SatoriTheme.spacingXS),
          Text(
            session.taskTag?.isNotEmpty == true ? session.taskTag! : '未设置标签',
            style: SatoriTypography.caption.copyWith(color: statusColor),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.8);
    final titleColor = isDark ? Colors.white70 : SatoriColors.inkSmoke;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SatoriTypography.subtitle.copyWith(color: titleColor),
        ),
        const SizedBox(height: SatoriTheme.spacingS),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor =
        isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SatoriTheme.spacingM,
        vertical: SatoriTheme.spacingS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: SatoriTypography.caption.copyWith(color: subColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: SatoriTypography.body.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
