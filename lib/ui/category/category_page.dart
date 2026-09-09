import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/category.dart';
import '../../data/model/course.dart';
import '../../data/repository/course_repository.dart';
import '../../data/repository/home_repository.dart';
import '../../widgets/app_states.dart';
import '../../widgets/course_card.dart';

/// 分类页：左侧分类 + 右侧课程（左右联动）
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final HomeRepository _homeRepository = locator<HomeRepository>();
  final CourseRepository _courseRepository = locator<CourseRepository>();

  List<Category> _categories = [];
  List<Course> _courses = [];
  int _selectedIndex = 0; // 0 = 全部
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _categories = await _homeRepository.fetchCategories();
    await _loadCourses();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadCourses() async {
    final categoryId = _selectedIndex == 0
        ? null
        : _categories[_selectedIndex - 1].id;

    final data = await _courseRepository.fetchCourses(
      categoryIds: categoryId != null ? [categoryId] : null,
      pageSize: 50,
    );
    if (!mounted) return;
    setState(() => _courses = data);
  }

  void _selectCategory(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _loading = true;
    });
    _loadCourses().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('课程分类')),
      body: _loading
          ? const AppLoading()
          : Row(
              children: [
                // 左侧分类导航
                SizedBox(
                  width: 96,
                  child: ListView.builder(
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      final label =
                          index == 0 ? '全部' : _categories[index - 1].name;
                      final selected = index == _selectedIndex;
                      return _LeftItem(
                        label: label,
                        selected: selected,
                        onTap: () => _selectCategory(index),
                      );
                    },
                  ),
                ),
                // 右侧课程列表
                Expanded(
                  child: Container(
                    color: AppColors.bgLight,
                    child: _courses.isEmpty
                        ? const AppEmptyView(message: '该分类下暂无课程')
                        : ListView.builder(
                            itemCount: _courses.length,
                            itemBuilder: (context, index) {
                              final course = _courses[index];
                              return CourseCard(
                                course: course,
                                onTap: () =>
                                    context.push('/course/${course.id}'),
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

/// 左侧分类项
class _LeftItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LeftItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.spaceLg,
          horizontal: AppDimens.spaceSm,
        ),
        color: selected ? AppColors.bgCard : AppColors.bgLight,
        child: Stack(
          children: [
            if (selected)
              const Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: SizedBox(
                  width: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color:
                      selected ? AppColors.brand : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
