import 'package:flutter/material.dart';

/// 颜色设计令牌，全局唯一颜色来源。
/// 对应 Kotlin 版的 DesignTokens.kt
class AppColors {
  AppColors._(); // 禁止实例化（工具类规范）

  static const brand = Color(0xFF00C4D4);
  static const brandDark = Color(0xFF00A8B8);
  static const brandGradient = LinearGradient(colors: [brand, brandDark]);

  static const bgLight = Color(0xFFF5F5F7);
  static const bgCard = Colors.white;
  static const bgInput = Color(0xFFF2F3F7);

  static const textMain = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF4A4A6A);
  static const textMuted = Color(0xFF8B8BA0);

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const price = Color(0xFFE83929);
}