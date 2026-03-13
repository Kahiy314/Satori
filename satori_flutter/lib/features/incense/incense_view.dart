import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../services/haptic_service.dart';
import 'incense_view_model.dart';
import 'components/smoke_particle_view.dart';
import 'components/incense_ember_view.dart';
import 'components/incense_stick_view.dart';
import 'components/tai_chi_glass_view.dart';

/// 焚香主页面
class IncenseView extends StatefulWidget {
  const IncenseView({super.key});

  @override
  State<IncenseView> createState() => _IncenseViewState();
}

class _IncenseViewState extends State<IncenseView> {
  final _vm = IncenseViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 上下滑动切换模式
      onVerticalDragEnd: _onVerticalSwipe,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: SatoriTheme.animNormal,
                transitionBuilder: (child, anim) {
                  final offset = _vm.timerMode == TimerMode.countdown
                      ? const Offset(0, -0.1)
                      : const Offset(0, 0.1);
                  return SlideTransition(
                    position: Tween(begin: offset, end: Offset.zero).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: _vm.timerMode == TimerMode.countdown
                    ? _CountdownScene(key: const ValueKey('countdown'), vm: _vm)
                    : _CountUpScene(key: const ValueKey('countup'), vm: _vm),
              ),
            ),
            _buildTimerDisplay(),
            _buildControls(),
            const SizedBox(height: 100),
          ],
        ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SatoriTheme.spacingL, SatoriTheme.spacingM, SatoriTheme.spacingL, 0,
      ),
      child: Row(
        children: [
          Text('焚香', style: SatoriTypography.largeTitle),
          const Spacer(),
          _buildModeTab(),
        ],
      ),
    );
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

  // ── Timer Display ──

  Widget _buildTimerDisplay() {
    return Padding(
      padding: const EdgeInsets.only(bottom: SatoriTheme.spacingM),
      child: Text(
        _vm.formattedTime,
        style: SatoriTypography.timer.copyWith(
          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  // ── Controls ──

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
      child: Column(
        children: [
          // 预设选择器
          if (_vm.state == TimerState.idle && _vm.timerMode == TimerMode.countdown)
            _buildPresetPicker(),

          const SizedBox(height: SatoriTheme.spacingM),

          // 按钮
          AnimatedSwitcher(
            duration: SatoriTheme.animNormal,
            child: Row(
              key: ValueKey(_vm.state),
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildActionButtons(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    switch (_vm.state) {
      case TimerState.idle:
        final label = _vm.timerMode == TimerMode.countdown ? '点燃' : '开始';
        final icon = _vm.timerMode == TimerMode.countdown
            ? Icons.local_fire_department
            : Icons.play_arrow;
        return [
          _primaryButton(label, icon, () {
            HapticService.instance.mediumTap();
            _vm.start();
          }),
        ];
      case TimerState.running:
        return [
          _secondaryButton('暂停', Icons.pause, () {
            HapticService.instance.lightTap();
            _vm.pause();
          }),
        ];
      case TimerState.paused:
        return [
          _primaryButton('继续', Icons.play_arrow, () {
            HapticService.instance.lightTap();
            _vm.start();
          }),
          const SizedBox(width: SatoriTheme.spacingL),
          _secondaryButton('结束', Icons.close, () {
            HapticService.instance.lightTap();
            _vm.reset();
          }),
        ];
      case TimerState.completed:
        return [
          _primaryButton('再燃一炷', Icons.local_fire_department, () {
            HapticService.instance.mediumTap();
            _vm.reset();
          }),
        ];
    }
  }

  Widget _primaryButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SatoriTheme.spacingL,
          vertical: SatoriTheme.spacingM,
        ),
        decoration: BoxDecoration(
          color: SatoriColors.incenseEmber,
          borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
          boxShadow: const [SatoriTheme.shadowSubtle],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(text, style: SatoriTypography.subtitle.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SatoriTheme.spacingL,
          vertical: SatoriTheme.spacingM,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(text, style: SatoriTypography.subtitle),
          ],
        ),
      ),
    );
  }

  // ── Preset Picker ──

  Widget _buildPresetPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...IncenseViewModel.presets.map((p) {
            final isSelected = _vm.totalDuration == p.minutes * 60.0;
            return Padding(
              padding: const EdgeInsets.only(right: SatoriTheme.spacingS),
              child: GestureDetector(
                onTap: () {
                  HapticService.instance.lightTap();
                  _vm.selectPreset(p.minutes);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SatoriColors.incenseEmber.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
                  ),
                  child: Text(
                    p.label,
                    style: SatoriTypography.caption.copyWith(
                      color: isSelected ? SatoriColors.incenseEmber : Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }),
          // 自定义入口
          GestureDetector(
            onTap: () {
              HapticService.instance.lightTap();
              _showCustomDurationSheet();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
              ),
              child: const Icon(Icons.tune, size: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomDurationSheet() {
    _vm.customMinutes = (_vm.totalDuration / 60).toInt();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CustomDurationSheet(vm: _vm),
    );
  }
}

// ── 倒计时场景 ──

class _CountdownScene extends StatelessWidget {
  final IncenseViewModel vm;
  const _CountdownScene({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneHeight = constraints.maxHeight;
        final stickBaseHeight = sceneHeight * 0.5;
        final burnerCenterY = sceneHeight * 0.28;
        final visibleStickHeight = stickBaseHeight * (1 - vm.burnProgress);
        final stickBottomY = burnerCenterY - 18;
        final stickTopY = stickBottomY - visibleStickHeight;
        final stickCenterY = (stickBottomY + stickTopY) / 2;

        return Stack(
          alignment: Alignment.center,
          children: [
            // 烟雾粒子
            Positioned(
              top: stickTopY - sceneHeight * 0.15,
              child: SizedBox(
                width: 200,
                height: sceneHeight * 0.5,
                child: SmokeParticleView(
                  burnProgress: vm.burnProgress,
                  opacity: vm.state == TimerState.running ? 1 : 0.3,
                ),
              ),
            ),

            // 香身
            if (visibleStickHeight > 1)
              Positioned(
                top: (sceneHeight / 2) + stickCenterY - visibleStickHeight / 2,
                child: SizedBox(
                  width: 6,
                  height: visibleStickHeight,
                  child: IncenseStickView(burnProgress: vm.burnProgress),
                ),
              ),

            // 余烬
            if (vm.state == TimerState.running && visibleStickHeight > 1)
              Positioned(
                top: (sceneHeight / 2) + stickTopY - 5,
                child: const SizedBox(
                  width: 14,
                  height: 10,
                  child: IncenseEmberView(),
                ),
              ),

            // 香炉
            Positioned(
              top: (sceneHeight / 2) + burnerCenterY - 25,
              child: const SizedBox(
                width: 80,
                height: 50,
                child: IncenseBurnerView(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── 正计时场景 ──

class _CountUpScene extends StatelessWidget {
  final IncenseViewModel vm;
  const _CountUpScene({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneHeight = constraints.maxHeight;
        return Stack(
          alignment: Alignment.center,
          children: [
            // 烟雾
            Positioned(
              top: sceneHeight * 0.1,
              child: SizedBox(
                width: 200,
                height: sceneHeight * 0.6,
                child: SmokeParticleView(
                  burnProgress: 0,
                  opacity: vm.state == TimerState.running ? 1 : 0.3,
                ),
              ),
            ),
            // 太极
            Positioned(
              top: sceneHeight * 0.5 - sceneHeight * 0.12 - 50,
              child: SizedBox(
                width: 100,
                height: 100,
                child: TaiChiGlassView(
                  fillProgress:
                      vm.state == TimerState.running ? vm.burnProgress : 0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── 自定义时长弹窗 ──

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
    return 40 + ratio * 120;
  }

  double get _previewWidth {
    final ratio = (_minutes - IncenseViewModel.minMinutes) /
        (IncenseViewModel.maxMinutes - IncenseViewModel.minMinutes);
    return 3 + ratio * 5;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: SatoriTheme.spacingM),
          Text('自定义专注时长', style: SatoriTypography.title),
          const SizedBox(height: SatoriTheme.spacingM),
          Text(
            '$_minutes 分钟',
            style: SatoriTypography.timer.copyWith(color: SatoriColors.incenseEmber),
          ),
          const SizedBox(height: SatoriTheme.spacingL),
          // 香身预览
          SizedBox(
            height: 180,
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
                    width: 50,
                    height: 30,
                    child: CustomPaint(painter: _MiniburnerPainter()),
                  ),
                ),
              ],
            ),
          ),
          // 滑块
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
          const SizedBox(height: SatoriTheme.spacingM),
          // 确认
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SatoriColors.incenseEmber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                widget.vm.customMinutes = _minutes;
                widget.vm.applyCustomDuration();
                Navigator.pop(context);
              },
              child: Text('确定', style: SatoriTypography.subtitle),
            ),
          ),
        ],
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
