// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockItem _$StockItemFromJson(Map<String, dynamic> json) => _StockItem(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  name: json['name'] as String,
  widthCm: (json['width_cm'] as num?)?.toInt(),
  heightCm: (json['height_cm'] as num?)?.toInt(),
  stockItemGroupId: (json['stock_item_group_id'] as num?)?.toInt(),
  group: json['stock_item_group'] == null
      ? null
      : StockItemGroupRef.fromJson(
          json['stock_item_group'] as Map<String, dynamic>,
        ),
  displayName: json['display_name'] as String,
  unit: $enumDecode(
    _$StockUnitEnumMap,
    json['unit'],
    unknownValue: StockUnit.unknown,
  ),
  unitLabel: json['unit_label'] as String,
  description: json['description'] as String?,
  isActive: json['is_active'] as bool,
  sortOrder: (json['sort_order'] as num).toInt(),
  variantsCount: (json['variants_count'] as num?)?.toInt(),
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => StockItemVariantRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <StockItemVariantRef>[],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$StockItemToJson(_StockItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'width_cm': instance.widthCm,
      'height_cm': instance.heightCm,
      'stock_item_group_id': instance.stockItemGroupId,
      'stock_item_group': instance.group?.toJson(),
      'display_name': instance.displayName,
      'unit': _$StockUnitEnumMap[instance.unit]!,
      'unit_label': instance.unitLabel,
      'description': instance.description,
      'is_active': instance.isActive,
      'sort_order': instance.sortOrder,
      'variants_count': instance.variantsCount,
      'variants': instance.variants.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$StockUnitEnumMap = {
  StockUnit.piece: 'piece',
  StockUnit.kilogram: 'kilogram',
  StockUnit.unknown: 'unknown',
};

_StockItemVariantRef _$StockItemVariantRefFromJson(Map<String, dynamic> json) =>
    _StockItemVariantRef(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String,
      widthCm: (json['width_cm'] as num?)?.toInt(),
      heightCm: (json['height_cm'] as num?)?.toInt(),
      isActive: json['is_active'] as bool? ?? true,
      product: json['product'] == null
          ? null
          : StockItemVariantProductRef.fromJson(
              json['product'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$StockItemVariantRefToJson(
  _StockItemVariantRef instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'width_cm': instance.widthCm,
  'height_cm': instance.heightCm,
  'is_active': instance.isActive,
  'product': instance.product?.toJson(),
};

_StockItemVariantProductRef _$StockItemVariantProductRefFromJson(
  Map<String, dynamic> json,
) => _StockItemVariantProductRef(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$StockItemVariantProductRefToJson(
  _StockItemVariantProductRef instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

_StockItemGroupRef _$StockItemGroupRefFromJson(Map<String, dynamic> json) =>
    _StockItemGroupRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$StockItemGroupRefToJson(_StockItemGroupRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };
