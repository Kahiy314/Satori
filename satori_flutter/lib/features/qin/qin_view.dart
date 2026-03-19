import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/components/drawer_entry_button.dart';
import '../../services/haptic_service.dart';
import 'qin_view_model.dart';
import 'components/music_player_view.dart';

/// 抚琴主页面
class QinView extends StatefulWidget {
  final VoidCallback? onDrawerTap;
  const QinView({super.key, this.onDrawerTap});

  @override
  State<QinView> createState() => _QinViewState();
}

class _QinViewState extends State<QinView> {
  final _vm = QinViewModel();

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
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.only(top: SatoriTheme.spacingXS),
            child: Text('建议佩戴耳机',
                style: SatoriTypography.caption.copyWith(color: Colors.grey)),
          ),
          const SizedBox(height: SatoriTheme.spacingL),
          Expanded(child: _buildTrackList()),
          if (_vm.currentTrack != null)
            Padding(
              padding: const EdgeInsets.only(bottom: SatoriTheme.spacingS),
              child: MusicPlayerView(vm: _vm),
            ),
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
          Text('抚琴', style: SatoriTypography.largeTitle),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTrackList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingL),
      itemCount: _vm.tracks.length,
      itemBuilder: (_, i) => _buildTrackRow(_vm.tracks[i]),
    );
  }

  Widget _buildTrackRow(Track track) {
    final isCurrent = _vm.currentTrack?.id == track.id;

    return GestureDetector(
      onTap: () {
        if (track.isLocked) {
          HapticService.instance.warningTap();
        } else {
          HapticService.instance.lightTap();
          _vm.play(track);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: SatoriTheme.spacingS,
          horizontal: SatoriTheme.spacingM,
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? SatoriColors.stringGold.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
        ),
        child: Row(
          children: [
            // 播放指示
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? SatoriColors.stringGold.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.05),
              ),
              child: Center(
                child: track.isLocked
                    ? const Icon(Icons.lock, size: 14, color: Colors.grey)
                    : isCurrent && _vm.isPlaying
                        ? const _EqualizerBars()
                        : Icon(Icons.music_note,
                            size: 14,
                            color: isCurrent
                                ? SatoriColors.stringGold
                                : Colors.grey),
              ),
            ),
            const SizedBox(width: SatoriTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                      style: SatoriTypography.body.copyWith(
                          color: track.isLocked ? Colors.grey : null)),
                  Text(track.artist,
                      style:
                          SatoriTypography.caption.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            Text(
              _vm.formatTime(track.duration),
              style: SatoriTypography.caption
                  .copyWith(color: Colors.grey.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 均衡器动画条
class _EqualizerBars extends StatefulWidget {
  const _EqualizerBars();

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final h = 4 + _controller.value * (_rng.nextDouble() * 12);
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: SatoriColors.stringGold,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}
