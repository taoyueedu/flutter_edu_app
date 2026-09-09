import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/course.dart';
import '../../data/model/teacher.dart';
import '../../data/repository/teacher_repository.dart';
import '../../widgets/app_states.dart';
import '../../widgets/course_card.dart';

/// 讲师详情页
class TeacherDetailPage extends StatefulWidget {
  final int teacherId;

  const TeacherDetailPage({super.key, required this.teacherId});

  @override
  State<TeacherDetailPage> createState() => _TeacherDetailPageState();
}

class _TeacherDetailPageState extends State<TeacherDetailPage> {
  Teacher? _teacher;
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final repository = locator<TeacherRepository>();
    final results = await Future.wait([
      _fetchTeacher(repository),
      repository.fetchTeacherCourses(widget.teacherId),
    ]);

    if (!mounted) return;
    setState(() {
      _teacher = results[0] as Teacher?;
      _courses = results[1] as List<Course>;
      _loading = false;
      _error = _teacher == null ? '讲师不存在' : null;
    });
  }

  Future<Teacher?> _fetchTeacher(TeacherRepository repository) async {
    final teachers = await repository.fetchTeachers();
    for (final t in teachers) {
      if (t.id == widget.teacherId) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AppLoading());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: AppErrorView(message: _error!, onRetry: _load),
      );
    }

    final teacher = _teacher!;
    return Scaffold(
      appBar: AppBar(title: const Text('讲师详情')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.spaceXl),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  backgroundImage: teacher.avatarUrl != null
                      ? CachedNetworkImageProvider(teacher.avatarUrl!)
                      : null,
                  child: teacher.avatarUrl == null
                      ? const Icon(Icons.person,
                          size: 40, color: AppColors.brand)
                      : null,
                ),
                const SizedBox(height: AppDimens.spaceMd),
                Text(
                  teacher.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.spaceXs),
                Text(
                  teacher.title ?? '资深讲师',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: AppDimens.spaceMd),
                Text(
                  teacher.description ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),
          Text(
            'TA 的课程（${_courses.length}）',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: AppDimens.spaceSm),
          if (_courses.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: AppEmptyView(message: '该讲师暂无课程'),
            )
          else
            ..._courses.map((course) => CourseCard(
                  course: course,
                  onTap: () => context.push('/course/${course.id}'),
                )),
        ],
      ),
    );
  }
}
