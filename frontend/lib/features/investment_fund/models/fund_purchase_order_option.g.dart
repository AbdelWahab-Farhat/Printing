// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_purchase_order_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FundPurchaseOrderOption _$FundPurchaseOrderOptionFromJson(
  Map<String, dynamic> json,
) => _FundPurchaseOrderOption(
  id: (json['id'] as num).toInt(),
  vendor: json['vendor'] as String?,
  orderDate: json['order_date'] as String?,
  receivedOn: json['received_on'] as String?,
  items:
      (json['items'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$FundPurchaseOrderOptionToJson(
  _FundPurchaseOrderOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'vendor': instance.vendor,
  'order_date': instance.orderDate,
  'received_on': instance.receivedOn,
  'items': instance.items,
};
