// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  subtitle: json['subtitle'] as String?,
  coverUrl: json['coverUrl'] as String? ?? '',
  price: (json['price'] as num?)?.toDouble() ?? 0,
  originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0,
  studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
  isFeatured: json['isFeatured'] as bool? ?? false,
  isLive: json['isLive'] as bool? ?? false,
  isTrainingCamp: json['isTrainingCamp'] as bool? ?? false,
  teacherId: (json['teacherId'] as num?)?.toInt(),
  teacherName: json['teacherName'] as String?,
  teacherAvatar: json['teacherAvatar'] as String?,
  description: json['description'] as String?,
  chapters: (json['chapters'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'coverUrl': instance.coverUrl,
  'price': instance.price,
  'originalPrice': instance.originalPrice,
  'studentCount': instance.studentCount,
  'isFeatured': instance.isFeatured,
  'isLive': instance.isLive,
  'isTrainingCamp': instance.isTrainingCamp,
  'teacherId': instance.teacherId,
  'teacherName': instance.teacherName,
  'teacherAvatar': instance.teacherAvatar,
  'description': instance.description,
  'chapters': instance.chapters,
};
