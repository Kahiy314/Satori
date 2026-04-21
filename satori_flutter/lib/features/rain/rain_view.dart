import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/components/member_prompt.dart';
import '../../core/theme/theme.dart';
import '../../services/entitlement_controller.dart';
import '../../core/components/section_page_header.dart';
import '../../services/haptic_service.dart';
import '../tea/tea_view.dart';
import 'rain_view_model.dart';
import 'components/audio_wave_view.dart';

/// 听雨主页面
class RainView extends StatefulWidget {
  final bool showPlayer;
  final EntitlementController? entitlementController;

  const RainView({
    super.key,
    this.showPlayer = true,
    this.entitlementController,
  });

  @override
  State<RainView> createState() => _RainViewState();
}

class _RainViewState extends State<RainView>
    with SingleTickerProviderStateMixin {
  late final RainViewModel _vm;
  late final AnimationController _waveController;

  // 图标映射
  static const _iconMap = <String, IconData>{
    'cloud.drizzle': Icons.grain,
    'stream': Icons.stream,
    'cloud.bolt': Icons.thunderstorm,
    'water.waves.2': Icons.waves,
    'wind': Icons.air,
    'flame': Icons.local_fire_department,
    'bubble': Icons.bubble_chart,
  };

  @override
  void initState() {
    super.initState();
    _vm = RainViewModel(entitlementController: widget.entitlementController);
    _vm.addListener(_onChanged);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          if (!_vm.isAnyPlaying)
            Padding(
              padding: const EdgeInsets.only(top: SatoriTheme.spacingS),
              child: Text(
                '建议佩戴耳机  ·  单次只聆听一种声音',
                style: SatoriTypography.caption.copyWith(color: Colors.grey),
              ),
            ),
          const SizedBox(height: SatoriTheme.spacingL),
          Expanded(child: _buildSoundGrid()),
          if (widget.showPlayer && _vm.isAnyPlaying) ...[
            AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: SatoriTheme.spacingL),
                  child: AudioWaveView(phase: _waveController.value * pi * 2),
                ),
              ),
            ),
            const SizedBox(height: SatoriTheme.spacingM),
            GestureDetector(
              onTap: () {
                HapticService.instance.lightTap();
                _vm.stopAll();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SatoriTheme.spacingL,
                  vertical: SatoriTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
                ),
                child: Text('止息',
                    style:
                        SatoriTypography.subtitle.copyWith(color: Colors.grey)),
              ),
            ),
          ],
          const SizedBox(height: SatoriTheme.spacingL),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const SectionPageHeader(title: '听雨');
  }

  Widget _buildSoundGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: SatoriTheme.spacingM,
          crossAxisSpacing: SatoriTheme.spacingM,
          childAspectRatio: 0.78,
        ),
        itemCount: _vm.sources.length,
        itemBuilder: (_, i) => _SoundSourceCard(
          source: _vm.sources[i],
          isLocked: _vm.isSourceLocked(_vm.sources[i]),
          icon: _iconMap[_vm.sources[i].icon] ?? Icons.music_note,
          onToggle: () {
            _handleSourceTap(_vm.sources[i]);
          },
          onVolumeChange: (v) => _vm.setVolume(_vm.sources[i].id, v),
        ),
      ),
    );
  }

  void _handleSourceTap(SoundSource source) {
    if (_vm.isSourceLocked(source)) {
      HapticService.instance.warningTap();
      unawaited(
        MemberPrompt.showHalfBlock(
          context,
          title: '${source.name} 属于${source.requiredTier.label}权益',
          description:
              '当前白噪音需要${source.requiredTier.label}或更高会员等级。你也可以在设置中开启开发者模式，便于调试完整资源。',
          onGoTea: _openTea,
        ),
      );
      return;
    }

    HapticService.instance.lightTap();
    unawaited(_vm.toggleSource(source.id));
  }

  void _openTea() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeaView(
          entitlementController: widget.entitlementController,
        ),
      ),
    );
  }
}

class _SoundSourceCard extends StatelessWidget {
  final SoundSource source;
  final bool isLocked;
  final IconData icon;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChange;

  const _SoundSourceCard({
    required this.source,
    required this.isLocked,
    required this.icon,
    required this.onToggle,
    required this.onVolumeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: SatoriTheme.spacingM,
            ),
            decoration: BoxDecoration(
              color: source.isPlaying
                  ? SatoriColors.rainCyan.withValues(alpha: 0.1)
                  : isLocked
                      ? SatoriColors.teaAmber.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
              border: Border.all(
                color: source.isPlaying
                    ? SatoriColors.rainCyan.withValues(alpha: 0.3)
                    : isLocked
                        ? SatoriColors.teaAmber.withValues(alpha: 0.18)
                        : Colors.transparent,
              ),
              boxShadow: source.isPlaying
                  ? [
                      BoxShadow(
                        color: SatoriColors.rainCyan.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLocked ? Icons.lock_outline : icon,
                  size: 24,
                  color: source.isPlaying
                      ? SatoriColors.rainCyan
                      : isLocked
                          ? SatoriColors.teaAmber
                          : Colors.grey,
                ),
                const SizedBox(height: 6),
                Text(
                  source.name,
                  style: SatoriTypography.caption.copyWith(
                    color: source.isPlaying
                        ? null
                        : isLocked
                            ? SatoriColors.teaAmber
                            : Colors.grey,
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 4),
                  Text(
                    source.requiredTier.label,
                    style: SatoriTypography.caption.copyWith(
                      fontSize: 10,
                      color: SatoriColors.teaAmber,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (source.isPlaying) const SizedBox(height: SatoriTheme.spacingXS),
        if (source.isPlaying)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              height: 24,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  activeTrackColor: SatoriColors.rainCyan,
                  inactiveTrackColor:
                      SatoriColors.rainCyan.withValues(alpha: 0.2),
                  thumbColor: SatoriColors.rainCyan,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: source.volume,
                  onChanged: onVolumeChange,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
