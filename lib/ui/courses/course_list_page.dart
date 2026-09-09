import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../data/model/category.dart';
import '../../data/model/course.dart';
import '../../widgets/app_states.dart';
import '../../widgets/course_card.dart';
import 'course_list_provider.dart';

/// 全部课程页：分类筛选 + 排序 + 分页加载
class CourseListPage extends ConsumerStatefulWidget {
  final Category? initialCategory;

  const CourseListPage({super.key, this.initialCategory});

  @override
  ConsumerState<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends ConsumerState<CourseListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 延迟到首帧构建完成后加载，避免在 widget 树构建期间同步修改 provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(courseListProvider.notifier)
          .loadInitial(categoryId: widget.initialCategory?.id);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(courseListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseListProvider);

    if (state.loading) {
      return const Scaffold(body: AppLoading());
    }
    if (state.error != null && state.courses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('全部课程')),
        body: AppErrorView(
          message: state.error!,
          onRetry: () => ref.read(courseListProvider.notifier).loadInitial(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('全部课程')),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(courseListProvider.notifier).loadInitial(),
              child: state.courses.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        AppEmptyView(message: '没有符合条件的课程'),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: state.courses.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.courses.length) {
                          return const _Footer();
                        }
                        final Course course = state.courses[index];
                        return CourseCard(
                          course: course,
                          onTap: () => context.push('/course/${course.id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部加载状态
class _Footer extends ConsumerWidget {
  const _Footer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseListProvider);

    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            '— 没有更多了 —',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brand,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

/// 分类 + 排序筛选栏
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseListProvider);
    final notifier = ref.read(courseListProvider.notifier);

    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceMd),
      child: Column(
        children: [
          // 分类 chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.spaceLg),
              children: [
                _Chip(
                  label: '全部',
                  selected: state.selectedCategoryId == null,
                  onTap: () => notifier.selectCategory(null),
                ),
                ...state.categories.map(
                  (c) => _Chip(
                    label: c.name,
                    selected: state.selectedCategoryId == c.id,
                    onTap: () => notifier.selectCategory(c.id),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceMd),
          // 排序栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SortItem(
                label: '最新',
                selected: state.sortBy == 'newest',
                onTap: () => notifier.selectSort('newest'),
              ),
              _SortItem(
                label: '人气',
                selected: state.sortBy == 'students_desc',
                onTap: () => notifier.selectSort('students_desc'),
              ),
              _SortItem(
                label: '价格↑',
                selected: state.sortBy == 'price_asc',
                onTap: () => notifier.selectSort('price_asc'),
              ),
              _SortItem(
                label: '价格↓',
                selected: state.sortBy == 'price_desc',
                onTap: () => notifier.selectSort('price_desc'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单个分类 chip
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: AppDimens.spaceMd),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceLg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.bgInput,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 排序项
class _SortItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? AppColors.brand : AppColors.textSecondary,
        ),
      ),
    );
  }
}
