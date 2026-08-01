// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_City _$CityFromJson(Map<String, dynamic> json) => _City(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  isRegionRequired: json['is_region_required'] as bool,
  deliveryPrice: json['delivery_price'] as String?,
  darbBranch: json['darb_branch'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  regionsCount: (json['regions_count'] as num?)?.toInt(),
  regions: (json['regions'] as List<dynamic>?)
      ?.map((e) => Region.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CityToJson(_City instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'is_region_required': instance.isRegionRequired,
  'delivery_price': instance.deliveryPrice,
  'darb_branch': instance.darbBranch,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'regions_count': instance.regionsCount,
  'regions': instance.regions?.map((e) => e.toJson()).toList(),
};

_Region _$RegionFromJson(Map<String, dynamic> json) => _Region(
  id: (json['id'] as num).toInt(),
  cityId: (json['city_id'] as num).toInt(),
  name: json['name'] as String,
  code: json['code'] as String?,
  darbBranch: json['darb_branch'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$RegionToJson(_Region instance) => <String, dynamic>{
  'id': instance.id,
  'city_id': instance.cityId,
  'name': instance.name,
  'code': instance.code,
  'darb_branch': instance.darbBranch,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
