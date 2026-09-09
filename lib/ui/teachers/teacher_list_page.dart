import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/teacher.dart';
import '../../data/repository/teacher_repository.dart';
import '../../widgets/app_states.dart';

/// 讲师列表页
class TeacherListPage extends StatefulWidget {
  const TeacherListPage({super.key});

  @override
  State<TeacherListPage> createState() => _TeacherListPageState();
}

class _TeacherListPageState extends State<TeacherListPage> {
  List<Teacher> _teachers = [];
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
    final data = await repository.fetchTeachers();
    if (!mounted) return;
    setState(() {
      _teachers = data;
      _loading = false;
      if (data.isEmpty) _error = '暂无讲师';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AppLoading());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('讲师团队')),
        body: AppErrorView(message: _error!, onRetry: _load),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('讲师团队')),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        itemCount: _teachers.length,
        itemBuilder: (context, index) {
          final teacher = _teachers[index];
          return _TeacherCard(
            teacher: teacher,
            onTap: () => context.push('/teacher/${teacher.id}'),
          );
        },
      ),
    );
  }
}

/// 讲师卡片
class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onTap;

  const _TeacherCard({required this.teacher, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        margin: const EdgeInsets.only(bottom: AppDimens.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.brand.withValues(alpha: 0.1),
              backgroundImage: teacher.avatarUrl != null
                  ? NetworkImage(teacher.avatarUrl!)
                  : null,
              child: teacher.avatarUrl == null
                  ? const Icon(Icons.person, size: 30, color: AppColors.brand)
                  : null,
            ),
            const SizedBox(width: AppDimens.spaceLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        teacher.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(width: AppDimens.spaceSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          teacher.title ?? '资深讲师',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    teacher.description ?? '深耕一线教学多年，注重实战',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${teacher.courseCount} 门课程',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
