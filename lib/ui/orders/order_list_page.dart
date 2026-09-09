import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/order.dart';
import '../../data/repository/order_repository.dart';
import '../../widgets/app_states.dart';

/// 我的订单列表页
class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final OrderRepository _orderRepository = locator<OrderRepository>();

  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _orderRepository.fetchOrders();
    if (!mounted) return;
    setState(() {
      _orders = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AppLoading());

    return Scaffold(
      appBar: AppBar(title: const Text('我的订单')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _orders.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  AppEmptyView(message: '暂无订单，快去选购课程吧'),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppDimens.spaceLg),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return _OrderCard(
                    order: order,
                    onTap: () => context.push('/order/${order.orderNo}'),
                  );
                },
              ),
      ),
    );
  }
}

/// 订单卡片
class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        margin: const EdgeInsets.only(bottom: AppDimens.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '订单号：${order.orderNo}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  order.statusText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: order.status == 0
                        ? AppColors.warning
                        : order.status == 1
                            ? AppColors.success
                            : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spaceMd),
            for (final course in order.courses.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book,
                        size: 15, color: AppColors.brand),
                    const SizedBox(width: AppDimens.spaceSm),
                    Expanded(
                      child: Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (order.courses.length > 3)
              const Text(
                '...',
                style: TextStyle(color: AppColors.textMuted),
              ),
            const SizedBox(height: AppDimens.spaceMd),
            Row(
              children: [
                const Spacer(),
                Text(
                  '¥${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.price,
                  ),
                ),
                const SizedBox(width: AppDimens.spaceMd),
                if (order.status == 0)
                  OutlinedButton(
                    onPressed: () => context.push('/pay/${order.orderNo}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(72, 32),
                      foregroundColor: AppColors.brand,
                      side: const BorderSide(color: AppColors.brand),
                    ),
                    child: const Text('去支付'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
