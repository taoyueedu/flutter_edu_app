// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  orderNo: json['orderNo'] as String,
  courses: (json['courses'] as List<dynamic>)
      .map((e) => Course.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  status: (json['status'] as num).toInt(),
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'orderNo': instance.orderNo,
  'courses': instance.courses,
  'totalAmount': instance.totalAmount,
  'status': instance.status,
  'createdAt': instance.createdAt,
};
