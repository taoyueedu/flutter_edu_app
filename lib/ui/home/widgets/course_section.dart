import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../data/model/course.dart';
import '../../../widgets/course_card.dart';

/// 首页课程区块：标题栏 + 横向滚动课程卡片
class CourseSection extends StatelessWidget {
  final String title;
  final List<Course> courses;

  const CourseSection({super.key, required this.title, required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceLg),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppDimens.spaceSm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/courses'),
                child: const Text(
                  '查看全部',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        // 横向滚动课程卡片
        SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimens.spaceLg),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return SizedBox(
                width: 260,
                child: CourseCard(
                  course: course,
                  onTap: () => context.push('/course/${course.id}'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppDimens.spaceMd),
      ],
    );
  }
}
