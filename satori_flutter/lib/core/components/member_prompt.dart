import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// 会员提示等级 — U7
enum MemberPromptLevel {
  /// 轻提示：功能附近弱提醒（小图标/文字）
  light,

  /// 半拦截：点击会员功能后的权益说明底部弹窗
  halfBlock,

  /// 强拦截：确实无法继续的会员能力，全屏遮挡
  fullBlock,
}

/// 会员提示组件工厂 — U7
///
/// 三级策略：轻提示 / 半拦截 / 强拦截。
/// 所有提示都提供跳转到品茗界面的快捷方式。
class MemberPrompt {
  MemberPrompt._();

  /// 轻提示：在 widget 旁显示一个小标签
  static Widget lightBadge({
    required String text,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: SatoriColors.teaAmber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_cafe, size: 12, color: SatoriColors.teaAmber),
            const SizedBox(width: 4),
            Text(
              text,
              style: SatoriTypography.caption.copyWith(
                color: SatoriColors.teaAmber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 半拦截：底部弹窗说明权益
  static Future<bool?> showHalfBlock(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onGoTea,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HalfBlockSheet(
        title: title,
        description: description,
        onGoTea: onGoTea,
      ),
    );
  }

  /// 强拦截：全屏遮挡 dialog
  static Future<void> showFullBlock(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onGoTea,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FullBlockDialog(
        title: title,
        description: description,
        onGoTea: onGoTea,
      ),
    );
  }
}

class _HalfBlockSheet extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onGoTea;

  const _HalfBlockSheet({
    required this.title,
    required this.description,
    required this.onGoTea,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2A26) : SatoriColors.ricePaper;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;

    return Container(
      padding: const EdgeInsets.all(SatoriTheme.spacingL),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SatoriTheme.cornerLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: SatoriTheme.spacingL),
          Icon(Icons.local_cafe, size: 32, color: SatoriColors.teaAmber),
          const SizedBox(height: SatoriTheme.spacingM),
          Text(title,
              style: SatoriTypography.title.copyWith(color: textColor)),
          const SizedBox(height: SatoriTheme.spacingS),
          Text(
            description,
            style: SatoriTypography.body.copyWith(
                color: textColor.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SatoriTheme.spacingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SatoriColors.teaAmber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(SatoriTheme.cornerMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context, true);
                onGoTea();
              },
              child: Text('前往品茗', style: SatoriTypography.subtitle),
            ),
          ),
          const SizedBox(height: SatoriTheme.spacingS),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('暂不需要',
                style: SatoriTypography.body
                    .copyWith(color: textColor.withValues(alpha: 0.5))),
          ),
          const SizedBox(height: SatoriTheme.spacingM),
        ],
      ),
    );
  }
}

class _FullBlockDialog extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onGoTea;

  const _FullBlockDialog({
    required this.title,
    required this.description,
    required this.onGoTea,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2A26) : SatoriColors.ricePaper;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(SatoriTheme.spacingXL),
        padding: const EdgeInsets.all(SatoriTheme.spacingL),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(SatoriTheme.cornerLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_cafe, size: 40, color: SatoriColors.teaAmber),
            const SizedBox(height: SatoriTheme.spacingM),
            Text(title,
                style: SatoriTypography.title.copyWith(color: textColor)),
            const SizedBox(height: SatoriTheme.spacingS),
            Text(
              description,
              style: SatoriTypography.body.copyWith(
                  color: textColor.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SatoriTheme.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SatoriColors.teaAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(SatoriTheme.cornerMedium),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onGoTea();
                },
                child: Text('前往品茗', style: SatoriTypography.subtitle),
              ),
            ),
            const SizedBox(height: SatoriTheme.spacingS),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('返回',
                  style: SatoriTypography.body
                      .copyWith(color: textColor.withValues(alpha: 0.5))),
            ),
          ],
        ),
      ),
    );
  }
}
