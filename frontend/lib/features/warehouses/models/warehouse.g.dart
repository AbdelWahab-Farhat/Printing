// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Warehouse _$WarehouseFromJson(Map<String, dynamic> json) => _Warehouse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  type: $enumDecode(
    _$WarehouseTypeEnumMap,
    json['type'],
    unknownValue: WarehouseType.unknown,
  ),
  typeLabel: json['type_label'] as String,
  location: json['location'] as String?,
  stocksCount: (json['stocks_count'] as num?)?.toInt(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$WarehouseToJson(_Warehouse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$WarehouseTypeEnumMap[instance.type]!,
      'type_label': instance.typeLabel,
      'location': instance.location,
      'stocks_count': instance.stocksCount,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$WarehouseTypeEnumMap = {
  WarehouseType.main: 'main',
  WarehouseType.operational: 'operational',
  WarehouseType.showroom: 'showroom',
  WarehouseType.unknown: 'unknown',
};
