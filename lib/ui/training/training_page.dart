import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/course.dart';
import '../../data/repository/training_repository.dart';
import '../../widgets/app_states.dart';

/// 训练营页
class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
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
    final repository = locator<TrainingRepository>();
    final data = await repository.fetchTrainingCourses();
    if (!mounted) return;
    setState(() {
      _courses = data;
      _loading = false;
      if (data.isEmpty) _error = '暂无训练营';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AppLoading());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('训练营')),
        body: AppErrorView(message: _error!, onRetry: _load),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('训练营')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _courses.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  AppEmptyView(message: '暂无训练营，敬请期待'),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppDimens.spaceLg),
                itemCount: _courses.length,
                itemBuilder: (context, index) => _CampCard(
                  course: _courses[index],
                  onTap: () => context.push('/course/${_courses[index].id}'),
                ),
              ),
      ),
    );
  }
}

/// 训练营卡片
class _CampCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CampCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.spaceMd),
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: const Icon(Icons.flag, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppDimens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '训练营',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spaceSm),
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceSm),
                  Row(
                    children: [
                      const Icon(Icons.people,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${course.studentCount} 人已报名',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        course.priceText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.price,
                        ),
                      ),
                      if (course.originalPrice > course.price)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '¥${course.originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
