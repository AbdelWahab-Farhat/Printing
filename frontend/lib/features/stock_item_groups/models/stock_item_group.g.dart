// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_item_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockItemGroup _$StockItemGroupFromJson(Map<String, dynamic> json) =>
    _StockItemGroup(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      defaultUnit: $enumDecode(
        _$StockUnitEnumMap,
        json['default_unit'],
        unknownValue: StockUnit.unknown,
      ),
      defaultUnitLabel: json['default_unit_label'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool,
      sortOrder: (json['sort_order'] as num).toInt(),
      itemsCount: (json['items_count'] as num?)?.toInt(),
      productsCount: (json['products_count'] as num?)?.toInt(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => StockItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StockItem>[],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$StockItemGroupToJson(_StockItemGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'default_unit': _$StockUnitEnumMap[instance.defaultUnit]!,
      'default_unit_label': instance.defaultUnitLabel,
      'description': instance.description,
      'is_active': instance.isActive,
      'sort_order': instance.sortOrder,
      'items_count': instance.itemsCount,
      'products_count': instance.productsCount,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$StockUnitEnumMap = {
  StockUnit.piece: 'piece',
  StockUnit.kilogram: 'kilogram',
  StockUnit.unknown: 'unknown',
};
