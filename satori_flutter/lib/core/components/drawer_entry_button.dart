import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// 左上角宣纸抽屉入口按钮。
///
/// 极简小图标，不破坏焚香主界面的安静感。
/// 深浅主题自适应。
class DrawerEntryButton extends StatelessWidget {
  final VoidCallback onTap;

  const DrawerEntryButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : SatoriColors.inkSmoke.withValues(alpha: 0.35);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(SatoriTheme.spacingS),
        child: Icon(
          Icons.menu,
          size: 20,
          color: color,
        ),
      ),
    );
  }
}
