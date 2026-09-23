// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_orders.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PeriodInvestorShare _$PeriodInvestorShareFromJson(Map<String, dynamic> json) =>
    _PeriodInvestorShare(
      investorId: (json['investor_id'] as num).toInt(),
      name: json['name'] as String,
      amount: json['amount'] as String,
    );

Map<String, dynamic> _$PeriodInvestorShareToJson(
  _PeriodInvestorShare instance,
) => <String, dynamic>{
  'investor_id': instance.investorId,
  'name': instance.name,
  'amount': instance.amount,
};

_PeriodOrder _$PeriodOrderFromJson(Map<String, dynamic> json) => _PeriodOrder(
  orderId: (json['order_id'] as num).toInt(),
  code: json['code'] as String,
  status: json['status'] as String,
  statusLabel: json['status_label'] as String,
  customerName: json['customer_name'] as String?,
  occurredAt: json['occurred_at'] == null
      ? null
      : DateTime.parse(json['occurred_at'] as String),
  grandTotal: json['grand_total'] as String,
  investorsTotal: json['investors_total'] as String,
  investors:
      (json['investors'] as List<dynamic>?)
          ?.map((e) => PeriodInvestorShare.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PeriodInvestorShare>[],
);

Map<String, dynamic> _$PeriodOrderToJson(_PeriodOrder instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'code': instance.code,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'customer_name': instance.customerName,
      'occurred_at': instance.occurredAt?.toIso8601String(),
      'grand_total': instance.grandTotal,
      'investors_total': instance.investorsTotal,
      'investors': instance.investors.map((e) => e.toJson()).toList(),
    };

_PeriodOrdersTotals _$PeriodOrdersTotalsFromJson(Map<String, dynamic> json) =>
    _PeriodOrdersTotals(
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      investorsTotal: json['investors_total'] as String? ?? '0.00',
    );

Map<String, dynamic> _$PeriodOrdersTotalsToJson(_PeriodOrdersTotals instance) =>
    <String, dynamic>{
      'orders': instance.orders,
      'investors_total': instance.investorsTotal,
    };

_PeriodOrders _$PeriodOrdersFromJson(Map<String, dynamic> json) =>
    _PeriodOrders(
      period: FundPeriod.fromJson(json['period'] as Map<String, dynamic>),
      orders:
          (json['orders'] as List<dynamic>?)
              ?.map((e) => PeriodOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PeriodOrder>[],
      investors:
          (json['investors'] as List<dynamic>?)
              ?.map(
                (e) => PeriodInvestorShare.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <PeriodInvestorShare>[],
      totals: json['totals'] == null
          ? const PeriodOrdersTotals()
          : PeriodOrdersTotals.fromJson(json['totals'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PeriodOrdersToJson(_PeriodOrders instance) =>
    <String, dynamic>{
      'period': instance.period.toJson(),
      'orders': instance.orders.map((e) => e.toJson()).toList(),
      'investors': instance.investors.map((e) => e.toJson()).toList(),
      'totals': instance.totals.toJson(),
    };
