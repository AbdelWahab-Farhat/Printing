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
      released: json['released'] as String? ?? '0.00',
      pending: json['pending'] as String? ?? '0.00',
      expected: json['expected'] as String? ?? '0.00',
    );

Map<String, dynamic> _$PeriodInvestorShareToJson(
  _PeriodInvestorShare instance,
) => <String, dynamic>{
  'investor_id': instance.investorId,
  'name': instance.name,
  'amount': instance.amount,
  'released': instance.released,
  'pending': instance.pending,
  'expected': instance.expected,
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
  profitState: $enumDecodeNullable(
    _$PeriodProfitStateEnumMap,
    json['profit_state'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  profitStateLabel: json['profit_state_label'] as String?,
  states:
      (json['states'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$PeriodProfitStateEnumMap, e))
          .toList() ??
      const <PeriodProfitState>[],
  byState: json['by_state'] == null
      ? null
      : PeriodOrderByState.fromJson(json['by_state'] as Map<String, dynamic>),
  uncollected: json['uncollected'] as bool? ?? false,
  expectedInvestors:
      (json['expected_investors'] as List<dynamic>?)
          ?.map((e) => PeriodInvestorShare.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PeriodInvestorShare>[],
);

Map<String, dynamic> _$PeriodOrderToJson(
  _PeriodOrder instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'code': instance.code,
  'status': instance.status,
  'status_label': instance.statusLabel,
  'customer_name': instance.customerName,
  'occurred_at': instance.occurredAt?.toIso8601String(),
  'grand_total': instance.grandTotal,
  'investors_total': instance.investorsTotal,
  'investors': instance.investors.map((e) => e.toJson()).toList(),
  'profit_state': _$PeriodProfitStateEnumMap[instance.profitState],
  'profit_state_label': instance.profitStateLabel,
  'states': instance.states.map((e) => _$PeriodProfitStateEnumMap[e]!).toList(),
  'by_state': instance.byState?.toJson(),
  'uncollected': instance.uncollected,
  'expected_investors': instance.expectedInvestors
      .map((e) => e.toJson())
      .toList(),
};

const _$PeriodProfitStateEnumMap = {
  PeriodProfitState.awaitingDelivery: 'awaiting_delivery',
  PeriodProfitState.awaitingPayment: 'awaiting_payment',
  PeriodProfitState.awaitingPeriodEnd: 'awaiting_period_end',
  PeriodProfitState.released: 'released',
};

_PeriodOrderByState _$PeriodOrderByStateFromJson(Map<String, dynamic> json) =>
    _PeriodOrderByState(
      released: json['released'] as String? ?? '0.00',
      awaitingPayment: json['awaiting_payment'] as String? ?? '0.00',
      awaitingPeriodEnd: json['awaiting_period_end'] as String? ?? '0.00',
      awaitingDelivery: json['awaiting_delivery'] as String?,
    );

Map<String, dynamic> _$PeriodOrderByStateToJson(_PeriodOrderByState instance) =>
    <String, dynamic>{
      'released': instance.released,
      'awaiting_payment': instance.awaitingPayment,
      'awaiting_period_end': instance.awaitingPeriodEnd,
      'awaiting_delivery': instance.awaitingDelivery,
    };

_PeriodStateTotal _$PeriodStateTotalFromJson(Map<String, dynamic> json) =>
    _PeriodStateTotal(
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      amount: json['amount'] as String? ?? '0.00',
      unpriced: (json['unpriced'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PeriodStateTotalToJson(_PeriodStateTotal instance) =>
    <String, dynamic>{
      'orders': instance.orders,
      'amount': instance.amount,
      'unpriced': instance.unpriced,
    };

_PeriodStatesTotals _$PeriodStatesTotalsFromJson(Map<String, dynamic> json) =>
    _PeriodStatesTotals(
      released: json['released'] == null
          ? const PeriodStateTotal()
          : PeriodStateTotal.fromJson(json['released'] as Map<String, dynamic>),
      awaitingPayment: json['awaiting_payment'] == null
          ? const PeriodStateTotal()
          : PeriodStateTotal.fromJson(
              json['awaiting_payment'] as Map<String, dynamic>,
            ),
      awaitingPeriodEnd: json['awaiting_period_end'] == null
          ? const PeriodStateTotal()
          : PeriodStateTotal.fromJson(
              json['awaiting_period_end'] as Map<String, dynamic>,
            ),
      awaitingDelivery: json['awaiting_delivery'] == null
          ? const PeriodStateTotal()
          : PeriodStateTotal.fromJson(
              json['awaiting_delivery'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PeriodStatesTotalsToJson(_PeriodStatesTotals instance) =>
    <String, dynamic>{
      'released': instance.released.toJson(),
      'awaiting_payment': instance.awaitingPayment.toJson(),
      'awaiting_period_end': instance.awaitingPeriodEnd.toJson(),
      'awaiting_delivery': instance.awaitingDelivery.toJson(),
    };

_PeriodOrdersTotals _$PeriodOrdersTotalsFromJson(Map<String, dynamic> json) =>
    _PeriodOrdersTotals(
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      investorsTotal: json['investors_total'] as String? ?? '0.00',
      byState: json['by_state'] == null
          ? const PeriodStatesTotals()
          : PeriodStatesTotals.fromJson(
              json['by_state'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PeriodOrdersTotalsToJson(_PeriodOrdersTotals instance) =>
    <String, dynamic>{
      'orders': instance.orders,
      'investors_total': instance.investorsTotal,
      'by_state': instance.byState.toJson(),
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
