import 'package:json_annotation/json_annotation.dart';

part 'teacher.g.dart';

@JsonSerializable()
class Teacher {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? title;        // 头衔
  final String? description;  // 简介
  final int courseCount;

  Teacher({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.title,
    this.description,
    this.courseCount = 0,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) =>
      _$TeacherFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherToJson(this);
}