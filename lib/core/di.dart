import 'package:get_it/get_it.dart';

import '../data/repository/auth_repository.dart';
import '../data/repository/course_repository.dart';
import '../data/repository/home_repository.dart';
import '../data/repository/live_repository.dart';
import '../data/repository/order_repository.dart';
import '../data/repository/teacher_repository.dart';
import '../data/repository/training_repository.dart';

/// 全局依赖注入容器（get_it）
/// 页面/ViewModel 用 `locator<T>()` 取仓库，避免直接 new。
final GetIt locator = GetIt.instance;

/// 初始化依赖注册（在 main() 里调用）
Future<void> setupLocator() async {
  locator.registerLazySingleton<HomeRepository>(() => HomeRepository());
  locator.registerLazySingleton<CourseRepository>(() => CourseRepository());
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository());
  locator.registerLazySingleton<TeacherRepository>(() => TeacherRepository());
  locator.registerLazySingleton<LiveRepository>(() => LiveRepository());
  locator.registerLazySingleton<TrainingRepository>(() => TrainingRepository());
  locator.registerLazySingleton<OrderRepository>(() => OrderRepository());
}
