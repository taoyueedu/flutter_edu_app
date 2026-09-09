import '../../core/network/api_client.dart';
import '../model/course.dart';

/// 课程列表 / 详情 / 搜索 仓库
class CourseRepository {
  final ApiClient _api = ApiClient.instance;

  /// 分页加载课程列表
  Future<List<Course>> fetchCourses({
    List<int>? categoryIds,
    String? sortBy, // price_asc / price_desc / students_desc / newest
    int page = 1,
    int pageSize = 10,
  }) async {
    final result = await _api.get<List<Course>>(
      '/courses',
      query: {
        if (categoryIds != null && categoryIds.isNotEmpty)
          'category_ids': categoryIds.join(','),
        'sort_by': ?sortBy,
        'page': page,
        'page_size': pageSize,
      },
      transform: (d) => _toList(d, Course.fromJson),
    );
    return result.data ?? const [];
  }

  /// 课程详情
  Future<Course?> fetchCourseDetail(int id) async {
    final result = await _api.get<Course>(
      '/courses/$id',
      transform: (d) =>
          d is Map<String, dynamic> ? Course.fromJson(d) : null,
    );
    return result.data;
  }

  /// 搜索
  Future<List<Course>> searchCourses(String keyword) async {
    final result = await _api.get<List<Course>>(
      '/courses/search',
      query: {'keyword': keyword},
      transform: (d) => _toList(d, Course.fromJson),
    );
    return result.data ?? const [];
  }

  static List<T>? _toList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return null;
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}
