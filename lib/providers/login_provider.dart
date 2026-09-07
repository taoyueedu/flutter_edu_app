import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di.dart';
import '../data/model/user.dart';

/// 登录状态（对应 Kotlin 版 LoginViewModel + StateFlow 的"当前值"）
class LoginState {
  final User? user;          // 当前登录用户
  final bool isLoading;      // 是否正在请求
  final String? errorMessage;// 错误提示

  const LoginState({this.user, this.isLoading = false, this.errorMessage});

  bool get isLoggedIn => user != null;

  LoginState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return LoginState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 全局登录逻辑（对应 Kotlin 版 LoginViewModel + StateFlow）
/// 用 `locator<AuthRepository>()` 取仓库（第 08 章的手写 DI 仍可用）。
class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// 密码登录
  Future<bool> loginWithPassword(String phone, String password) =>
      _doLogin(() => locator<AuthRepository>().loginWithPassword(
          phone: phone, password: password));

  /// 短信登录
  Future<bool> loginWithSms(String phone, String smsCode) =>
      _doLogin(() => locator<AuthRepository>().loginWithSms(
          phone: phone, smsCode: smsCode));

  Future<bool> _doLogin(Future<User?> Function() action) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final user = await action();

    if (user != null) {
      state = state.copyWith(user: user, isLoading: false);
      return true;
    }
    state = state.copyWith(
      isLoading: false,
      errorMessage: '登录失败，请检查账号或验证码',
    );
    return false;
  }

  /// 退出登录
  void logout() => state = state.copyWith(clearUser: true);
}

/// 全局 Provider（后面所有页面用 `ref.watch(loginProvider)` 读登录态）
final loginProvider =
    NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);