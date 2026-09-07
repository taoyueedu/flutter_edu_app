import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 简易封装（同步接口，底层异步缓存）
class SpUtil {
  SpUtil._();

  static late SharedPreferences _prefs;

  /// 必须在 main() 里先调用
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String getString(String key, {String def = ''}) =>
      _prefs.getString(key) ?? def;

  static Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  static Future<void> remove(String key) => _prefs.remove(key);
}