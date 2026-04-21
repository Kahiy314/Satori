import 'package:flutter/material.dart';
import '../../core/components/section_page_header.dart';
import '../../core/theme/theme.dart';
import '../../services/stats_aggregator.dart';
import 'stats_overview_section.dart';
import 'stats_history_section.dart';

/// 行迹（统计）主页面。
/// 首版拆成：概览 + 历史列表 + 单日时间轴。
/// 热力图与年趋势放后续小版本。
class StatsView extends StatefulWidget {
  final StatsAggregator aggregator;

  const StatsView({super.key, required this.aggregator});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  StatsSnapshot _overview = StatsSnapshot.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant StatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 每次页面重建时刷新数据（导航回来时）
    _loadData();
  }

  Future<void> _loadData() async {
    final overview = await widget.aggregator.overview();
    if (!mounted) return;
    setState(() {
      _overview = overview;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SatoriColors.inkStone : Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    // 顶部标题
                    SliverToBoxAdapter(
                      child: const SectionPageHeader(title: '行迹'),
                    ),

                    // 概览卡片
                    SliverToBoxAdapter(
                      child: StatsOverviewSection(snapshot: _overview),
                    ),

                    // 历史列表标题
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          SatoriTheme.spacingL,
                          SatoriTheme.spacingXL,
                          SatoriTheme.spacingL,
                          SatoriTheme.spacingS,
                        ),
                        child: Text(
                          '历史记录',
                          style: SatoriTypography.title.copyWith(
                            color: isDark ? Colors.white70 : SatoriColors.inkSmoke,
                          ),
                        ),
                      ),
                    ),

                    // 历史列表
                    StatsHistorySection(aggregator: widget.aggregator),
                  ],
                ),
              ),
      ),
    );
  }
}
