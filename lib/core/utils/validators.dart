/// 表单校验工具
class Validators {
  Validators._();

  /// 校验手机号：11 位，1 开头
  static String? validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '请输入手机号';
    if (!RegExp(r'^1\d{10}$').hasMatch(v)) return '手机号格式不正确';
    return null;
  }

  /// 校验密码：6~20 位
  static String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return '请输入密码';
    if (v.length < 6 || v.length > 20) return '密码长度为 6~20 位';
    return null;
  }

  /// 校验验证码：4~6 位数字
  static String? validateSmsCode(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '请输入验证码';
    if (!RegExp(r'^\d{4,6}$').hasMatch(v)) return '验证码格式不正确';
    return null;
  }
}
