import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/components/member_prompt.dart';
import '../../core/theme/theme.dart';
import '../../services/entitlement_controller.dart';
import '../../core/components/section_page_header.dart';
import '../../services/haptic_service.dart';
import '../tea/tea_view.dart';
import 'qin_view_model.dart';
import 'components/music_player_view.dart';

/// 抚琴主页面
class QinView extends StatefulWidget {
  final QinViewModel? viewModel;
  final EntitlementController? entitlementController;

  const QinView({super.key, this.viewModel, this.entitlementController});

  @override
  State<QinView> createState() => _QinViewState();
}

class _QinViewState extends State<QinView> {
  late final QinViewModel _vm;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _vm = widget.viewModel ??
        QinViewModel(entitlementController: widget.entitlementController);
    _vm.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    if (_ownsViewModel) {
      _vm.dispose();
    }
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
    return const SectionPageHeader(title: '抚琴');
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
    final isLocked = _vm.isTrackLocked(track);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          HapticService.instance.warningTap();
          unawaited(
            MemberPrompt.showHalfBlock(
              context,
              title: '${track.title} 属于${track.requiredTier.label}权益',
              description:
                  '当前曲目需要${track.requiredTier.label}或更高会员等级。若你正在调试资源，也可以在设置中开启开发者模式。',
              onGoTea: _openTea,
            ),
          );
        } else {
          HapticService.instance.lightTap();
          unawaited(_vm.play(track));
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
                child: isLocked
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
                      style: SatoriTypography.body
                          .copyWith(color: isLocked ? Colors.grey : null)),
                  Text(track.artist,
                      style: SatoriTypography.caption
                          .copyWith(color: Colors.grey)),
                ],
              ),
            ),
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(right: SatoriTheme.spacingS),
                child: Text(
                  track.requiredTier.label,
                  style: SatoriTypography.caption.copyWith(
                    color: SatoriColors.teaAmber,
                  ),
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
