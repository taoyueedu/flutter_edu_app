import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';

/// 通用主按钮
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool filled;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = filled ? AppColors.brand : AppColors.bgInput;
    final fgColor = filled ? Colors.white : AppColors.textMain;

    return SizedBox(
      height: AppDimens.buttonHeight,
      child: FilledButton(
        onPressed: (loading || onPressed == null) ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
