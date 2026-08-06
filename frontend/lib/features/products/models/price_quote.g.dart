// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PriceQuote _$PriceQuoteFromJson(Map<String, dynamic> json) => _PriceQuote(
  quantity: json['quantity'] as String,
  unit: json['unit'] as String,
  unitLabel: json['unit_label'] as String,
  unitPrice: json['unit_price'] as String,
  total: json['total'] as String,
  appliedTierMinQuantity: json['applied_tier_min_quantity'] as String,
  nextTier: json['next_tier'] == null
      ? null
      : NextPriceTier.fromJson(json['next_tier'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PriceQuoteToJson(_PriceQuote instance) =>
    <String, dynamic>{
      'quantity': instance.quantity,
      'unit': instance.unit,
      'unit_label': instance.unitLabel,
      'unit_price': instance.unitPrice,
      'total': instance.total,
      'applied_tier_min_quantity': instance.appliedTierMinQuantity,
      'next_tier': instance.nextTier?.toJson(),
    };

_NextPriceTier _$NextPriceTierFromJson(Map<String, dynamic> json) =>
    _NextPriceTier(
      minQuantity: json['min_quantity'] as String,
      unitPrice: json['unit_price'] as String,
      quantityToReach: json['quantity_to_reach'] as String,
    );

Map<String, dynamic> _$NextPriceTierToJson(_NextPriceTier instance) =>
    <String, dynamic>{
      'min_quantity': instance.minQuantity,
      'unit_price': instance.unitPrice,
      'quantity_to_reach': instance.quantityToReach,
    };
