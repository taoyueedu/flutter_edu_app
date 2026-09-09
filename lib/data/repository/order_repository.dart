import '../../core/network/api_client.dart';
import '../model/order.dart';

/// 订单仓库
class OrderRepository {
  final ApiClient _api = ApiClient.instance;

  /// 创建订单（下单）
  Future<Order?> createOrder(List<int> courseIds) async {
    final result = await _api.post<Order>(
      '/orders',
      body: {'course_ids': courseIds},
      transform: (d) =>
          d is Map<String, dynamic> ? Order.fromJson(d) : null,
    );
    return result.data;
  }

  /// 订单列表
  Future<List<Order>> fetchOrders() async {
    final result = await _api.get<List<Order>>(
      '/orders',
      transform: (d) => _toList(d, Order.fromJson),
    );
    return result.data ?? const [];
  }

  /// 订单详情
  Future<Order?> fetchOrderDetail(String orderNo) async {
    final result = await _api.get<Order>(
      '/orders/$orderNo',
      transform: (d) =>
          d is Map<String, dynamic> ? Order.fromJson(d) : null,
    );
    return result.data;
  }

  static List<T>? _toList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return null;
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}
