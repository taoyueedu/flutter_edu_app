import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../data/model/category.dart';

/// 分类宫格：4 列 × N 行
class CategoryGrid extends StatelessWidget {
  final List<Category> categories;

  const CategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.spaceLg),
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.9,
        children: List.generate(categories.length, (index) {
          final category = categories[index];
          return InkWell(
            onTap: () => context.push('/courses', extra: category),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.brand.withValues(alpha: 0.1),
                  child: Icon(
                    _categoryIcon(index),
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: AppDimens.spaceSm),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  IconData _categoryIcon(int index) {
    const icons = [
      Icons.computer,
      Icons.brush,
      Icons.music_note,
      Icons.fitness_center,
      Icons.language,
      Icons.business_center,
      Icons.psychology,
      Icons.camera_alt,
    ];
    return icons[index % icons.length];
  }
}
