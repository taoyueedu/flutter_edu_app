import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../providers/login_provider.dart';

/// 我的页（用户中心）
class MinePage extends ConsumerWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginProvider);
    final isLoggedIn = loginState.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _UserCard(
            isLoggedIn: isLoggedIn,
            nickname: loginState.user?.displayName,
            avatarUrl: loginState.user?.avatarUrl,
          ),

          Container(
            margin: const EdgeInsets.all(AppDimens.spaceLg),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            ),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: '我的订单',
                  onTap: () => context.push('/orders'),
                ),
                const _Divider(),
                _MenuItem(
                  icon: Icons.star_outline,
                  title: '我的收藏',
                  onTap: () => _notify(context, '收藏功能开发中'),
                ),
                const _Divider(),
                _MenuItem(
                  icon: Icons.school_outlined,
                  title: '学习记录',
                  onTap: () => _notify(context, '学习记录开发中'),
                ),
                const _Divider(),
                _MenuItem(
                  icon: Icons.card_giftcard_outlined,
                  title: '优惠券',
                  onTap: () => _notify(context, '优惠券功能开发中'),
                ),
                const _Divider(),
                _MenuItem(
                  icon: Icons.support_agent,
                  title: '联系客服',
                  onTap: () => _notify(context, '客服热线：400-000-0000'),
                ),
                const _Divider(),
                _MenuItem(
                  icon: Icons.info_outline,
                  title: '关于我们',
                  onTap: () => _notify(context, '桃悦智科 v1.0.0'),
                ),
              ],
            ),
          ),

          if (isLoggedIn) ...[
            const SizedBox(height: AppDimens.spaceLg),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.spaceLg),
              child: OutlinedButton(
                onPressed: () => _confirmLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                ),
                child: const Text('退出登录'),
              ),
            ),
          ],
          const SizedBox(height: AppDimens.spaceXxl),
        ],
      ),
    );
  }

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(loginProvider.notifier).logout();
              _notify(context, '已退出登录');
            },
            child:
                const Text('确定', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ---------- 用户信息卡 ----------
class _UserCard extends StatelessWidget {
  final bool isLoggedIn;
  final String? nickname;
  final String? avatarUrl;

  const _UserCard({
    required this.isLoggedIn,
    this.nickname,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceXl),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 36, color: AppColors.brand)
                : null,
          ),
          const SizedBox(width: AppDimens.spaceLg),
          Expanded(
            child: isLoggedIn
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname ?? '用户',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '学无止境，每天进步一点点',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => context.push('/login'),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '点击登录 / 注册',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '登录后畅享全部课程',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }
}

// ---------- 菜单项 ----------
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceLg,
          vertical: AppDimens.spaceLg,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppDimens.spaceMd),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMain,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ---------- 分割线 ----------
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: AppDimens.spaceLg + 32,
      endIndent: AppDimens.spaceLg,
      color: Color(0xFFEEEEF2),
    );
  }
}
