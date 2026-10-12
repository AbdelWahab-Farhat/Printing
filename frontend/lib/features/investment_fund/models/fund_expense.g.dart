// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FundExpensePeriod _$FundExpensePeriodFromJson(Map<String, dynamic> json) =>
    _FundExpensePeriod(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
    );

Map<String, dynamic> _$FundExpensePeriodToJson(_FundExpensePeriod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'status': instance.status,
      'status_label': instance.statusLabel,
    };

_FundExpensePurchaseOrder _$FundExpensePurchaseOrderFromJson(
  Map<String, dynamic> json,
) => _FundExpensePurchaseOrder(id: (json['id'] as num).toInt());

Map<String, dynamic> _$FundExpensePurchaseOrderToJson(
  _FundExpensePurchaseOrder instance,
) => <String, dynamic>{'id': instance.id};

_FundExpenseSplit _$FundExpenseSplitFromJson(Map<String, dynamic> json) =>
    _FundExpenseSplit(
      onGoods: json['on_goods'] as String,
      onSales: json['on_sales'] as String,
    );

Map<String, dynamic> _$FundExpenseSplitToJson(_FundExpenseSplit instance) =>
    <String, dynamic>{
      'on_goods': instance.onGoods,
      'on_sales': instance.onSales,
    };

_FundExpenseGoodsCost _$FundExpenseGoodsCostFromJson(
  Map<String, dynamic> json,
) => _FundExpenseGoodsCost(
  stockItemId: (json['stock_item_id'] as num).toInt(),
  name: json['name'] as String,
  unitLabel: json['unit_label'] as String?,
  quantity: json['quantity'] as String,
  costBefore: json['cost_before'] as String?,
  costAfter: json['cost_after'] as String?,
);

Map<String, dynamic> _$FundExpenseGoodsCostToJson(
  _FundExpenseGoodsCost instance,
) => <String, dynamic>{
  'stock_item_id': instance.stockItemId,
  'name': instance.name,
  'unit_label': instance.unitLabel,
  'quantity': instance.quantity,
  'cost_before': instance.costBefore,
  'cost_after': instance.costAfter,
};

_FundExpense _$FundExpenseFromJson(Map<String, dynamic> json) => _FundExpense(
  id: (json['id'] as num).toInt(),
  kind: json['kind'] as String,
  kindLabel: json['kind_label'] as String,
  name: json['name'] as String,
  amount: json['amount'] as String,
  incurredOn: json['incurred_on'] as String?,
  notes: json['notes'] as String?,
  treasuryAccount: json['treasury_account'] == null
      ? null
      : PeriodExpenseRef.fromJson(
          json['treasury_account'] as Map<String, dynamic>,
        ),
  recordedBy: json['recorded_by'] == null
      ? null
      : PeriodExpenseRef.fromJson(json['recorded_by'] as Map<String, dynamic>),
  period: json['period'] == null
      ? null
      : FundExpensePeriod.fromJson(json['period'] as Map<String, dynamic>),
  counted: json['counted'] as bool? ?? true,
  recordedAfterClose: json['recorded_after_close'] as bool? ?? false,
  isReversed: json['is_reversed'] as bool? ?? false,
  reversal: json['reversal'] == null
      ? null
      : PeriodExpenseReversal.fromJson(
          json['reversal'] as Map<String, dynamic>,
        ),
  expenseAmount: json['expense_amount'] as String?,
  purchaseOrder: json['purchase_order'] == null
      ? null
      : FundExpensePurchaseOrder.fromJson(
          json['purchase_order'] as Map<String, dynamic>,
        ),
  split: json['split'] == null
      ? null
      : FundExpenseSplit.fromJson(json['split'] as Map<String, dynamic>),
  goods:
      (json['goods'] as List<dynamic>?)
          ?.map((e) => FundExpenseGoodsCost.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FundExpenseGoodsCost>[],
);

Map<String, dynamic> _$FundExpenseToJson(_FundExpense instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'kind_label': instance.kindLabel,
      'name': instance.name,
      'amount': instance.amount,
      'incurred_on': instance.incurredOn,
      'notes': instance.notes,
      'treasury_account': instance.treasuryAccount?.toJson(),
      'recorded_by': instance.recordedBy?.toJson(),
      'period': instance.period?.toJson(),
      'counted': instance.counted,
      'recorded_after_close': instance.recordedAfterClose,
      'is_reversed': instance.isReversed,
      'reversal': instance.reversal?.toJson(),
      'expense_amount': instance.expenseAmount,
      'purchase_order': instance.purchaseOrder?.toJson(),
      'split': instance.split?.toJson(),
      'goods': instance.goods.map((e) => e.toJson()).toList(),
    };
