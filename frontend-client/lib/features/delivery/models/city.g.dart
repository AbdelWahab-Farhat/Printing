// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Region _$RegionFromJson(Map<String, dynamic> json) => _Region(
  id: (json['id'] as num).toInt(),
  cityId: (json['city_id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$RegionToJson(_Region instance) => <String, dynamic>{
  'id': instance.id,
  'city_id': instance.cityId,
  'name': instance.name,
};

_City _$CityFromJson(Map<String, dynamic> json) => _City(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  fulfilmentType: json['fulfilment_type'] as String?,
  fulfilmentTypeLabel: json['fulfilment_type_label'] as String?,
  isOfficePickup: json['is_office_pickup'] as bool? ?? false,
  isRegionRequired: json['is_region_required'] as bool? ?? false,
  deliveryPrice: json['delivery_price'] as String?,
  regions:
      (json['regions'] as List<dynamic>?)
          ?.map((e) => Region.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Region>[],
);

Map<String, dynamic> _$CityToJson(_City instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'fulfilment_type': instance.fulfilmentType,
  'fulfilment_type_label': instance.fulfilmentTypeLabel,
  'is_office_pickup': instance.isOfficePickup,
  'is_region_required': instance.isRegionRequired,
  'delivery_price': instance.deliveryPrice,
  'regions': instance.regions.map((e) => e.toJson()).toList(),
};
