import '../../core/network/api_client.dart';
import '../model/banner.dart';
import '../model/category.dart';
import '../model/course.dart';

/// 首页数据仓库：聚合 Banner + 分类 + 精选课程 + 各分类课程
class HomeRepository {
  final ApiClient _api = ApiClient.instance;

  /// 获取首页轮播图
  Future<List<BannerModel>> fetchBanners() async {
    final result = await _api.get<List<BannerModel>>(
      '/content/banners',
      query: {'position': 'home'},
      transform: (d) => _toList(d, BannerModel.fromJson),
    );
    return result.data ?? const [];
  }

  /// 获取分类
  Future<List<Category>> fetchCategories() async {
    final result = await _api.get<List<Category>>(
      '/courses/categories',
      transform: (d) => _toList(d, Category.fromJson),
    );
    return result.data ?? const [];
  }

  /// 获取课程列表（精选 or 指定分类）
  Future<List<Course>> fetchCourses({
    bool isFeatured = false,
    List<int>? categoryIds,
  }) async {
    final result = await _api.get<List<Course>>(
      '/courses',
      query: {
        if (isFeatured) 'is_featured': true,
        if (categoryIds != null && categoryIds.isNotEmpty)
          'category_ids': categoryIds.join(','),
        'page_size': 6,
      },
      transform: (d) => _toList(d, Course.fromJson),
    );
    return result.data ?? const [];
  }

  /// 把 json['data'] 里的 List 逐个转成模型 List；data 非 List 返回 null
  static List<T>? _toList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return null;
    return data
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
