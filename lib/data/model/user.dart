import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String phone;
  final String? nickname;
  final String? avatarUrl;

  User({required this.id, required this.phone, this.nickname, this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// 显示名：昵称优先，没有就用脱敏手机号
  String get displayName {
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    return phone.replaceRange(3, 7, '****');
  }
}