/// 全局配置
/// 三套环境（dev / staging / prod）的值在构建时用 --dart-define 注入：
///   dev:     默认值，无需注入
///   staging: flutter run --dart-define=APP_ENV=staging \
///                        --dart-define=API_BASE_URL=https://staging-api.taoyue.com
///   prod:    flutter build apk --dart-define=APP_ENV=prod \
///                        --dart-define=API_BASE_URL=https://api.taoyue.com
/// 可追溯字段（COMMIT_HASH / BUILD_NUMBER）由 CI 注入，见第 8 章。
class AppConfig {
  AppConfig._();

  /// 当前构建环境：dev / staging / prod
  static const String env =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// 后端地址
  /// - 默认值保留本机调试地址（Windows 桌面 / 真机）
  /// - Android 模拟器访问宿主机请传 --dart-define=API_BASE_URL=http://10.0.2.2:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// 本次构建对应的 git commit（短哈希），用于线上回溯，CI 注入
  static const String commitHash =
      String.fromEnvironment('COMMIT_HASH', defaultValue: 'unknown');

  /// 本次构建号（自动递增），CI 注入
  static const String buildNumber =
      String.fromEnvironment('BUILD_NUMBER', defaultValue: '0');

  /// 是否为正式环境（决定日志、测试入口等行为）
  static bool get isProd => env == 'prod';

  /// 分页大小
  static const int pageSize = 10;

  /// 超时时间（秒）
  static const int connectTimeout = 10;
  static const int receiveTimeout = 15;

  /// 本地 Token 存储 key
  static const String tokenKey = 'taoyue_token';
  static const String userKey = 'taoyue_user';
}
