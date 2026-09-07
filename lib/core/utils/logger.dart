import 'package:flutter/foundation.dart';

/// 简单日志封装：debug 模式才打印
class Logger {
  Logger._();

  static void log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[TaoyueEdu] $message');
    }
  }
}