// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shop _$ShopFromJson(Map<String, dynamic> json) => _Shop(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  cityId: (json['city_id'] as num).toInt(),
  cityName: json['city_name'] as String?,
  regionId: (json['region_id'] as num?)?.toInt(),
  regionName: json['region_name'] as String?,
  businessFieldId: (json['business_field_id'] as num?)?.toInt(),
  businessFieldName: json['business_field_name'] as String?,
  pageUrl: json['page_url'] as String?,
);

Map<String, dynamic> _$ShopToJson(_Shop instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'city_id': instance.cityId,
  'city_name': instance.cityName,
  'region_id': instance.regionId,
  'region_name': instance.regionName,
  'business_field_id': instance.businessFieldId,
  'business_field_name': instance.businessFieldName,
  'page_url': instance.pageUrl,
};

_BusinessField _$BusinessFieldFromJson(Map<String, dynamic> json) =>
    _BusinessField(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$BusinessFieldToJson(_BusinessField instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
