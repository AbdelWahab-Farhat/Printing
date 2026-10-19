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
  deposit: json['deposit'] == null
      ? const DepositOffer()
      : DepositOffer.fromJson(json['deposit'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BasketQuoteToJson(_BasketQuote instance) =>
    <String, dynamic>{
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'items_total': instance.itemsTotal,
      'delivery_price': instance.deliveryPrice,
      'total_with_delivery': instance.totalWithDelivery,
      'deposit': instance.deposit.toJson(),
    };

_DepositOffer _$DepositOfferFromJson(Map<String, dynamic> json) =>
    _DepositOffer(
      offered: json['offered'] as bool? ?? false,
      minPercent: (json['min_percent'] as num?)?.toInt() ?? 25,
      minAmount: json['min_amount'] as String?,
      maxAmount: json['max_amount'] as String?,
    );

Map<String, dynamic> _$DepositOfferToJson(_DepositOffer instance) =>
    <String, dynamic>{
      'offered': instance.offered,
      'min_percent': instance.minPercent,
      'min_amount': instance.minAmount,
      'max_amount': instance.maxAmount,
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
