import 'dart:convert';

import '../../core/constants/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/sp_util.dart';
import '../model/user.dart';

/// 登录注册仓库
class AuthRepository {
  final ApiClient _api = ApiClient.instance;

  /// 密码登录
  Future<User?> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    final result = await _api.post<dynamic>(
      '/auth/password-login/client',
      body: {'phone': phone, 'password': password},
      transform: (d) => d,
    );
    return _handleLoginResult(result.data);
  }

  /// 短信验证码登录
  Future<User?> loginWithSms({
    required String phone,
    required String smsCode,
  }) async {
    final result = await _api.post<dynamic>(
      '/auth/login',
      body: {'phone': phone, 'sms_code': smsCode},
      transform: (d) => d,
    );
    return _handleLoginResult(result.data);
  }

  /// 发送验证码
  Future<bool> sendSmsCode(String phone) async {
    final result = await _api.post<dynamic>(
      '/auth/sms-code',
      body: {'phone': phone},
    );
    return result.isSuccess;
  }

  /// 注册
  Future<bool> register({
    required String phone,
    required String password,
    required String smsCode,
  }) async {
    final result = await _api.post<dynamic>(
      '/auth/register',
      body: {'phone': phone, 'password': password, 'sms_code': smsCode},
    );
    return result.isSuccess;
  }

  /// 处理登录返回：存 token、存用户 JSON
  User? _handleLoginResult(dynamic data) {
    if (data == null) return null;
    if (data is! Map<String, dynamic>) return null;
    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      SpUtil.setString(AppConfig.tokenKey, token);
    }
    final user = User.fromJson(data);
    SpUtil.setString(AppConfig.userKey, jsonEncode(user.toJson()));
    return user;
  }

  /// 从本地读取已保存的用户（App 启动恢复登录态用）
  User? fetchLocalUser() {
    final raw = SpUtil.getString(AppConfig.userKey);
    if (raw.isEmpty) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 退出登录：清本地 token 与用户
  Future<void> logout() async {
    await SpUtil.remove(AppConfig.tokenKey);
    await SpUtil.remove(AppConfig.userKey);
  }

  /// 拉取当前登录用户（服务端为准）
  Future<User?> fetchMe() async {
    final result = await _api.get<dynamic>('/auth/me', transform: (d) => d);
    if (!result.isSuccess || result.data == null) return null;
    if (result.data is! Map<String, dynamic>) return null;
    return User.fromJson(result.data as Map<String, dynamic>);
  }
}
