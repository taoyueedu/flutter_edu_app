// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Teacher _$TeacherFromJson(Map<String, dynamic> json) => Teacher(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TeacherToJson(Teacher instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'title': instance.title,
  'description': instance.description,
  'courseCount': instance.courseCount,
};
