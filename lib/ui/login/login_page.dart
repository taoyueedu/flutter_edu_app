import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../core/utils/validators.dart';
import '../../data/repository/auth_repository.dart';
import '../../providers/login_provider.dart';
import '../../widgets/app_button.dart';

/// 登录页：密码登录 + 短信登录（Tab 切换）
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();

  int _mode = 0; // 0=密码登录 1=短信登录
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendSmsCode() async {
    final phoneError = Validators.validatePhone(_phoneController.text);
    if (phoneError != null) {
      _showToast(phoneError);
      return;
    }

    final ok =
        await locator<AuthRepository>().sendSmsCode(_phoneController.text);
    if (!mounted) return;
    if (ok) {
      _showToast('验证码已发送');
      _startCountdown();
    } else {
      _showToast('发送失败，请稍后重试');
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _login() async {
    final phoneError = Validators.validatePhone(_phoneController.text);
    if (phoneError != null) return _showToast(phoneError);

    final notifier = ref.read(loginProvider.notifier);
    final ok = _mode == 0
        ? await notifier.loginWithPassword(
            _phoneController.text.trim(),
            _passwordController.text,
          )
        : await notifier.loginWithSms(
            _phoneController.text.trim(),
            _smsCodeController.text.trim(),
          );

    if (!mounted) return;

    if (ok) {
      _showToast('登录成功');
      context.pop(true);
    } else {
      _showToast(ref.read(loginProvider).errorMessage ?? '登录失败');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    return Scaffold(
      backgroundColor: AppColors.bgCard,
      appBar: AppBar(title: const Text('登录')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimens.spaceXl),
            const Icon(Icons.school, size: 56, color: AppColors.brand),
            const SizedBox(height: AppDimens.spaceMd),
            const Text(
              '桃悦智科',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: AppDimens.spaceXs),
            const Text(
              '欢迎回来，继续学习',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimens.spaceXxl),

            Row(
              children: [
                _ModeTab(
                  label: '密码登录',
                  selected: _mode == 0,
                  onTap: () => setState(() => _mode = 0),
                ),
                const SizedBox(width: AppDimens.spaceXl),
                _ModeTab(
                  label: '短信登录',
                  selected: _mode == 1,
                  onTap: () => setState(() => _mode = 1),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spaceLg),

            _Input(
              controller: _phoneController,
              hint: '请输入手机号',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              maxLength: 11,
            ),
            const SizedBox(height: AppDimens.spaceMd),

            if (_mode == 0)
              _Input(
                controller: _passwordController,
                hint: '请输入密码',
                icon: Icons.lock_outline,
                obscure: true,
                maxLength: 20,
              )
            else
              _Input(
                controller: _smsCodeController,
                hint: '请输入验证码',
                icon: Icons.sms_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
                suffix: TextButton(
                  onPressed: _countdown > 0 ? null : _sendSmsCode,
                  child: Text(
                    _countdown > 0 ? '$_countdown 秒' : '获取验证码',
                    style: TextStyle(
                      color: _countdown > 0
                          ? AppColors.textMuted
                          : AppColors.brand,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppDimens.spaceXl),

            AppButton(
              text: '登录',
              loading: loginState.isLoading,
              onPressed: loginState.isLoading ? null : _login,
            ),
            const SizedBox(height: AppDimens.spaceMd),

            Center(
              child: Text(
                '未注册的手机号验证后将自动注册',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spaceXl),

            Center(
              child: TextButton(
                onPressed: () => context.push('/register'),
                child: const Text(
                  '没有账号？立即注册',
                  style: TextStyle(color: AppColors.brand),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Tab ----------
class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppColors.textMain : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 24 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 输入框 ----------
class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final int maxLength;
  final Widget? suffix;

  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.maxLength = 20,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: [
        if (keyboardType == TextInputType.phone ||
            keyboardType == TextInputType.number)
          FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        suffixIcon: suffix,
        counterText: '',
      ),
    );
  }
}
