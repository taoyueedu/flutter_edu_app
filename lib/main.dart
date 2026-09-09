import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator(); // 注册全局依赖（get_it），页面用 locator<T>() 取仓库
  runApp(const TaoyueEduApp());
}
