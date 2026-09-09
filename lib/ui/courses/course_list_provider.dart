import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../data/model/category.dart';
import '../../data/model/course.dart';
import '../../data/repository/course_repository.dart';
import '../../data/repository/home_repository.dart';

/// 课程列表状态
class CourseListState {
  final List<Category> categories;
  final int? selectedCategoryId;
  final String sortBy; // newest / students_desc / price_asc / price_desc
  final List<Course> courses;
  final int page;
  final bool hasMore;
  final bool loading;
  final bool loadingMore;
  final String? error;

  const CourseListState({
    this.categories = const [],
    this.selectedCategoryId,
    this.sortBy = 'newest',
    this.courses = const [],
    this.page = 1,
    this.hasMore = true,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  CourseListState copyWith({
    List<Category>? categories,
    int? selectedCategoryId,
    String? sortBy,
    List<Course>? courses,
    int? page,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    String? error,
  }) {
    return CourseListState(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      sortBy: sortBy ?? this.sortBy,
      courses: courses ?? this.courses,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error ?? this.error,
    );
  }
}

/// 课程列表状态管理
class CourseListNotifier extends Notifier<CourseListState> {
  CourseRepository get _courseRepository => locator<CourseRepository>();
  HomeRepository get _homeRepository => locator<HomeRepository>();

  @override
  CourseListState build() => const CourseListState();

  /// 初始化：先拿分类，再加载第一页
  Future<void> loadInitial({int? categoryId}) async {
    state = state.copyWith(
      loading: true,
      error: null,
      selectedCategoryId: categoryId ?? state.selectedCategoryId,
    );

    try {
      final categories = await _homeRepository.fetchCategories();
      state = state.copyWith(categories: categories);
      await refresh();
    } catch (e) {
      state = state.copyWith(loading: false, error: '加载失败：$e');
    }
  }

  /// 刷新（第一页）
  Future<void> refresh() async {
    final data = await _courseRepository.fetchCourses(
      categoryIds:
          state.selectedCategoryId != null ? [state.selectedCategoryId!] : null,
      sortBy: state.sortBy,
      page: 1,
    );
    state = state.copyWith(
      page: 1,
      courses: data,
      hasMore: data.isNotEmpty,
      loading: false,
      error: null,
    );
  }

  /// 上拉加载更多
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.loading) return;

    state = state.copyWith(loadingMore: true);
    final data = await _courseRepository.fetchCourses(
      categoryIds:
          state.selectedCategoryId != null ? [state.selectedCategoryId!] : null,
      sortBy: state.sortBy,
      page: state.page + 1,
    );

    if (data.isEmpty) {
      state = state.copyWith(loadingMore: false, hasMore: false);
    } else {
      state = state.copyWith(
        loadingMore: false,
        page: state.page + 1,
        courses: [...state.courses, ...data],
      );
    }
  }

  /// 切换分类
  Future<void> selectCategory(int? categoryId) async {
    if (state.selectedCategoryId == categoryId) return;
    state = state.copyWith(selectedCategoryId: categoryId, loading: true);
    await refresh();
  }

  /// 切换排序
  Future<void> selectSort(String sortBy) async {
    if (state.sortBy == sortBy) return;
    state = state.copyWith(sortBy: sortBy, loading: true);
    await refresh();
  }
}

/// 页面级 Provider
final courseListProvider =
    NotifierProvider<CourseListNotifier, CourseListState>(
  CourseListNotifier.new,
);
