import 'package:go_router/go_router.dart';

import 'data/model/category.dart';
import 'ui/course_detail/course_detail_page.dart';
import 'ui/courses/course_list_page.dart';
import 'ui/live/live_page.dart';
import 'ui/login/login_page.dart';
import 'ui/login/register_page.dart';
import 'ui/main/main_page.dart';
import 'ui/orders/order_confirm_page.dart';
import 'ui/orders/order_detail_page.dart';
import 'ui/orders/order_list_page.dart';
import 'ui/orders/pay_page.dart';
import 'ui/search/search_page.dart';
import 'ui/teachers/teacher_detail_page.dart';

/// 全局路由表
/// 页面路径约定（企业级规范）：
/// /           主框架（底部导航）
/// /login      登录
/// /course/:id 课程详情
/// /teacher/:id 讲师详情
/// /order/:no  订单详情
/// /live       直播
/// /search     搜索
/// /courses    全部课程（列表，可从首页"查看全部"或分类宫格进入）
abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const courseDetail = '/course/:id';
  static const teacherDetail = '/teacher/:id';
  static const orderDetail = '/order/:no';
  static const live = '/live';
  static const search = '/search';
  static const courses = '/courses';
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
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.live,
      builder: (context, state) => const LivePage(),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: AppRoutes.courses,
      builder: (context, state) {
        final category = state.extra as Category?;
        return CourseListPage(initialCategory: category);
      },
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
      path: '/orders',
      builder: (context, state) => const OrderListPage(),
    ),
    GoRoute(
      path: '/order/create',
      builder: (context, state) {
        final extra =
            state.extra as Map<String, dynamic>? ?? const <String, dynamic>{};
        final ids = (extra['courseIds'] as List?)?.cast<int>() ?? const [];
        return OrderConfirmPage(courseIds: ids);
      },
    ),
    GoRoute(
      path: '/pay/:no',
      builder: (context, state) =>
          PayPage(orderNo: state.pathParameters['no']!),
    ),
    GoRoute(
      path: AppRoutes.orderDetail,
      builder: (context, state) => OrderDetailPage(
        orderNo: state.pathParameters['no']!,
      ),
    ),
  ],
);