import '../../core/network/api_client.dart';
import '../model/course.dart';

/// 训练营仓库
class TrainingRepository {
  final ApiClient _api = ApiClient.instance;

  /// 训练营课程列表
  Future<List<Course>> fetchTrainingCourses() async {
    final result = await _api.get<List<Course>>(
      '/courses',
      query: {'is_training_camp': true, 'page_size': 20},
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
