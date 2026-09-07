/// 全局配置
class AppConfig {
  AppConfig._();

  /// 后端地址
  /// - Windows 桌面版 / 真机调试：127.0.0.1
  /// - Android 模拟器：请改成 10.0.2.2
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// 分页大小
  static const int pageSize = 10;

  /// 超时时间（秒）
  static const int connectTimeout = 10;
  static const int receiveTimeout = 15;

  /// 本地 Token 存储 key
  static const String tokenKey = 'taoyue_token';
  static const String userKey = 'taoyue_user';
}