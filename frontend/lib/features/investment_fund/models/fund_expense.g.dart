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
    };
