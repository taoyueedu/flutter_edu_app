import 'package:dio/dio.dart';

import '../constants/app_config.dart';
import '../storage/sp_util.dart';
import '../utils/logger.dart';
import 'api_result.dart';

/// 统一的网络客户端（单例）
/// 职责：
/// 1. 全局 Dio 配置（baseUrl / 超时）
/// 2. 请求拦截：自动附加 Token
/// 3. 响应拦截：统一日志、统一错误处理
/// 4. 对外提供 get/post 方法，返回 ApiResult
class ApiClient {
  // 私有命名构造函数 `_internal` 禁止外部实例化
  ApiClient._internal() {
    // 在构造函数中初始化dio实例
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(seconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
      ),
    );
    // 给dio实例添加拦截器：请求拦截器
    _dio.interceptors.add(_buildRequestInterceptor());
    // 响应拦截器 
    _dio.interceptors.add(_buildResponseInterceptor());
  }

  // ---------- 单例 ----------
  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  // ---------- 请求拦截器：附加 Token ----------
  Interceptor _buildRequestInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = SpUtil.getString(AppConfig.tokenKey);
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        Logger.log('请求: ${options.method} ${options.uri}');
        handler.next(options);
      },
    );
  }

  // ---------- 响应拦截器：统一处理 ----------
  Interceptor _buildResponseInterceptor() {
    return InterceptorsWrapper(
      onError: (e, handler) {
        // 网络层错误（超时、断网、4xx/5xx）
        final message = _resolveError(e);
        Logger.log('请求失败: $message');
        handler.next(e);
      },
    );
  }

  String _resolveError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '网络超时，请稍后重试';
      case DioExceptionType.connectionError:
        return '无法连接服务器，请检查网络';
      case DioExceptionType.badResponse:
        return '服务器异常（${e.response?.statusCode}）';
      default:
        return '网络错误，请稍后重试';
    }
  }

  // ---------- 对外方法 ----------

  /// GET 请求，返回解析后的 ApiResult
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T? Function(dynamic data)? transform,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      final body = resp.data ?? const {};
      return ApiResult<T>.fromJson(body, transform: transform);
    } on DioException catch (e) {
      return ApiResult<T>(code: -1, message: _resolveError(e));
    } catch (e) {
      Logger.log('未处理异常: $e');
      return ApiResult<T>(code: -1, message: '数据解析失败');
    }
  }

  /// POST 请求（请求体为 JSON）
  Future<ApiResult<T>> post<T>(
    String path, {
    Object? body,
    T? Function(dynamic data)? transform,
  }) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
      );
      final result = resp.data ?? const {};
      return ApiResult<T>.fromJson(result, transform: transform);
    } on DioException catch (e) {
      return ApiResult<T>(code: -1, message: _resolveError(e));
    } catch (e) {
      Logger.log('未处理异常: $e');
      return ApiResult<T>(code: -1, message: '数据解析失败');
    }
  }
}