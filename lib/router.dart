import 'package:go_router/go_router.dart';

import 'ui/course_detail/course_detail_page.dart';
import 'ui/login/login_page.dart';
import 'ui/main/main_page.dart';
import 'ui/orders/order_detail_page.dart';
import 'ui/teachers/teacher_detail_page.dart';

/// 全局路由表
/// 页面路径约定（企业级规范）：
/// /           主框架（底部导航）
/// /login      登录
/// /course/:id 课程详情
/// /teacher/:id 讲师详情
/// /order/:no  订单详情
abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const courseDetail = '/course/:id';
  static const teacherDetail = '/teacher/:id';
  static const orderDetail = '/order/:no';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.courseDetail,
      builder: (context, state) => CourseDetailPage(
        courseId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: AppRoutes.teacherDetail,
      builder: (context, state) => TeacherDetailPage(
        teacherId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: AppRoutes.orderDetail,
      builder: (context, state) => OrderDetailPage(
        orderNo: state.pathParameters['no']!,
      ),
    ),
  ],
);