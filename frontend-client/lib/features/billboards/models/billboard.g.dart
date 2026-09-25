// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillboardProductTarget _$BillboardProductTargetFromJson(
  Map<String, dynamic> json,
) => BillboardProductTarget(
  productId: (json['product_id'] as num).toInt(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$BillboardProductTargetToJson(
  BillboardProductTarget instance,
) => <String, dynamic>{
  'product_id': instance.productId,
  'type': instance.$type,
};

BillboardUrlTarget _$BillboardUrlTargetFromJson(Map<String, dynamic> json) =>
    BillboardUrlTarget(
      url: json['url'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$BillboardUrlTargetToJson(BillboardUrlTarget instance) =>
    <String, dynamic>{'url': instance.url, 'type': instance.$type};

BillboardNoTarget _$BillboardNoTargetFromJson(Map<String, dynamic> json) =>
    BillboardNoTarget($type: json['type'] as String?);

Map<String, dynamic> _$BillboardNoTargetToJson(BillboardNoTarget instance) =>
    <String, dynamic>{'type': instance.$type};

_Billboard _$BillboardFromJson(Map<String, dynamic> json) => _Billboard(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  imageUrl: json['image_url'] as String,
  widthPx: (json['width_px'] as num?)?.toInt(),
  heightPx: (json['height_px'] as num?)?.toInt(),
  target: json['target'] == null
      ? const BillboardTarget.none()
      : BillboardTarget.fromJson(json['target'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BillboardToJson(_Billboard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image_url': instance.imageUrl,
      'width_px': instance.widthPx,
      'height_px': instance.heightPx,
      'target': instance.target.toJson(),
    };
