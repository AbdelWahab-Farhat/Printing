// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basket_quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BasketQuote _$BasketQuoteFromJson(Map<String, dynamic> json) => _BasketQuote(
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => BasketLineQuote.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BasketLineQuote>[],
  itemsTotal: json['items_total'] as String?,
  deliveryPrice: json['delivery_price'] as String?,
  totalWithDelivery: json['total_with_delivery'] as String?,
);

Map<String, dynamic> _$BasketQuoteToJson(_BasketQuote instance) =>
    <String, dynamic>{
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'items_total': instance.itemsTotal,
      'delivery_price': instance.deliveryPrice,
      'total_with_delivery': instance.totalWithDelivery,
    };

_BasketLineQuote _$BasketLineQuoteFromJson(Map<String, dynamic> json) =>
    _BasketLineQuote(
      productId: (json['product_id'] as num).toInt(),
      productVariantId: (json['product_variant_id'] as num).toInt(),
      unitLabel: json['unit_label'] as String?,
      unitPrice: json['unit_price'] as String?,
      lineTotal: json['line_total'] as String?,
    );

Map<String, dynamic> _$BasketLineQuoteToJson(_BasketLineQuote instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'product_variant_id': instance.productVariantId,
      'unit_label': instance.unitLabel,
      'unit_price': instance.unitPrice,
      'line_total': instance.lineTotal,
    };
