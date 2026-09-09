import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';

/// 顶部品牌栏 + 搜索框（渐变背景）
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spaceLg,
        AppDimens.spaceLg,
        AppDimens.spaceLg,
        AppDimens.spaceLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 品牌行
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.brand,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimens.spaceSm),
              const Text(
                '桃悦智科',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.live_tv, color: Colors.white),
                onPressed: () => context.push('/live'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceLg),
          // 搜索框
          GestureDetector(
            onTap: () => context.push('/search'),
            child: Container(
              height: AppDimens.inputHeight,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.spaceMd),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.textMuted),
                  SizedBox(width: AppDimens.spaceSm),
                  Text(
                    '搜索感兴趣的课程',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
