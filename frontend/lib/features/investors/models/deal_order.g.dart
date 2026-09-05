// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deal_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DealOrder _$DealOrderFromJson(Map<String, dynamic> json) => _DealOrder(
  orderId: (json['order_id'] as num).toInt(),
  code: json['code'] as String,
  status: json['status'] as String,
  statusLabel: json['status_label'] as String,
  customerName: json['customer_name'] as String?,
  occurredAt: json['occurred_at'] == null
      ? null
      : DateTime.parse(json['occurred_at'] as String),
  grandTotal: json['grand_total'] as String,
  quantity: json['quantity'] as String,
  materialCost: json['material_cost'] as String,
  revenue: json['revenue'] as String,
  conversionCost: json['conversion_cost'] as String,
  profit: json['profit'] as String,
  investorsShare: json['investors_share'] as String?,
  companyShare: json['company_share'] as String?,
  isPosted: json['is_posted'] as bool? ?? false,
);

Map<String, dynamic> _$DealOrderToJson(_DealOrder instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'code': instance.code,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'customer_name': instance.customerName,
      'occurred_at': instance.occurredAt?.toIso8601String(),
      'grand_total': instance.grandTotal,
      'quantity': instance.quantity,
      'material_cost': instance.materialCost,
      'revenue': instance.revenue,
      'conversion_cost': instance.conversionCost,
      'profit': instance.profit,
      'investors_share': instance.investorsShare,
      'company_share': instance.companyShare,
      'is_posted': instance.isPosted,
    };
