import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../data/model/course.dart';

/// 通用课程卡片（横向：左图右文）
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const CourseCard({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceLg,
          vertical: AppDimens.spaceSm,
        ),
        padding: const EdgeInsets.all(AppDimens.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Row(
          children: [
            // 左：封面图
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: SizedBox(
                width: 110,
                height: 72,
                child: CachedNetworkImage(
                  imageUrl: course.coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: AppColors.bgInput,
                    child: const Icon(Icons.image, color: AppColors.textMuted),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.bgInput,
                    child: const Icon(Icons.broken_image,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimens.spaceMd),
            // 右：信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  const SizedBox(height: AppDimens.spaceXs),
                  Row(
                    children: [
                      const Icon(Icons.person,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Text(
                        course.teacherName ?? '官方讲师',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${course.studentCount}人已学',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spaceXs),
                  Row(
                    children: [
                      Text(
                        course.priceText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.price,
                        ),
                      ),
                      const SizedBox(width: AppDimens.spaceSm),
                      if (course.originalPrice > course.price)
                        Text(
                          '¥${course.originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
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
