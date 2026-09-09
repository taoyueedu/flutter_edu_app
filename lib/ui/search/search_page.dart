import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../core/storage/search_history.dart';
import '../../data/model/course.dart';
import '../../data/model/teacher.dart';
import '../../data/repository/course_repository.dart';
import '../../data/repository/teacher_repository.dart';
import '../../widgets/app_states.dart';
import '../../widgets/course_card.dart';

/// 搜索页：防抖实时搜索课程/讲师 + 搜索历史
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  bool _searched = false;
  bool _searching = false;
  List<Course> _courses = [];
  List<Teacher> _teachers = [];

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    _debounce?.cancel();
    final keyword = value.trim();
    if (keyword.isEmpty) {
      setState(() {
        _searched = false;
        _courses = [];
        _teachers = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _doSearch(keyword);
    });
  }

  Future<void> _doSearch(String keyword) async {
    setState(() {
      _searched = true;
      _searching = true;
    });

    final courseRepository = locator<CourseRepository>();
    final teacherRepository = locator<TeacherRepository>();

    final results = await Future.wait([
      courseRepository.searchCourses(keyword),
      teacherRepository.fetchTeachers(),
    ]);

    if (!mounted) return;
    setState(() {
      _courses = results[0] as List<Course>;
      _teachers = results[1] as List<Teacher>;
      _searching = false;
    });
  }

  void _submit(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) return;
    _debounce?.cancel();
    SearchHistory.add(keyword);
    _doSearch(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard,
      appBar: AppBar(
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              const SizedBox(width: AppDimens.spaceSm),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onInputChanged,
                  onSubmitted: _submit,
                  decoration: const InputDecoration(
                    hintText: '搜索课程 / 讲师',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _searched ? _buildResult() : _buildHistory(),
    );
  }

  // ---------- 搜索结果 ----------
  Widget _buildResult() {
    if (_searching) {
      return const AppLoading();
    }

    return ListView(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      children: [
        if (_courses.isNotEmpty) ...[
          const _SectionTitle('课程'),
          ..._courses.map((course) => CourseCard(
                course: course,
                onTap: () => context.push('/course/${course.id}'),
              )),
        ],
        if (_teachers.isNotEmpty) ...[
          const SizedBox(height: AppDimens.spaceMd),
          const _SectionTitle('讲师'),
          ..._teachers.map((teacher) => _TeacherTile(teacher: teacher)),
        ],
        if (_courses.isEmpty && _teachers.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 120),
            child: AppEmptyView(message: '未找到相关内容，换个关键词试试'),
          ),
      ],
    );
  }

  // ---------- 搜索历史 ----------
  Widget _buildHistory() {
    final history = SearchHistory.get();
    return ListView(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      children: [
        if (history.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                '搜索历史',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.textMuted),
                onPressed: () {
                  SearchHistory.clear();
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceSm),
          Wrap(
            spacing: AppDimens.spaceMd,
            runSpacing: AppDimens.spaceMd,
            children: history
                .map((keyword) => _HistoryChip(
                      keyword: keyword,
                      onTap: () {
                        _controller.text = keyword;
                        _submit(keyword);
                      },
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: AppDimens.spaceXl),
        const Text(
          '热门搜索',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: AppDimens.spaceSm),
        Wrap(
          spacing: AppDimens.spaceMd,
          runSpacing: AppDimens.spaceMd,
          children: const ['Flutter', 'Kotlin', '安卓开发', '后端', '设计模式']
              .map((keyword) => _HistoryChip(
                    keyword: keyword,
                    onTap: () {},
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ---------- 历史/热门 chip ----------
class _HistoryChip extends StatelessWidget {
  final String keyword;
  final VoidCallback onTap;

  const _HistoryChip({required this.keyword, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceLg,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          keyword,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ---------- 区块标题 ----------
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.spaceSm),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
    );
  }
}

// ---------- 讲师结果项 ----------
class _TeacherTile extends StatelessWidget {
  final Teacher teacher;

  const _TeacherTile({required this.teacher});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/teacher/${teacher.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spaceMd),
        margin: const EdgeInsets.only(bottom: AppDimens.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.brand.withValues(alpha: 0.1),
              backgroundImage: teacher.avatarUrl != null
                  ? NetworkImage(teacher.avatarUrl!)
                  : null,
              child: teacher.avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.brand)
                  : null,
            ),
            const SizedBox(width: AppDimens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teacher.title ?? '资深讲师',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
