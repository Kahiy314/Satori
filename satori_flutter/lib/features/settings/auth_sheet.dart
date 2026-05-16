import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../services/auth_controller.dart';

enum _AuthSheetMode { signIn, signUp, resetPassword }

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthSheetMode _mode = _AuthSheetMode.signIn;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E20) : Colors.white;

    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
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
                  Text(_title, style: SatoriTypography.title),
                  const SizedBox(height: SatoriTheme.spacingXS),
                  Text(
                    _subtitle,
                    style: SatoriTypography.caption.copyWith(
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: SatoriTheme.spacingL),
                  _buildModeTabs(),
                  const SizedBox(height: SatoriTheme.spacingL),
                  _buildEmailField(),
                  if (_mode != _AuthSheetMode.resetPassword) ...[
                    const SizedBox(height: SatoriTheme.spacingM),
                    _buildPasswordField(),
                  ],
                  if (widget.authController.errorMessage != null) ...[
                    const SizedBox(height: SatoriTheme.spacingM),
                    Text(
                      widget.authController.errorMessage!,
                      style: SatoriTypography.caption.copyWith(
                        color: SatoriColors.incenseEmber,
                      ),
                    ),
                  ],
                  if (widget.authController.infoMessage != null) ...[
                    const SizedBox(height: SatoriTheme.spacingM),
                    Text(
                      widget.authController.infoMessage!,
                      style: SatoriTypography.caption.copyWith(
                        color: SatoriColors.verdigris,
                      ),
                    ),
                  ],
                  const SizedBox(height: SatoriTheme.spacingL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.authController.isBusy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SatoriColors.incenseEmber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: widget.authController.isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _primaryButtonText,
                              style: SatoriTypography.subtitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: SatoriTheme.spacingS),
                  if (_mode != _AuthSheetMode.resetPassword)
                    TextButton(
                      onPressed: () {
                        widget.authController.clearMessages();
                        setState(() => _mode = _AuthSheetMode.resetPassword);
                      },
                      child: Text(
                        '忘记密码',
                        style: SatoriTypography.caption.copyWith(
                          color: Colors.grey.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String get _title {
    switch (_mode) {
      case _AuthSheetMode.signIn:
        return '登录 Satori';
      case _AuthSheetMode.signUp:
        return '创建账号';
      case _AuthSheetMode.resetPassword:
        return '重置密码';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case _AuthSheetMode.signIn:
        return '登录后可启用云端行迹与多端同步。';
      case _AuthSheetMode.signUp:
        return '首版仅支持邮箱密码账号。';
      case _AuthSheetMode.resetPassword:
        return '输入注册邮箱，我们会发送重置密码邮件。';
    }
  }

  String get _primaryButtonText {
    switch (_mode) {
      case _AuthSheetMode.signIn:
        return '登录';
      case _AuthSheetMode.signUp:
        return '注册';
      case _AuthSheetMode.resetPassword:
        return '发送重置邮件';
    }
  }

  Widget _buildModeTabs() {
    return Row(
      children: [
        _ModeChip(
          label: '登录',
          selected: _mode == _AuthSheetMode.signIn,
          onTap: () {
            widget.authController.clearMessages();
            setState(() => _mode = _AuthSheetMode.signIn);
          },
        ),
        const SizedBox(width: SatoriTheme.spacingS),
        _ModeChip(
          label: '注册',
          selected: _mode == _AuthSheetMode.signUp,
          onTap: () {
            widget.authController.clearMessages();
            setState(() => _mode = _AuthSheetMode.signUp);
          },
        ),
        const SizedBox(width: SatoriTheme.spacingS),
        _ModeChip(
          label: '重置密码',
          selected: _mode == _AuthSheetMode.resetPassword,
          onTap: () {
            widget.authController.clearMessages();
            setState(() => _mode = _AuthSheetMode.resetPassword);
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(
        labelText: '邮箱',
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      decoration: const InputDecoration(
        labelText: '密码',
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showSnack('请先输入邮箱');
      return;
    }

    bool success = false;
    switch (_mode) {
      case _AuthSheetMode.signIn:
        if (password.isEmpty) {
          _showSnack('请先输入密码');
          return;
        }
        success = await widget.authController.signInWithPassword(
          email: email,
          password: password,
        );
        break;
      case _AuthSheetMode.signUp:
        if (password.length < 6) {
          _showSnack('密码至少需要 6 位');
          return;
        }
        success = await widget.authController.signUpWithPassword(
          email: email,
          password: password,
        );
        break;
      case _AuthSheetMode.resetPassword:
        success = await widget.authController.sendPasswordReset(email);
        break;
    }

    if (!mounted || !success) return;

    final message = widget.authController.infoMessage;
    if (_mode == _AuthSheetMode.resetPassword) {
      if (message != null) _showSnack(message);
      setState(() => _mode = _AuthSheetMode.signIn);
      return;
    }

    Navigator.of(context).pop();
    if (message != null) _showSnack(message);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SatoriTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? SatoriColors.incenseEmber.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(SatoriTheme.cornerPill),
        ),
        child: Text(
          label,
          style: SatoriTypography.caption.copyWith(
            color: selected
                ? SatoriColors.incenseEmber
                : Colors.grey.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class PasswordRecoverySheet extends StatefulWidget {
  const PasswordRecoverySheet({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<PasswordRecoverySheet> createState() => _PasswordRecoverySheetState();
}

class _PasswordRecoverySheetState extends State<PasswordRecoverySheet> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E20) : Colors.white;

    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
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
                  const Text('设置新密码', style: SatoriTypography.title),
                  const SizedBox(height: SatoriTheme.spacingXS),
                  Text(
                    '邮箱回跳已成功进入 App，请立即设置新的登录密码。',
                    style: SatoriTypography.caption.copyWith(
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: SatoriTheme.spacingL),
                  _buildPasswordField(
                    controller: _passwordController,
                    label: '新密码',
                  ),
                  const SizedBox(height: SatoriTheme.spacingM),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: '确认新密码',
                  ),
                  if (widget.authController.errorMessage != null) ...[
                    const SizedBox(height: SatoriTheme.spacingM),
                    Text(
                      widget.authController.errorMessage!,
                      style: SatoriTypography.caption.copyWith(
                        color: SatoriColors.incenseEmber,
                      ),
                    ),
                  ],
                  if (widget.authController.infoMessage != null) ...[
                    const SizedBox(height: SatoriTheme.spacingM),
                    Text(
                      widget.authController.infoMessage!,
                      style: SatoriTypography.caption.copyWith(
                        color: SatoriColors.verdigris,
                      ),
                    ),
                  ],
                  const SizedBox(height: SatoriTheme.spacingL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.authController.isBusy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SatoriColors.incenseEmber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: widget.authController.isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              '更新密码',
                              style: SatoriTypography.subtitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: SatoriTheme.spacingS),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed:
                          widget.authController.isBusy ? null : _cancelRecovery,
                      child: Text(
                        '取消并退出恢复流程',
                        style: SatoriTypography.caption.copyWith(
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      autofillHints: const [AutofillHints.newPassword],
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 6) {
      _showSnack('密码至少需要 6 位');
      return;
    }
    if (password != confirmPassword) {
      _showSnack('两次输入的密码不一致');
      return;
    }

    final success = await widget.authController.updatePassword(
      password: password,
    );
    if (!mounted || !success) return;

    final message = widget.authController.infoMessage;
    Navigator.of(context).pop();
    if (message != null) _showSnack(message);
  }

  Future<void> _cancelRecovery() async {
    await widget.authController.signOut();
    if (!mounted) return;

    final message = widget.authController.infoMessage;
    Navigator.of(context).pop();
    if (message != null) _showSnack(message);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
