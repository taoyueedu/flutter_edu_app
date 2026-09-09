import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../data/model/category.dart';
import '../../widgets/app_states.dart';
import 'home_provider.dart';
import 'widgets/banner_slider.dart';
import 'widgets/category_grid.dart';
import 'widgets/course_section.dart';
import 'widgets/home_header.dart';

/// 首页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // 延迟到首帧构建完成后加载，避免在 widget 树构建期间同步修改 provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(homeProvider.notifier).loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);

    if (home.loading) return const Scaffold(body: AppLoading());
    if (home.error != null) {
      return Scaffold(
        body: AppErrorView(
          message: home.error!,
          onRetry: () => ref.read(homeProvider.notifier).loadHomeData(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.read(homeProvider.notifier).loadHomeData(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const HomeHeader(),
              const SizedBox(height: AppDimens.spaceMd),
              BannerSlider(banners: home.banners),
              const SizedBox(height: AppDimens.spaceLg),
              CategoryGrid(categories: home.categories),
              const SizedBox(height: AppDimens.spaceLg),
              CourseSection(
                title: '精选课程',
                courses: home.featuredCourses,
              ),
              ...home.sectionCourses.entries.map((entry) {
                // 找到该分类的名字；分类已删除则跳过
                Category? matched;
                for (final c in home.categories) {
                  if (c.id == entry.key) {
                    matched = c;
                    break;
                  }
                }
                if (matched == null || entry.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return CourseSection(
                  title: matched.name,
                  courses: entry.value,
                );
              }),
              const SizedBox(height: AppDimens.spaceXxl),
            ],
          ),
        ),
      ),
    );
  }
}
