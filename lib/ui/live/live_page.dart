import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/course.dart';
import '../../data/repository/live_repository.dart';
import '../../widgets/app_states.dart';

/// 直播公开课页
class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
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
    final repository = locator<LiveRepository>();
    final data = await repository.fetchLiveCourses();
    if (!mounted) return;
    setState(() {
      _courses = data;
      _loading = false;
      if (data.isEmpty) _error = '暂无直播';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AppLoading());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('直播公开课')),
        body: AppErrorView(message: _error!, onRetry: _load),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('直播公开课')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _courses.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  AppEmptyView(message: '暂无直播，敬请期待'),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppDimens.spaceLg),
                itemCount: _courses.length,
                itemBuilder: (context, index) => _LiveCard(
                  course: _courses[index],
                  onTap: () => context.push('/course/${_courses[index].id}'),
                ),
              ),
      ),
    );
  }
}

/// 直播卡片（带 LIVE 角标）
class _LiveCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _LiveCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  course.coverUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 120,
                    color: AppColors.bgInput,
                    child: const Icon(Icons.live_tv,
                        size: 40, color: AppColors.textMuted),
                  ),
                ),
                Positioned(
                  top: AppDimens.spaceMd,
                  left: AppDimens.spaceMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppDimens.spaceMd,
                  bottom: AppDimens.spaceSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${course.studentCount} 人观看',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
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
                      const Icon(Icons.person,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        course.teacherName ?? '官方讲师',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.play_circle_fill,
                          size: 14, color: AppColors.brand),
                      const SizedBox(width: 2),
                      const Text(
                        '立即观看',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brand,
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
