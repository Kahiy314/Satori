import 'package:flutter/material.dart';

import '../../core/config/supabase_config.dart';
import '../../services/auth_controller.dart';
import '../../services/entitlement_controller.dart';
import '../../core/components/section_page_header.dart';
import '../../core/theme/theme.dart';
import 'auth_sheet.dart';

/// 设置页 — U3
///
/// 核心内容为账号信息、应用偏好设置和关于 Satori。
/// 品茗在此保留会员与权益入口（双重露出 U6）。
class SettingsView extends StatelessWidget {
  final VoidCallback? onTeaTap;
  final AuthController authController;
  final Future<void> Function()? onAuthenticated;
  final EntitlementController entitlementController;
  static const _appVersion = 'v1.0.0';
  
  static int _developerModeFailedAttempts = 0;
  static const int _maxDeveloperModeAttempts = 5;
  
  const SettingsView({
    super.key,
    this.onTeaTap,
    required this.authController,
    this.onAuthenticated,
    required this.entitlementController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : SatoriColors.inkSmoke;
    final subColor =
        isDark ? Colors.white54 : SatoriColors.inkSmoke.withValues(alpha: 0.6);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: isDark ? SatoriColors.inkStone : Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: SatoriTheme.spacingL,
          ),
          children: [
            const SectionPageHeader(
              title: '设置',
              padding: EdgeInsets.only(top: SatoriTheme.spacingM),
            ),
            const SizedBox(height: SatoriTheme.spacingL),

            // ── 账号信息 ──
            _SectionHeader(title: '账号', color: subColor),
            const SizedBox(height: SatoriTheme.spacingS),
            _SettingsCard(
              color: cardColor,
              children: [
                _SettingsRow(
                  icon: Icons.person_outline,
                  label: authController.accountLabel,
                  textColor: textColor,
                  subColor: subColor,
                  trailing: _AccountStatusBadge(
                    label: authController.statusLabel,
                    status: authController.status,
                  ),
                  onTap: () => _handleAuthTap(context),
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

            _SectionHeader(title: '开发', color: subColor),
            const SizedBox(height: SatoriTheme.spacingS),
            _SettingsCard(
              color: cardColor,
              children: [
                _SettingsRow(
                  icon: Icons.construction_outlined,
                  label: '开发者模式',
                  textColor: textColor,
                  subColor: subColor,
                  trailing: entitlementController.isReady
                      ? _DeveloperModeBadge(
                          enabled: entitlementController.isDeveloperModeEnabled,
                        )
                      : Text(
                          '加载中',
                          style: SatoriTypography.caption
                              .copyWith(color: subColor),
                        ),
                  onTap: () => _handleDeveloperModeTap(context),
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
                  trailing: Text(
                    _appVersion,
                    style: SatoriTypography.caption.copyWith(color: subColor),
                  ),
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

  Future<void> _handleAuthTap(BuildContext context) async {
    if (!authController.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupabaseConfig.missingConfigurationHint)),
      );
      return;
    }

    if (authController.isSignedIn) {
      await _showAccountActions(context);
      return;
    }

    authController.clearMessages();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuthSheet(authController: authController),
    );

    if (authController.isSignedIn) {
      await onAuthenticated?.call();
    }
  }

  Future<void> _showAccountActions(BuildContext context) async {
    final email = authController.currentEmail ?? '当前账号';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1E1E20) : Colors.white;
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(SatoriTheme.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: SatoriTheme.spacingL),
                  const Text('账号管理', style: SatoriTypography.title),
                  const SizedBox(height: SatoriTheme.spacingXS),
                  Text(
                    email,
                    style: SatoriTypography.caption.copyWith(
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: SatoriTheme.spacingL),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('发送重置密码邮件'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      final success = await authController.sendPasswordReset(
                        email,
                      );
                      if (!context.mounted) return;
                      final message = success
                          ? (authController.infoMessage ?? '重置密码邮件已发送')
                          : (authController.errorMessage ?? '发送失败');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout),
                    title: const Text('退出登录'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await authController.signOut();
                      if (!context.mounted) return;
                      final message = authController.infoMessage ??
                          authController.errorMessage ??
                          '退出登录完成';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

static int _developerModeFailedAttempts = 0;
static const int _maxDeveloperModeAttempts = 5;

Future<void> _handleDeveloperModeTap(BuildContext context) async {
final messenger = ScaffoldMessenger.maybeOf(context);

if (entitlementController.isDeveloperModeEnabled) {
final shouldDisable = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('关闭开发者模式'),
content: const Text('关闭后将恢复会员权限限制，正在播放的会员内容也会停止。'),
actions: [
TextButton(
onPressed: () => Navigator.of(dialogContext).pop(false),
child: const Text('取消'),
),
FilledButton(
onPressed: () => Navigator.of(dialogContext).pop(true),
child: const Text('关闭'),
),
],
),
);

```
if (shouldDisable == true) {
  await WidgetsBinding.instance.endOfFrame;

  await entitlementController.setDeveloperModeEnabled(false);

  if (!context.mounted) return;

  messenger?.showSnackBar(
    const SnackBar(
      content: Text('开发者模式已关闭'),
    ),
  );
}

return;
```

}

if (_developerModeFailedAttempts >= _maxDeveloperModeAttempts) {
messenger?.showSnackBar(
const SnackBar(
content: Text('密码错误次数过多，已禁止继续尝试'),
),
);
return;
}

final password = await showDialog<String>(
context: context,
builder: (_) => _DeveloperModeDialog(
failedAttempts: _developerModeFailedAttempts,
maxAttempts: _maxDeveloperModeAttempts,
),
);

if (password == null) {
return;
}

await WidgetsBinding.instance.endOfFrame;

final unlocked =
await entitlementController.unlockDeveloperMode(password);

if (!context.mounted) return;

if (unlocked) {
_developerModeFailedAttempts = 0;

```
messenger?.showSnackBar(
  const SnackBar(
    content: Text('开发者模式已开启'),
  ),
);
```

} else {
_developerModeFailedAttempts++;

```
final remaining =
    _maxDeveloperModeAttempts - _developerModeFailedAttempts;

if (_developerModeFailedAttempts >= _maxDeveloperModeAttempts) {
  messenger?.showSnackBar(
    const SnackBar(
      content: Text('密码错误次数过多，已禁止继续尝试'),
    ),
  );
} else {
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        '密码错误，还可尝试 $remaining 次',
      ),
    ),
  );
}
```

}
}

class _DeveloperModeDialog extends StatefulWidget {
const _DeveloperModeDialog({
required this.failedAttempts,
required this.maxAttempts,
});

final int failedAttempts;
final int maxAttempts;

@override
State<_DeveloperModeDialog> createState() =>
_DeveloperModeDialogState();
}

class _DeveloperModeDialogState extends State<_DeveloperModeDialog> {
final _passwordController = TextEditingController();

@override
void dispose() {
_passwordController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return AlertDialog(
title: const Text('开启开发者模式'),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
TextField(
controller: _passwordController,
autofocus: true,
obscureText: true,
decoration: InputDecoration(
labelText: '输入密码',
helperText:
'剩余尝试次数：${widget.maxAttempts - widget.failedAttempts}',
),
onSubmitted: (value) =>
Navigator.of(context).pop(value),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.of(context).pop(),
child: const Text('取消'),
),
FilledButton(
onPressed: () =>
Navigator.of(context).pop(_passwordController.text),
child: const Text('开启'),
),
],
);
}
}

class _DeveloperModeDialog extends StatefulWidget {
  const _DeveloperModeDialog();

  @override
  State<_DeveloperModeDialog> createState() => _DeveloperModeDialogState();
}

class _DeveloperModeDialogState extends State<_DeveloperModeDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('开启开发者模式'),
      content: TextField(
        controller: _passwordController,
        autofocus: true,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: '输入密码',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_passwordController.text),
          child: const Text('开启'),
        ),
      ],
    );
  }
}

class _DeveloperModeBadge extends StatelessWidget {
  final bool enabled;

  const _DeveloperModeBadge({required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? SatoriColors.incenseEmber : Colors.grey;
    final text = enabled ? '已开启' : '未开启';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
      ),
      child: Text(
        text,
        style: SatoriTypography.caption.copyWith(color: color),
      ),
    );
  }
}

class _AccountStatusBadge extends StatelessWidget {
  final String label;
  final AuthViewState status;

  const _AccountStatusBadge({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AuthViewState.unavailable => Colors.grey,
      AuthViewState.signedOut => Colors.grey,
      AuthViewState.signingIn => SatoriColors.teaAmber,
      AuthViewState.signedIn => SatoriColors.verdigris,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
      ),
      child: Text(
        label,
        style: SatoriTypography.caption.copyWith(color: color),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.symmetric(horizontal: SatoriTheme.spacingM),
      child: Divider(height: 1, color: color.withValues(alpha: 0.15)),
    );
  }
}
