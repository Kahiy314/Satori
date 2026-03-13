import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/components/glass_background.dart';
import '../qin_view_model.dart';

/// 底部音乐播放器条
class MusicPlayerView extends StatelessWidget {
  final QinViewModel vm;

  const MusicPlayerView({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingM),
      child: Stack(
        children: [
          const Positioned.fill(
            child: GlassBackground(cornerRadius: SatoriTheme.cornerLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SatoriTheme.spacingL,
              vertical: SatoriTheme.spacingM,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 进度条
                _ProgressSlider(vm: vm),
                const SizedBox(height: SatoriTheme.spacingS),
                // 时间标签
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(vm.formattedCurrentTime,
                        style: SatoriTypography.caption
                            .copyWith(color: Colors.grey.withValues(alpha: 0.6))),
                    Text(vm.formattedDuration,
                        style: SatoriTypography.caption
                            .copyWith(color: Colors.grey.withValues(alpha: 0.6))),
                  ],
                ),
                const SizedBox(height: SatoriTheme.spacingS),
                // 曲名 + 控制
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vm.currentTrack?.title ?? '',
                              style: SatoriTypography.subtitle),
                          Text(vm.currentTrack?.artist ?? '',
                              style: SatoriTypography.caption
                                  .copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                    // 播放/暂停
                    GestureDetector(
                      onTap: vm.togglePlayPause,
                      child: Icon(
                        vm.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 36,
                        color: SatoriColors.stringGold,
                      ),
                    ),
                    const SizedBox(width: SatoriTheme.spacingS),
                    // 下一曲
                    GestureDetector(
                      onTap: vm.playNext,
                      child: const Icon(
                        Icons.skip_next,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSlider extends StatelessWidget {
  final QinViewModel vm;
  const _ProgressSlider({required this.vm});

  @override
  Widget build(BuildContext context) {
    final maxVal = max(vm.duration, 1.0);
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
        activeTrackColor: SatoriColors.stringGold,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.15),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(
        value: vm.currentTime.clamp(0, maxVal),
        min: 0,
        max: maxVal,
        onChanged: (v) => vm.seek(v),
      ),
    );
  }
}
