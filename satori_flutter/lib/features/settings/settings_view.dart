import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// 设置页 — U3
///
/// 核心内容为账号信息、应用偏好设置和关于 Satori。
/// 品茗在此保留会员与权益入口（双重露出 U6）。
class SettingsView extends StatelessWidget {
  final VoidCallback? onTeaTap;

  const SettingsView({super.key, this.onTeaTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor = isDark
        ? Colors.white54
        : SatoriColors.inkSmoke.withValues(alpha: 0.6);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: isDark ? SatoriColors.inkStone : SatoriColors.ricePaper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: SatoriTheme.spacingL,
          ),
          children: [
            const SizedBox(height: SatoriTheme.spacingXL),
            Text(
              '设置',
              style: SatoriTypography.largeTitle.copyWith(color: textColor),
            ),
            const SizedBox(height: SatoriTheme.spacingXL),

            // ── 账号信息 ──
            _SectionHeader(title: '账号', color: subColor),
            const SizedBox(height: SatoriTheme.spacingS),
            _SettingsCard(
              color: cardColor,
              children: [
                _SettingsRow(
                  icon: Icons.person_outline,
                  label: '登录 / 注册',
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: SatoriTheme.spacingL),

            // ── 会员与权益（品茗双重露出 U6）──
            _SectionHeader(title: '会员', color: subColor),
            const SizedBox(height: SatoriTheme.spacingS),
            _SettingsCard(
              color: cardColor,
              children: [
                _SettingsRow(
                  icon: Icons.local_cafe_outlined,
                  label: '品茗 · 会员与权益',
                  textColor: textColor,
                  subColor: subColor,
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: subColor,
                  ),
                  onTap: onTeaTap,
                ),
              ],
            ),
            const SizedBox(height: SatoriTheme.spacingL),

            // ── 应用偏好 ──
            _SectionHeader(title: '偏好', color: subColor),
            const SizedBox(height: SatoriTheme.spacingS),
            _SettingsCard(
              color: cardColor,
              children: [
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  label: '外观',
                  textColor: textColor,
                  subColor: subColor,
                  trailing: Text('跟随系统',
                      style:
                          SatoriTypography.caption.copyWith(color: subColor)),
                  onTap: () {},
                ),
                _Divider(color: subColor),
                _SettingsRow(
                  icon: Icons.timer_outlined,
                  label: '最短有效专注',
                  textColor: textColor,
                  subColor: subColor,
                  trailing: Text('2 分钟',
                      style:
                          SatoriTypography.caption.copyWith(color: subColor)),
                  onTap: () {},
                ),
                _Divider(color: subColor),
                _SettingsRow(
                  icon: Icons.notifications_none_outlined,
                  label: '短时退出提示',
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: SatoriTheme.spacingL),

            // ── 关于 ──
            _SectionHeader(title: '关于', color: subColor),
            const SizedBox(height: SatoriTheme.spacingS),
            _SettingsCard(
              color: cardColor,
              children: [
                _SettingsRow(
                  icon: Icons.info_outline,
                  label: '关于 Satori',
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () {},
                ),
                _Divider(color: subColor),
                _SettingsRow(
                  icon: Icons.description_outlined,
                  label: '隐私政策',
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: SatoriTheme.spacingXXL),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: SatoriTypography.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Color color;
  final List<Widget> children;
  const _SettingsCard({required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SatoriTheme.cornerMedium),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color subColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.subColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SatoriTheme.spacingM,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: subColor),
            const SizedBox(width: SatoriTheme.spacingM),
            Expanded(
              child: Text(
                label,
                style: SatoriTypography.body.copyWith(color: textColor),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingM),
      child: Divider(height: 1, color: color.withValues(alpha: 0.15)),
    );
  }
}
