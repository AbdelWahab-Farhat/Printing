// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Customer _$CustomerFromJson(Map<String, dynamic> json) => _Customer(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  isActive: json['is_active'] as bool,
  shops: (json['shops'] as List<dynamic>?)
      ?.map((e) => CustomerShop.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'phone': instance.phone,
  'is_active': instance.isActive,
  'shops': instance.shops?.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

_CustomerShop _$CustomerShopFromJson(Map<String, dynamic> json) =>
    _CustomerShop(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      pageUrl: json['page_url'] as String?,
      businessFieldId: (json['business_field_id'] as num?)?.toInt(),
      businessField: json['business_field'] == null
          ? null
          : BusinessField.fromJson(
              json['business_field'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CustomerShopToJson(_CustomerShop instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'page_url': instance.pageUrl,
      'business_field_id': instance.businessFieldId,
      'business_field': instance.businessField?.toJson(),
    };
