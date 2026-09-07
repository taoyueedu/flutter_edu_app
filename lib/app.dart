import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'router.dart';

class TaoyueEduApp extends StatelessWidget {
  const TaoyueEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ProviderScope 把整棵 widget 树包起来，所有 Provider 都能用
    return ProviderScope(
      child: MaterialApp.router(
        title: '桃悦智科',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.brand,
            primary: AppColors.brand,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.bgLight,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.bgCard,
            foregroundColor: AppColors.textMain,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        routerConfig: appRouter,   // go_router 路由表（见 10.4）
      ),
    );
  }
}