import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../data/model/banner.dart';
import '../../data/model/category.dart';
import '../../data/model/course.dart';
import '../../data/repository/home_repository.dart';

/// 首页状态（数据容器，对应 StateFlow 的"当前值"）
class HomeState {
  final bool loading;
  final String? error;
  final List<BannerModel> banners;
  final List<Category> categories;
  final List<Course> featuredCourses;
  final Map<int, List<Course>> sectionCourses;

  const HomeState({
    this.loading = true,
    this.error,
    this.banners = const [],
    this.categories = const [],
    this.featuredCourses = const [],
    this.sectionCourses = const {},
  });

  HomeState copyWith({
    bool? loading,
    String? error,
    List<BannerModel>? banners,
    List<Category>? categories,
    List<Course>? featuredCourses,
    Map<int, List<Course>>? sectionCourses,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      featuredCourses: featuredCourses ?? this.featuredCourses,
      sectionCourses: sectionCourses ?? this.sectionCourses,
    );
  }
}

/// 首页状态管理（对应 HomeViewModel）
class HomeNotifier extends Notifier<HomeState> {
  HomeRepository get _repository => locator<HomeRepository>();

  @override
  HomeState build() => const HomeState();

  /// 首次加载：并发请求 Banner + 分类 + 精选 + 前几个分类的课程
  Future<void> loadHomeData() async {
    state = state.copyWith(loading: true, error: null);

    try {
      // 并发请求（Future.wait = 同时发多个请求，快）
      final results = await Future.wait([
        _repository.fetchBanners(),
        _repository.fetchCategories(),
        _repository.fetchCourses(isFeatured: true),
      ]);
      final banners = results[0] as List<BannerModel>;
      final categories = results[1] as List<Category>;
      final featuredCourses = results[2] as List<Course>;

      // 逐个分类加载课程（最多 4 个分类区块）
      final sectionCourses = <int, List<Course>>{};
      final cats = categories.take(4).toList();
      for (final c in cats) {
        final courses = await _repository.fetchCourses(categoryIds: [c.id]);
        sectionCourses[c.id] = courses;
      }
  
      // 将原来的状态复制给state新的状态，然后单独修改
      state = state.copyWith(
        loading: false,
        banners: banners,
        categories: categories,
        featuredCourses: featuredCourses,
        sectionCourses: sectionCourses,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '加载失败：$e');
    }
  }
}

/// 全局/页面级 Provider（页面用 ref.watch(homeProvider) 读数据）
final homeProvider =
    NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);