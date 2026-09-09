import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/course.dart';
import '../../data/repository/course_repository.dart';
import '../../providers/login_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_states.dart';

/// 课程详情页
class CourseDetailPage extends ConsumerStatefulWidget {
  final int courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  Course? _course;
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
    final repository = locator<CourseRepository>();
    final course = await repository.fetchCourseDetail(widget.courseId);
    if (!mounted) return;
    setState(() {
      _course = course;
      _loading = false;
      _error = course == null ? '课程不存在或加载失败' : null;
    });
  }

  /// 立即购买：先判断登录
  void _onBuy() {
    final isLoggedIn = ref.read(loginProvider).isLoggedIn;
    if (!isLoggedIn) {
      context.push('/login').then((ok) {
        if (ok == true && mounted) _createOrder();
      });
      return;
    }
    _createOrder();
  }

  Future<void> _createOrder() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在创建订单...')),
    );
    // 订单创建页（第 22 章实现）
    context.push('/order/create', extra: {'courseIds': [widget.courseId]});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: AppLoading());
    }
    if (_error != null) {
      return Scaffold(
        body: AppErrorView(message: _error!, onRetry: _load),
      );
    }

    final course = _course!;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(course: course),
          _PriceCard(course: course),
          _DescriptionCard(course: course),
          _ChaptersCard(course: course),
          _TeacherCard(course: course),
          const SizedBox(height: 90),
        ],
      ),
      bottomNavigationBar: _BottomBar(course: course, onBuy: _onBuy),
    );
  }
}

// ---------- 顶部封面 ----------
class _Header extends StatelessWidget {
  final Course course;
  const _Header({required this.course});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: course.coverUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              color: AppColors.bgInput,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, _, _) => Container(
              color: AppColors.bgInput,
              child: const Icon(Icons.broken_image, size: 48),
            ),
          ),
        ),
        // 渐变遮罩
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(AppDimens.spaceLg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.spaceSm),
                Text(
                  '${course.teacherName ?? '官方讲师'} · '
                  '${course.studentCount}人已学',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        // 返回按钮
        Positioned(
          top: AppDimens.spaceMd,
          left: AppDimens.spaceMd,
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- 价格区 ----------
class _PriceCard extends StatelessWidget {
  final Course course;
  const _PriceCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimens.spaceLg),
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            course.priceText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.price,
            ),
          ),
          const SizedBox(width: AppDimens.spaceSm),
          if (course.originalPrice > course.price)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '原价 ¥${course.originalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
          const Spacer(),
          const Icon(Icons.verified, size: 16, color: AppColors.brand),
          const SizedBox(width: 4),
          const Text(
            '正版保障',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ---------- 课程简介 ----------
class _DescriptionCard extends StatelessWidget {
  final Course course;
  const _DescriptionCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '课程简介',
      child: Text(
        course.description ?? '暂无简介',
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }
}

// ---------- 章节大纲 ----------
class _ChaptersCard extends StatelessWidget {
  final Course course;
  const _ChaptersCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final chapters = course.chapters ?? const [];
    return _SectionCard(
      title: '章节大纲（${chapters.length} 章）',
      child: Column(
        children: List.generate(chapters.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline,
                    size: 18, color: AppColors.brand),
                const SizedBox(width: AppDimens.spaceSm),
                Expanded(
                  child: Text(
                    chapters[index],
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------- 讲师介绍 ----------
class _TeacherCard extends StatelessWidget {
  final Course course;
  const _TeacherCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '讲师介绍',
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.brand.withValues(alpha: 0.1),
            backgroundImage: course.teacherAvatar != null
                ? CachedNetworkImageProvider(course.teacherAvatar!)
                : null,
            child: course.teacherAvatar == null
                ? const Icon(Icons.person, color: AppColors.brand)
                : null,
          ),
          const SizedBox(width: AppDimens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.teacherName ?? '官方讲师',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '深耕一线教学多年，注重实战',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 通用区块 ----------
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimens.spaceLg,
        0,
        AppDimens.spaceLg,
        AppDimens.spaceLg,
      ),
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: AppDimens.spaceMd),
          child,
        ],
      ),
    );
  }
}

// ---------- 底部购买栏 ----------
class _BottomBar extends StatelessWidget {
  final Course course;
  final VoidCallback onBuy;
  const _BottomBar({required this.course, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceLg,
          vertical: AppDimens.spaceSm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              course.priceText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.price,
              ),
            ),
            const SizedBox(width: AppDimens.spaceLg),
            Expanded(
              child: AppButton(text: '立即购买', onPressed: onBuy),
            ),
          ],
        ),
      ),
    );
  }
}
