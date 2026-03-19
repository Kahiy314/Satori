import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/components/drawer_entry_button.dart';
import '../../services/haptic_service.dart';
import 'rain_view_model.dart';
import 'components/audio_wave_view.dart';

/// 听雨主页面
class RainView extends StatefulWidget {
  final VoidCallback? onDrawerTap;
  const RainView({super.key, this.onDrawerTap});

  @override
  State<RainView> createState() => _RainViewState();
}

class _RainViewState extends State<RainView>
    with SingleTickerProviderStateMixin {
  final _vm = RainViewModel();
  late final AnimationController _waveController;

  // 图标映射
  static const _iconMap = <String, IconData>{
    'cloud.drizzle': Icons.grain,
    'cloud.heavyrain': Icons.thunderstorm,
    'cloud.bolt': Icons.flash_on,
    'water.waves': Icons.water,
    'wind': Icons.air,
    'moon.stars': Icons.nightlight_round,
  };

  @override
  void initState() {
    super.initState();
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
                '建议佩戴耳机  ·  可叠加多种声音',
                style: SatoriTypography.caption.copyWith(color: Colors.grey),
              ),
            ),
          const SizedBox(height: SatoriTheme.spacingL),
          Expanded(child: _buildSoundGrid()),
          if (_vm.isAnyPlaying) ...[
            AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
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
                    style: SatoriTypography.subtitle.copyWith(color: Colors.grey)),
              ),
            ),
          ],
          const SizedBox(height: SatoriTheme.spacingL),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SatoriTheme.spacingS, SatoriTheme.spacingM, SatoriTheme.spacingL, 0,
      ),
      child: Row(
        children: [
          if (widget.onDrawerTap != null)
            DrawerEntryButton(onTap: widget.onDrawerTap!),
          Text('听雨', style: SatoriTypography.largeTitle),
          const Spacer(),
        ],
      ),
    );
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
          childAspectRatio: 0.8,
        ),
        itemCount: _vm.sources.length,
        itemBuilder: (_, i) => _SoundSourceCard(
          source: _vm.sources[i],
          icon: _iconMap[_vm.sources[i].icon] ?? Icons.music_note,
          onToggle: () {
            HapticService.instance.lightTap();
            _vm.toggleSource(_vm.sources[i].id);
          },
          onVolumeChange: (v) => _vm.setVolume(_vm.sources[i].id, v),
        ),
      ),
    );
  }
}

class _SoundSourceCard extends StatelessWidget {
  final SoundSource source;
  final IconData icon;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChange;

  const _SoundSourceCard({
    required this.source,
    required this.icon,
    required this.onToggle,
    required this.onVolumeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: SatoriTheme.spacingM),
            decoration: BoxDecoration(
              color: source.isPlaying
                  ? SatoriColors.rainCyan.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
              border: Border.all(
                color: source.isPlaying
                    ? SatoriColors.rainCyan.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 24,
                    color:
                        source.isPlaying ? SatoriColors.rainCyan : Colors.grey),
                const SizedBox(height: 6),
                Text(
                  source.name,
                  style: SatoriTypography.caption.copyWith(
                    color: source.isPlaying ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (source.isPlaying)
          SizedBox(
            height: 24,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                activeTrackColor: SatoriColors.rainCyan,
                inactiveTrackColor: SatoriColors.rainCyan.withValues(alpha: 0.2),
                thumbColor: SatoriColors.rainCyan,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: source.volume,
                onChanged: onVolumeChange,
              ),
            ),
          ),
      ],
    );
  }
}
