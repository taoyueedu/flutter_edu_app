import '../../core/network/api_client.dart';
import '../model/course.dart';
import '../model/teacher.dart';

/// 讲师仓库
class TeacherRepository {
  final ApiClient _api = ApiClient.instance;

  /// 讲师列表
  Future<List<Teacher>> fetchTeachers() async {
    final result = await _api.get<List<Teacher>>(
      '/courses/teachers',
      transform: (d) => _toList(d, Teacher.fromJson),
    );
    return result.data ?? const [];
  }

  /// 讲师详情
  Future<Teacher?> fetchTeacherDetail(int id) async {
    final result = await _api.get<Teacher>(
      '/courses/teachers/$id',
      transform: (d) =>
          d is Map<String, dynamic> ? Teacher.fromJson(d) : null,
    );
    return result.data;
  }

  /// 讲师名下课程
  Future<List<Course>> fetchTeacherCourses(int teacherId) async {
    final result = await _api.get<List<Course>>(
      '/courses',
      query: {'teacher_id': teacherId},
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
