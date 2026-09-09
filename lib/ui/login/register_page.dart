import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../core/utils/validators.dart';
import '../../data/repository/auth_repository.dart';
import '../../widgets/app_button.dart';

/// 注册页
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final phoneError = Validators.validatePhone(_phoneController.text);
    if (phoneError != null) return _toast(phoneError);

    final codeError = Validators.validateSmsCode(_smsCodeController.text);
    if (codeError != null) return _toast(codeError);

    final pwdError = Validators.validatePassword(_passwordController.text);
    if (pwdError != null) return _toast(pwdError);

    if (_passwordController.text != _confirmController.text) {
      return _toast('两次输入的密码不一致');
    }

    setState(() => _loading = true);
    final ok = await locator<AuthRepository>().register(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      smsCode: _smsCodeController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      _toast('注册成功，请登录');
      context.pop();
    } else {
      _toast('注册失败，请稍后重试');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceXl),
        child: Column(
          children: [
            const SizedBox(height: AppDimens.spaceLg),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: _decoration('请输入手机号', Icons.phone_android),
            ),
            const SizedBox(height: AppDimens.spaceMd),
            TextField(
              controller: _smsCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: _decoration('请输入验证码', Icons.sms_outlined),
            ),
            const SizedBox(height: AppDimens.spaceMd),
            TextField(
              controller: _passwordController,
              obscureText: true,
              maxLength: 20,
              decoration: _decoration('设置密码（6~20位）', Icons.lock_outline),
            ),
            const SizedBox(height: AppDimens.spaceMd),
            TextField(
              controller: _confirmController,
              obscureText: true,
              maxLength: 20,
              decoration: _decoration('确认密码', Icons.lock_outline),
            ),
            const SizedBox(height: AppDimens.spaceXl),
            AppButton(
              text: '注册',
              loading: _loading,
              onPressed: _loading ? null : _register,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textMuted),
      counterText: '',
    );
  }
}
