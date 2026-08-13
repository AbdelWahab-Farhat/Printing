// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manufacturing_cost_rate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ManufacturingCostRate _$ManufacturingCostRateFromJson(
  Map<String, dynamic> json,
) => _ManufacturingCostRate(
  id: (json['id'] as num).toInt(),
  product: json['product'] == null
      ? null
      : ArrivalRef.fromJson(json['product'] as Map<String, dynamic>),
  productVariant: json['product_variant'] == null
      ? null
      : RateVariant.fromJson(json['product_variant'] as Map<String, dynamic>),
  costType: $enumDecode(
    _$ManufacturingCostTypeEnumMap,
    json['cost_type'],
    unknownValue: ManufacturingCostType.unknown,
  ),
  costTypeLabel: json['cost_type_label'] as String,
  ratePerUnit: json['rate_per_unit'] as String,
  isActive: json['is_active'] as bool? ?? true,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ManufacturingCostRateToJson(
  _ManufacturingCostRate instance,
) => <String, dynamic>{
  'id': instance.id,
  'product': instance.product?.toJson(),
  'product_variant': instance.productVariant?.toJson(),
  'cost_type': _$ManufacturingCostTypeEnumMap[instance.costType]!,
  'cost_type_label': instance.costTypeLabel,
  'rate_per_unit': instance.ratePerUnit,
  'is_active': instance.isActive,
  'notes': instance.notes,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$ManufacturingCostTypeEnumMap = {
  ManufacturingCostType.labor: 'labor',
  ManufacturingCostType.machineRuntime: 'machine_runtime',
  ManufacturingCostType.overhead: 'overhead',
  ManufacturingCostType.scrapLoss: 'scrap_loss',
  ManufacturingCostType.unknown: 'unknown',
};

_RateVariant _$RateVariantFromJson(Map<String, dynamic> json) => _RateVariant(
  id: (json['id'] as num).toInt(),
  label: json['label'] as String,
);

Map<String, dynamic> _$RateVariantToJson(_RateVariant instance) =>
    <String, dynamic>{'id': instance.id, 'label': instance.label};
