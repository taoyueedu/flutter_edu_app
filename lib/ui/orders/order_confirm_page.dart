import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/di.dart';
import '../../data/model/course.dart';
import '../../data/repository/course_repository.dart';
import '../../data/repository/order_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_states.dart';

/// 确认订单页
class OrderConfirmPage extends StatefulWidget {
  final List<int> courseIds;

  const OrderConfirmPage({super.key, required this.courseIds});

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  final OrderRepository _orderRepository = locator<OrderRepository>();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courseRepository = locator<CourseRepository>();
    final list = <Course>[];
    for (final id in widget.courseIds) {
      final course = await courseRepository.fetchCourseDetail(id);
      if (course != null) list.add(course);
    }
    if (!mounted) return;
    setState(() {
      _courses = list;
      _loading = false;
      if (list.isEmpty) _error = '课程加载失败';
    });
  }

  double get _totalAmount => _courses.fold(0, (sum, c) => sum + c.price);

  Future<void> _submitOrder() async {
    setState(() => _submitting = true);
    final order = await _orderRepository.createOrder(widget.courseIds);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (order != null) {
      context.push('/pay/${order.orderNo}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下单失败，请稍后重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AppLoading());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('确认订单')),
        body: AppErrorView(message: _error!, onRetry: _loadCourses),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('确认订单')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            ),
            child: Column(
              children: [
                for (final course in _courses)
                  ListTile(
                    leading: const Icon(Icons.menu_book,
                        color: AppColors.brand),
                    title: Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Text(
                      course.priceText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.price,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceMd),
          Container(
            padding: const EdgeInsets.all(AppDimens.spaceLg),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            ),
            child: Row(
              children: [
                const Text(
                  '合计',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '¥${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.price,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceLg,
            vertical: AppDimens.spaceSm,
          ),
          child: AppButton(
            text: '提交订单（¥${_totalAmount.toStringAsFixed(2)}）',
            loading: _submitting,
            onPressed: _submitting ? null : _submitOrder,
          ),
        ),
      ),
    );
  }
}
