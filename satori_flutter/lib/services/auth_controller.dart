import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthViewState {
  unavailable,
  signedOut,
  signingIn,
  signedIn,
}

class AuthController extends ChangeNotifier {
  AuthController({SupabaseClient? client}) : _client = client {
    _refreshStatus(notify: false);
    _subscription = _client?.auth.onAuthStateChange.listen((_) {
      _busy = false;
      _refreshStatus();
    });
  }

  final SupabaseClient? _client;
  StreamSubscription<AuthState>? _subscription;

  AuthViewState _status = AuthViewState.unavailable;
  bool _busy = false;
  String? _errorMessage;
  String? _infoMessage;

  AuthViewState get status => _status;
  bool get isAvailable => _client != null;
  bool get isBusy => _busy;
  bool get isSignedIn => _status == AuthViewState.signedIn;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  User? get currentUser => _client?.auth.currentUser;
  String? get currentEmail => currentUser?.email;

  String get accountLabel {
    if (isSignedIn && currentEmail != null && currentEmail!.isNotEmpty) {
      return currentEmail!;
    }
    if (!isAvailable) return '云同步未配置';
    return '登录 / 注册';
  }

  String get statusLabel {
    switch (_status) {
      case AuthViewState.unavailable:
        return '本地模式';
      case AuthViewState.signedOut:
        return '未登录';
      case AuthViewState.signingIn:
        return '处理中';
      case AuthViewState.signedIn:
        return '已登录';
    }
  }

  void clearMessages() {
    if (_errorMessage == null && _infoMessage == null) return;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      _errorMessage = 'Supabase 尚未配置，无法登录。';
      notifyListeners();
      return false;
    }

    _beginRequest();
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _infoMessage = '已登录';
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '登录失败，请稍后重试。';
      return false;
    } finally {
      _endRequest();
    }
  }

  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      _errorMessage = 'Supabase 尚未配置，无法注册。';
      notifyListeners();
      return false;
    }

    _beginRequest();
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      _infoMessage = response.session == null
          ? '注册成功。若项目开启了邮箱确认，请先完成验证后再登录。'
          : '注册成功，已自动登录。';
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '注册失败，请稍后重试。';
      return false;
    } finally {
      _endRequest();
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    if (_client == null) {
      _errorMessage = 'Supabase 尚未配置，无法发送重置邮件。';
      notifyListeners();
      return false;
    }

    _beginRequest();
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      _infoMessage = '重置密码邮件已发送，请检查邮箱。';
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '发送重置邮件失败，请稍后重试。';
      return false;
    } finally {
      _endRequest();
    }
  }

  Future<void> signOut() async {
    if (_client == null) return;

    _beginRequest();
    try {
      await _client.auth.signOut();
      _infoMessage = '已退出登录';
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '退出登录失败，请稍后重试。';
    } finally {
      _endRequest();
    }
  }

  void _beginRequest() {
    _busy = true;
    _errorMessage = null;
    _infoMessage = null;
    _refreshStatus();
  }

  void _endRequest() {
    _busy = false;
    _refreshStatus();
  }

  void _refreshStatus({bool notify = true}) {
    if (_client == null) {
      _status = AuthViewState.unavailable;
    } else if (_busy) {
      _status = AuthViewState.signingIn;
    } else if (_client.auth.currentUser != null) {
      _status = AuthViewState.signedIn;
    } else {
      _status = AuthViewState.signedOut;
    }

    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
