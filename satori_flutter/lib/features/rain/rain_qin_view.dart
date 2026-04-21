import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../services/entitlement_controller.dart';
import '../../services/haptic_service.dart';
import '../qin/qin_view.dart';
import 'rain_view.dart';

enum _RainQinMode { rain, qin }

/// 听雨 / 抚琴整合页
///
/// - 底部 tab 入口统一归到“听雨”
/// - 默认进入听雨
/// - 右上角通过模式切换栏在听雨和抚琴之间切换
class RainQinView extends StatefulWidget {
  final EntitlementController? entitlementController;

  const RainQinView({super.key, this.entitlementController});

  @override
  State<RainQinView> createState() => _RainQinViewState();
}

class _RainQinViewState extends State<RainQinView> {
  _RainQinMode _mode = _RainQinMode.rain;

  void _switchMode(_RainQinMode mode) {
    if (_mode == mode) return;
    HapticService.instance.lightTap();
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _mode == _RainQinMode.rain ? 0 : 1,
          children: [
            RainView(
              showPlayer: false,
              entitlementController: widget.entitlementController,
            ),
            QinView(entitlementController: widget.entitlementController),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + SatoriTheme.spacingM,
          right: SatoriTheme.spacingM,
          child: _ModeSwitch(
            mode: _mode,
            onModeChanged: _switchMode,
          ),
        ),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final _RainQinMode mode;
  final ValueChanged<_RainQinMode> onModeChanged;

  const _ModeSwitch({
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            text: '听雨',
            isSelected: mode == _RainQinMode.rain,
            accentColor: SatoriColors.rainCyan,
            onTap: () => onModeChanged(_RainQinMode.rain),
          ),
          _ModeButton(
            text: '抚琴',
            isSelected: mode == _RainQinMode.qin,
            accentColor: SatoriColors.stringGold,
            onTap: () => onModeChanged(_RainQinMode.qin),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.text,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SatoriTheme.animNormal,
        width: 56,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.85)
              : Colors.transparent,
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
}
