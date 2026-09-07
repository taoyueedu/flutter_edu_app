/// 统一响应包装：解析后端 {code, message, data} 
class ApiResult<T> {
  final int code;
  final String message;
  final T? data;

  ApiResult({required this.code, required this.message, this.data});

  /// 是否成功（code == 0）
  bool get isSuccess => code == 0;

  /// 从原始 JSON 构造。T 的转换逻辑由调用方传入（dataJson）提供
  factory ApiResult.fromJson(
    Map<String, dynamic> json, {
    T? Function(dynamic dataJson)? transform,
  }) {
    return ApiResult<T>(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String? ?? '未知错误',
      data: transform?.call(json['data']),
    );
  }
}