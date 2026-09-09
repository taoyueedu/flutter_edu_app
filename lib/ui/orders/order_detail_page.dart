import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/order.dart';
import '../../data/repository/order_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_states.dart';

/// 订单详情页
class OrderDetailPage extends StatefulWidget {
  final String orderNo;

  const OrderDetailPage({super.key, required this.orderNo});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = locator<OrderRepository>();
    final order = await repository.fetchOrderDetail(widget.orderNo);
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
      _error = order == null ? '订单不存在' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AppLoading());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('订单详情')),
        body: AppErrorView(message: _error!, onRetry: _load),
      );
    }

    final order = _order!;
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.spaceXl),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            ),
            child: Row(
              children: [
                Icon(
                  order.status == 1 ? Icons.check_circle : Icons.pending,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(width: AppDimens.spaceMd),
                Text(
                  order.statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),
          _InfoCard(order: order),
          const SizedBox(height: AppDimens.spaceLg),
          if (order.status == 0)
            AppButton(
              text: '去支付',
              onPressed: () => context.push('/pay/${order.orderNo}'),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Order order;

  const _InfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        children: [
          for (final course in order.courses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      course.title,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    course.priceText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.price,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          _InfoRow(label: '订单号', value: order.orderNo),
          _InfoRow(label: '下单时间', value: order.createdAt),
          _InfoRow(
            label: '支付金额',
            value: '¥${order.totalAmount.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
