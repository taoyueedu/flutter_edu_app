import 'package:json_annotation/json_annotation.dart';

part 'banner.g.dart';

@JsonSerializable()
class BannerModel {
  final int id;
  final String title;
  final String imageUrl;
  final String? linkType;   // course / teacher / none
  final int? linkId;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkType,
    this.linkId,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);

  Map<String, dynamic> toJson() => _$BannerModelToJson(this);
}