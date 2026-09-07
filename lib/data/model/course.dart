import 'package:json_annotation/json_annotation.dart';

part 'course.g.dart';

/// 课程模型
@JsonSerializable()
class Course {
  final int id;
  final String title;
  final String? subtitle;          // 副标题
  final String coverUrl;          // 封面图
  final double price;             // 价格
  final double originalPrice;     // 原价
  final int studentCount;         // 学习人数
  final bool isFeatured;          // 是否精选
  final bool isLive;              // 是否直播
  final bool isTrainingCamp;      // 是否训练营
  final int? teacherId;           // 讲师 ID
  final String? teacherName;      // 讲师名（列表页直接带过来）
  final String? teacherAvatar;
  final String? description;      // 详情页简介
  final List<String>? chapters;   // 章节大纲

  Course({
    required this.id,
    required this.title,
    this.subtitle,
    this.coverUrl = '',
    this.price = 0,
    this.originalPrice = 0,
    this.studentCount = 0,
    this.isFeatured = false,
    this.isLive = false,
    this.isTrainingCamp = false,
    this.teacherId,
    this.teacherName,
    this.teacherAvatar,
    this.description,
    this.chapters,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseToJson(this);

  /// 价格显示文案：¥9.9
  String get priceText => '¥${price.toStringAsFixed(1)}';
}