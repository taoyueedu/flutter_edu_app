import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/order.dart';
import '../../data/repository/order_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_states.dart';

/// 模拟支付页（真实项目在此接微信/支付宝 SDK）
class PayPage extends StatefulWidget {
  final String orderNo;

  const PayPage({super.key, required this.orderNo});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  Order? _order;
  bool _loading = true;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = locator<OrderRepository>();
    final order = await repository.fetchOrderDetail(widget.orderNo);
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
    });
  }

  /// 模拟支付成功：跳订单详情
  Future<void> _pay() async {
    setState(() => _paying = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _paying = false);
    context.pushReplacement('/order/${widget.orderNo}');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AppLoading());

    final order = _order;
    return Scaffold(
      appBar: AppBar(title: const Text('收银台')),
      body: order == null
          ? const Center(child: Text('订单不存在'))
          : Padding(
              padding: const EdgeInsets.all(AppDimens.spaceXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimens.spaceXl),
                  const Icon(Icons.account_balance_wallet,
                      size: 64, color: AppColors.brand),
                  const SizedBox(height: AppDimens.spaceLg),
                  Center(
                    child: Text(
                      '¥${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceSm),
                  Center(
                    child: Text(
                      '订单号：${order.orderNo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceXxl),
                  Container(
                    padding: const EdgeInsets.all(AppDimens.spaceLg),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wechat, color: Color(0xFF07C160)),
                        SizedBox(width: AppDimens.spaceMd),
                        Text(
                          '微信支付（模拟）',
                          style: TextStyle(fontSize: 15),
                        ),
                        Spacer(),
                        Icon(Icons.check_circle,
                            color: AppColors.brand, size: 20),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    text: '立即支付',
                    loading: _paying,
                    onPressed: _paying ? null : _pay,
                  ),
                ],
              ),
            ),
    );
  }
}
