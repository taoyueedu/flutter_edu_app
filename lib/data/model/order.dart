import 'package:flutter_edu_app/data/model/course.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final String orderNo;       // 订单号
  final List<Course> courses; // 关联课程
  final double totalAmount;   // 总价
  final int status;           // 0=待支付 1=已支付 2=已取消
  final String createdAt;

  Order({
    required this.orderNo,
    required this.courses,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);

  String get statusText => switch (status) {
        0 => '待支付',
        1 => '已支付',
        2 => '已取消',
        _ => '未知',
      };
}