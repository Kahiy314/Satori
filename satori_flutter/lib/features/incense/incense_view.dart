import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/models/focus_session.dart';
import '../../core/components/drawer_entry_button.dart';
import '../../core/components/paper_texture_background.dart';
import '../../services/haptic_service.dart';
import '../../services/user_preferences.dart';
import '../../app/providers.dart';
import 'incense_view_model.dart';
import 'components/calligraphic_smoke_view.dart';
import 'components/incense_ember_view.dart';
import 'components/incense_stick_view.dart';
import 'components/ring_control_view.dart';

/// 焚香主页面 — 文人案头仪式界面
///
/// 设计概念：
/// 倒计时态 = "器物、静置、燃烧、上升"
/// 正计时态 = "气、流动、聚拢、内观"
/// 共享世界观：东方、克制、安静、留白、非炫技
class IncenseView extends ConsumerStatefulWidget {
  final VoidCallback? onDrawerTap;
  const IncenseView({super.key, this.onDrawerTap});

  @override
  ConsumerState<IncenseView> createState() => _IncenseViewState();
}

class _IncenseViewState extends ConsumerState<IncenseView> {
  IncenseViewModel? _vmRef;
  StreamSubscription<IncenseSessionEvent>? _eventSub;

  // Convenience accessor — non-null after didChangeDependencies
  IncenseViewModel get _vm => _vmRef!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newVm = ref.watch(incenseViewModelProvider);
    if (newVm != _vmRef) {
      _vmRef?.removeListener(_onChanged);
      _eventSub?.cancel();
      _vmRef = newVm;
      _vmRef!.addListener(_onChanged);
      _eventSub = _vmRef!.sessionEvents.listen(_onSessionEvent);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onSessionEvent(IncenseSessionEvent event) {
    if (!mounted) return;
    if (event == IncenseSessionEvent.completed) {
      _showSessionSummary();
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _vmRef?.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: _onVerticalSwipe,
      child: Stack(
        children: [
          // ── 纸纹材质背景 ──
          const PaperTextureBackground(),

          // ── 主内容 ──
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: SatoriTheme.animNormal,
              transitionBuilder: (child, anim) {
                return FadeTransition(opacity: anim, child: child);
              },
              child: _vm.timerMode == TimerMode.countdown
                  ? _CountdownLayout(
                      key: const ValueKey('countdown'),
                      vm: _vm,
                      onAction: _handleAction,
                      onCustomDuration: _showCustomDurationSheet,
                      onTagInput: _showTagInput,
                    )
                  : _CountUpLayout(
                      key: const ValueKey('countup'),
                      vm: _vm,
                      onAction: _handleAction,
                      onTagInput: _showTagInput,
                    ),
            ),
          ),

          // ── 左上角宣纸入口 — 极淡，不破坏安静感 ──
          if (widget.onDrawerTap != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + SatoriTheme.spacingS,
              left: SatoriTheme.spacingS,
              child: DrawerEntryButton(onTap: widget.onDrawerTap!),
            ),

          // ── 右上角模式切换 — 仅 idle 时显示 ──
          if (_vm.state == TimerState.idle)
            Positioned(
              top: MediaQuery.of(context).padding.top + SatoriTheme.spacingM,
              right: SatoriTheme.spacingM,
              child: _buildModeTab(),
            ),
        ],
      ),
    );
  }

  void _onVerticalSwipe(DragEndDetails details) {
    if (_vm.state == TimerState.running) return;
    final v = details.primaryVelocity ?? 0;
    if (v > 200) {
      _vm.switchMode(TimerMode.countUp);
    } else if (v < -200) {
      _vm.switchMode(TimerMode.countdown);
    }
  }

  // ── Header ──

  void _handleAction() {
    HapticService.instance.mediumTap();
    switch (_vm.state) {
      case TimerState.idle:
        _vm.start();
        break;
      case TimerState.running:
        _vm.pause();
        break;
      case TimerState.paused:
        _vm.start();
        break;
      case TimerState.completed:
        _vm.reset();
        break;
    }
  }

  Widget _buildModeTab() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton('倒计时', TimerMode.countdown),
          _modeButton('正计时', TimerMode.countUp),
        ],
      ),
    );
  }

  Widget _modeButton(String text, TimerMode mode) {
    final isSelected = _vm.timerMode == mode;
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        if (_vm.state == TimerState.running) return;
        HapticService.instance.lightTap();
        _vm.switchMode(mode);
      },
      child: AnimatedContainer(
        duration: SatoriTheme.animNormal,
        width: 56,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? SatoriColors.incenseEmber.withValues(alpha: 0.85) : Colors.transparent,
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

  // ── Timer Display ── (removed: now inline in layouts)
  // ── Controls ── (removed: replaced by RingControlView in layouts)

  void _showCustomDurationSheet() {
    _vm.customMinutes = (_vm.totalDuration / 60).toInt();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomDurationSheet(vm: _vm),
    );
  }

  void _showTagInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagInputSheet(
        vm: _vm,
        userPreferences: ref.read(userPreferencesProvider),
      ),
    );
  }

  void _showSessionSummary() {
    final session = _vm.lastFinishedSession;
    if (session == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionSummarySheet(
        session: session,
        onSave: (note, mood) async {
          await _vm.updateSessionSummary(
            summaryNote: note,
            reflectionMood: mood,
          );
          _vm.reset();
          if (mounted) Navigator.pop(context);
        },
        onSkip: () {
          _vm.reset();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 倒计时布局 — "器物居中、竖向留白、烟气上升、信息很少"
//
// 参考图 2：
// - 页面主体：居中香炉 + 垂直细香 + 游丝烟
// - 香炉位于中下部
// - 时间在香炉下方，字号最大
// - 时间上方有"专注中..."状态文字
// - 时间下方圆环控制点
// ══════════════════════════════════════════════════════════

class _CountdownLayout extends StatelessWidget {
  final IncenseViewModel vm;
  final VoidCallback onAction;
  final VoidCallback onCustomDuration;
  final VoidCallback onTagInput;
  const _CountdownLayout({
    super.key,
    required this.vm,
    required this.onAction,
    required this.onCustomDuration,
    required this.onTagInput,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = vm.state == TimerState.running;
    final isPaused = vm.state == TimerState.paused;
    final isIdle = vm.state == TimerState.idle;
    final isCompleted = vm.state == TimerState.completed;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        Colors.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        // 参考图中：香炉占页面很大比例，居中偏下
        // 香炉尺寸：宽度约为屏宽 35~40%
        final burnerW = w * 0.38;
        final burnerH = burnerW * 0.55; // 宽高比约 2:1
        final burnerTop = h * 0.42;     // 炉子上沿
        final burnerCx = w / 2;

        // 香身：从炉口处向上延伸
        final stickMaxH = h * 0.30;
        final visibleStickH = stickMaxH * (1 - vm.burnProgress);
        // 香底部嵌入炉口内（炉口在炉身上方约 18% 位置）
        final stickBottom = burnerTop + burnerH * 0.12;
        final stickTop = stickBottom - visibleStickH;

        // 烟起点：从香顶向上
        final smokeBottom = stickTop;
        final smokeTop = (smokeBottom - h * 0.40).clamp(0.0, smokeBottom);

        return Stack(
          children: [
            // ── 游丝烟 ──
            Positioned(
              left: burnerCx - 100,
              top: smokeTop,
              child: SizedBox(
                width: 200,
                height: smokeBottom - smokeTop,
                child: CalligraphicSmokeView(
                  opacity: isRunning ? 1.0 : (isPaused ? 0.4 : 0.15),
                  burnProgress: vm.burnProgress,
                ),
              ),
            ),

            // ── 香炉（炉身 + 后沿，位于香身之下） ──
            Positioned(
              left: burnerCx - burnerW / 2,
              top: burnerTop,
              child: SizedBox(
                width: burnerW,
                height: burnerH,
                child: const IncenseBurnerView(),
              ),
            ),

            // ── 香身（在炉身之上，但被前沿遮挡） ──
            if (visibleStickH > 2)
              Positioned(
                left: burnerCx - 2.5,
                top: stickTop,
                child: SizedBox(
                  width: 5,
                  height: visibleStickH,
                  child: IncenseStickView(burnProgress: vm.burnProgress),
                ),
              ),

            // ── 余烬 ──
            if (isRunning && visibleStickH > 2)
              Positioned(
                left: burnerCx - 7,
                top: stickTop - 5,
                child: const SizedBox(
                  width: 14,
                  height: 10,
                  child: IncenseEmberView(),
                ),
              ),

            // ── 香炉前沿（遮住香身穿过炉口的部分） ──
            Positioned(
              left: burnerCx - burnerW / 2,
              top: burnerTop,
              child: SizedBox(
                width: burnerW,
                height: burnerH,
                child: const IncenseBurnerFrontRim(),
              ),
            ),

            // ── 信息区域（香炉下方） ──
            Positioned(
              left: 0,
              right: 0,
              top: burnerTop + burnerH + 8,
              bottom: 0,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: SatoriTheme.spacingL),

                    // 状态文字
                    AnimatedOpacity(
                      duration: SatoriTheme.animNormal,
                      opacity: isRunning || isPaused ? 1.0 : 0.0,
                      child: Text(
                        isPaused ? '已暂停' : '专注中...',
                        style: SatoriTypography.caption.copyWith(
                          color: textColor.withValues(alpha: 0.35),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: SatoriTheme.spacingS),

                    // 大号时间
                    Text(
                      vm.formattedTime,
                      style: SatoriTypography.timer.copyWith(
                        color: textColor.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: SatoriTheme.spacingL),

                    // 圆环控制 / 预设 / 暂停操作
                    if (isIdle) ...[
                      _buildPresetRow(context, onCustomDuration),
                      const SizedBox(height: SatoriTheme.spacingS),
                      _buildTagChip(context, onTagInput),
                      const SizedBox(height: SatoriTheme.spacingM),
                      RingControlView(
                        onTap: onAction,
                        icon: Icons.local_fire_department,
                        isActive: false,
                      ),
                    ] else if (isRunning)
                      RingControlView(
                        onTap: onAction,
                        icon: Icons.pause,
                        progress: vm.burnProgress,
                        isActive: true,
                      )
                    else if (isPaused)
                      _buildPausedRow(context)
                    else if (isCompleted)
                      RingControlView(
                        onTap: onAction,
                        icon: Icons.local_fire_department,
                        isActive: false,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPresetRow(BuildContext context, VoidCallback onCustom) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...IncenseViewModel.presets.map((p) {
            final isSelected = vm.totalDuration == p.minutes * 60.0;
            return Padding(
              padding: const EdgeInsets.only(right: SatoriTheme.spacingS),
              child: GestureDetector(
                onTap: () {
                  HapticService.instance.lightTap();
                  vm.selectPreset(p.minutes);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SatoriColors.incenseEmber.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(SatoriTheme.cornerPill),
                  ),
                  child: Text(
                    p.label,
                    style: SatoriTypography.caption.copyWith(
                      color: isSelected
                          ? SatoriColors.incenseEmber
                          : Colors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () {
              HapticService.instance.lightTap();
              onCustom();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
              ),
              child: Icon(Icons.tune,
                  size: 12, color: Colors.grey.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            HapticService.instance.lightTap();
            vm.start();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: SatoriColors.incenseEmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
            ),
            child: Text('继续',
                style: SatoriTypography.caption
                    .copyWith(color: SatoriColors.incenseEmber)),
          ),
        ),
        const SizedBox(width: SatoriTheme.spacingL),
        GestureDetector(
          onTap: () {
            HapticService.instance.lightTap();
            vm.reset();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
            ),
            child: Text('结束',
                style: SatoriTypography.caption
                    .copyWith(color: Colors.grey.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, VoidCallback onTap) {
    final tag = vm.currentTaskTag;
    return GestureDetector(
      onTap: () {
        HapticService.instance.lightTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline,
              size: 14,
              color: tag != null
                  ? SatoriColors.incenseEmber.withValues(alpha: 0.7)
                  : Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Text(
              tag ?? '添加标签',
              style: SatoriTypography.caption.copyWith(
                color: tag != null
                    ? SatoriColors.incenseEmber
                    : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 正计时布局 — "气、流动、内观"
//
// - 上方："已专注:" + 大号累计时间
// - 中心：游丝烟从屏幕下端缓缓上升
// - 下方：控制按钮
// ══════════════════════════════════════════════════════════

class _CountUpLayout extends StatelessWidget {
  final IncenseViewModel vm;
  final VoidCallback onAction;
  final VoidCallback onTagInput;
  const _CountUpLayout({
    super.key,
    required this.vm,
    required this.onAction,
    required this.onTagInput,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = vm.state == TimerState.running;
    final isPaused = vm.state == TimerState.paused;
    final isIdle = vm.state == TimerState.idle;
    final isCompleted = vm.state == TimerState.completed;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        Colors.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        return Stack(
          children: [
            // ── 游丝烟（从屏幕底端往上飘） ──
            Positioned(
              left: w / 2 - 100,
              top: h * 0.12,
              bottom: 0,
              child: SizedBox(
                width: 200,
                child: CalligraphicSmokeView(
                  opacity: isRunning ? 0.85 : (isPaused ? 0.4 : 0.2),
                ),
              ),
            ),

            // ── 上方：时间信息 ──
            Positioned(
              left: 0,
              right: 0,
              top: h * 0.08,
              child: Column(
                children: [
                  AnimatedOpacity(
                    duration: SatoriTheme.animNormal,
                    opacity: isRunning || isPaused ? 1.0 : 0.5,
                    child: Text(
                      isIdle ? '' : (isPaused ? '已暂停' : '已专注:'),
                      style: SatoriTypography.caption.copyWith(
                        color: textColor.withValues(alpha: 0.35),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: SatoriTheme.spacingXS),
                  Text(
                    vm.formattedTime,
                    style: SatoriTypography.timer.copyWith(
                      color: textColor.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),

            // ── 下方控制 ──
            Positioned(
              left: 0,
              right: 0,
              bottom: h * 0.08,
              child: Column(
                children: [
                  if (isIdle) ...[
                    _buildTagChip(context),
                    const SizedBox(height: SatoriTheme.spacingM),
                    RingControlView(
                      onTap: onAction,
                      icon: Icons.play_arrow,
                      isActive: false,
                    ),
                  ]
                  else if (isRunning)
                    RingControlView(
                      onTap: onAction,
                      icon: Icons.pause,
                      progress: vm.burnProgress,
                      isActive: true,
                    )
                  else if (isPaused)
                    _buildPausedRow(context)
                  else if (isCompleted)
                    RingControlView(
                      onTap: onAction,
                      icon: Icons.refresh,
                      isActive: false,
                    ),

                  // 正计时专用停止按钮
                  if (isPaused) ...[
                    const SizedBox(height: SatoriTheme.spacingM),
                    GestureDetector(
                      onTap: () {
                        HapticService.instance.lightTap();
                        vm.stopCountUp();
                      },
                      child: Text(
                        '完成本次专注',
                        style: SatoriTypography.caption.copyWith(
                          color: SatoriColors.incenseEmber.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPausedRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            HapticService.instance.lightTap();
            vm.start();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: SatoriColors.incenseEmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
            ),
            child: Text('继续',
                style: SatoriTypography.caption
                    .copyWith(color: SatoriColors.incenseEmber)),
          ),
        ),
        const SizedBox(width: SatoriTheme.spacingL),
        GestureDetector(
          onTap: () {
            HapticService.instance.lightTap();
            vm.reset();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
            ),
            child: Text('放弃',
                style: SatoriTypography.caption
                    .copyWith(color: Colors.grey.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context) {
    final tag = vm.currentTaskTag;
    return GestureDetector(
      onTap: () {
        HapticService.instance.lightTap();
        onTagInput();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline,
              size: 14,
              color: tag != null
                  ? SatoriColors.incenseEmber.withValues(alpha: 0.7)
                  : Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Text(
              tag ?? '添加标签',
              style: SatoriTypography.caption.copyWith(
                color: tag != null
                    ? SatoriColors.incenseEmber
                    : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 自定义时长弹窗（全屏） ──

class _CustomDurationSheet extends StatefulWidget {
  final IncenseViewModel vm;
  const _CustomDurationSheet({required this.vm});

  @override
  State<_CustomDurationSheet> createState() => _CustomDurationSheetState();
}

class _CustomDurationSheetState extends State<_CustomDurationSheet> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.vm.customMinutes;
  }

  double get _previewHeight {
    final ratio = (_minutes - IncenseViewModel.minMinutes) /
        (IncenseViewModel.maxMinutes - IncenseViewModel.minMinutes);
    return 60 + ratio * 200;
  }

  double get _previewWidth {
    final ratio = (_minutes - IncenseViewModel.minMinutes) /
        (IncenseViewModel.maxMinutes - IncenseViewModel.minMinutes);
    return 3 + ratio * 5;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E20) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: SatoriTheme.spacingL),
            Text('自定义专注时长', style: SatoriTypography.title),
            const SizedBox(height: SatoriTheme.spacingXL),
            Text(
              '$_minutes 分钟',
              style: SatoriTypography.timer.copyWith(
                color: SatoriColors.incenseEmber,
                fontSize: 48,
              ),
            ),
            const Spacer(),
            // 香身预览
            SizedBox(
              height: 260,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _previewWidth,
                    height: _previewHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_previewWidth / 3),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [SatoriColors.sandalwood, Color(0xD98B6B4A)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: SizedBox(
                      width: 50, height: 30,
                      child: CustomPaint(painter: _MiniburnerPainter()),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 滑块
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
              child: Column(
                children: [
                  Slider(
                    value: _minutes.toDouble(),
                    min: IncenseViewModel.minMinutes.toDouble(),
                    max: IncenseViewModel.maxMinutes.toDouble(),
                    divisions: IncenseViewModel.maxMinutes - IncenseViewModel.minMinutes,
                    activeColor: SatoriColors.incenseEmber,
                    onChanged: (v) => setState(() => _minutes = v.toInt()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${IncenseViewModel.minMinutes} 分钟',
                          style: SatoriTypography.caption.copyWith(color: Colors.grey)),
                      Text('${IncenseViewModel.maxMinutes} 分钟',
                          style: SatoriTypography.caption.copyWith(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: SatoriTheme.spacingXL),
            // 确认
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SatoriColors.incenseEmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    widget.vm.customMinutes = _minutes;
                    widget.vm.applyCustomDuration();
                    Navigator.pop(context);
                  },
                  child: Text('确定', style: SatoriTypography.subtitle),
                ),
              ),
            ),
            const SizedBox(height: SatoriTheme.spacingL),
          ],
        ),
      ),
    );
  }
}

class _MiniburnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: size.width, height: size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SatoriColors.sandalwood, Color(0xB38B6B4A)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 标签输入弹窗 ──

class _TagInputSheet extends StatefulWidget {
  final IncenseViewModel vm;
  final UserPreferences userPreferences;
  const _TagInputSheet({required this.vm, required this.userPreferences});

  @override
  State<_TagInputSheet> createState() => _TagInputSheetState();
}

class _TagInputSheetState extends State<_TagInputSheet> {
  late final TextEditingController _controller;
  List<String> _recentTags = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.vm.currentTaskTag ?? '');
    _loadRecentTags();
  }

  Future<void> _loadRecentTags() async {
    final tags = await widget.userPreferences.recentTags();
    if (mounted) setState(() => _recentTags = tags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyTag(String tag) {
    widget.vm.setTaskTag(tag.isEmpty ? null : tag);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E20) : Colors.white;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SatoriTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: SatoriTheme.spacingL),
            Text('本次专注标签', style: SatoriTypography.title),
            const SizedBox(height: SatoriTheme.spacingM),
            TextField(
              controller: _controller,
              autofocus: true,
              style: SatoriTypography.subtitle,
              decoration: InputDecoration(
                hintText: '如：读书、写代码、冥想...',
                hintStyle: SatoriTypography.caption.copyWith(
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: SatoriColors.incenseEmber.withValues(alpha: 0.5),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12,
                ),
              ),
              onSubmitted: _applyTag,
            ),
            if (_recentTags.isNotEmpty) ...[
              const SizedBox(height: SatoriTheme.spacingM),
              Text('最近使用',
                  style: SatoriTypography.caption
                      .copyWith(color: Colors.grey.withValues(alpha: 0.5))),
              const SizedBox(height: SatoriTheme.spacingS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentTags.map((tag) => GestureDetector(
                  onTap: () => _applyTag(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
                    ),
                    child: Text(tag, style: SatoriTypography.caption),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: SatoriTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.vm.setTaskTag(null);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('清除',
                        style: SatoriTypography.caption
                            .copyWith(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyTag(_controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SatoriColors.incenseEmber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('确定', style: SatoriTypography.caption
                        .copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SatoriTheme.spacingS),
          ],
        ),
      ),
    );
  }
}

// ── 会话小结弹窗 ──

class _SessionSummarySheet extends StatefulWidget {
  final FocusSession session;
  final Future<void> Function(String? note, ReflectionMood? mood) onSave;
  final VoidCallback onSkip;

  const _SessionSummarySheet({
    required this.session,
    required this.onSave,
    required this.onSkip,
  });

  @override
  State<_SessionSummarySheet> createState() => _SessionSummarySheetState();
}

class _SessionSummarySheetState extends State<_SessionSummarySheet> {
  final _noteController = TextEditingController();
  ReflectionMood? _selectedMood;

  String get _durationText {
    final secs = widget.session.actualDuration.toInt();
    final mins = secs ~/ 60;
    final remainSecs = secs % 60;
    if (mins >= 60) {
      final hrs = mins ~/ 60;
      final remainMins = mins % 60;
      return '$hrs小时${remainMins}分钟';
    }
    if (mins > 0) return '$mins分${remainSecs}秒';
    return '$remainSecs秒';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E20) : Colors.white;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: SatoriTheme.spacingXL),

              // 完成图标
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: SatoriColors.incenseEmber.withValues(alpha: 0.7),
              ),
              const SizedBox(height: SatoriTheme.spacingM),
              Text(
                '专注完成',
                style: SatoriTypography.title.copyWith(color: textColor),
              ),
              const SizedBox(height: SatoriTheme.spacingS),
              Text(
                _durationText,
                style: SatoriTypography.timer.copyWith(
                  color: SatoriColors.incenseEmber,
                ),
              ),
              if (widget.session.taskTag != null) ...[
                const SizedBox(height: SatoriTheme.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SatoriColors.incenseEmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
                  ),
                  child: Text(
                    widget.session.taskTag!,
                    style: SatoriTypography.caption.copyWith(
                      color: SatoriColors.incenseEmber,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: SatoriTheme.spacingXL),

              // 感受选择
              Text('此刻感受',
                  style: SatoriTypography.caption
                      .copyWith(color: Colors.grey.withValues(alpha: 0.6))),
              const SizedBox(height: SatoriTheme.spacingM),
              _buildMoodRow(),

              const SizedBox(height: SatoriTheme.spacingXL),

              // 备注输入
              Align(
                alignment: Alignment.centerLeft,
                child: Text('小结备注（可选）',
                    style: SatoriTypography.caption
                        .copyWith(color: Colors.grey.withValues(alpha: 0.6))),
              ),
              const SizedBox(height: SatoriTheme.spacingS),
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: SatoriTypography.caption.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText: '记录些什么...',
                  hintStyle: SatoriTypography.caption.copyWith(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: SatoriColors.incenseEmber.withValues(alpha: 0.5),
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const Spacer(),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SatoriColors.incenseEmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    final note = _noteController.text.trim();
                    widget.onSave(
                      note.isEmpty ? null : note,
                      _selectedMood,
                    );
                  },
                  child: Text('保存', style: SatoriTypography.subtitle
                      .copyWith(color: Colors.white)),
                ),
              ),
              const SizedBox(height: SatoriTheme.spacingS),
              TextButton(
                onPressed: widget.onSkip,
                child: Text('跳过',
                    style: SatoriTypography.caption
                        .copyWith(color: Colors.grey.withValues(alpha: 0.5))),
              ),
              const SizedBox(height: SatoriTheme.spacingS),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodRow() {
    const moods = [
      (mood: ReflectionMood.focused, label: '专注', icon: Icons.center_focus_strong),
      (mood: ReflectionMood.calm, label: '平静', icon: Icons.spa),
      (mood: ReflectionMood.productive, label: '高效', icon: Icons.bolt),
      (mood: ReflectionMood.distracted, label: '分心', icon: Icons.blur_on),
      (mood: ReflectionMood.tired, label: '疲惫', icon: Icons.bedtime),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: moods.map((m) {
        final isSelected = _selectedMood == m.mood;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedMood = isSelected ? null : m.mood;
            }),
            child: AnimatedContainer(
              duration: SatoriTheme.animFast,
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? SatoriColors.incenseEmber.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: SatoriColors.incenseEmber.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    m.icon,
                    size: 20,
                    color: isSelected
                        ? SatoriColors.incenseEmber
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? SatoriColors.incenseEmber
                          : Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
