// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pool_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PoolExpense _$PoolExpenseFromJson(Map<String, dynamic> json) => _PoolExpense(
  id: (json['id'] as num).toInt(),
  investorDealId: (json['investor_deal_id'] as num).toInt(),
  investmentPeriodId: (json['investment_period_id'] as num?)?.toInt(),
  kind: json['kind'] as String,
  kindLabel: json['kind_label'] as String,
  name: json['name'] as String,
  amount: json['amount'] as String,
  isLanded: json['is_landed'] as bool? ?? false,
  isDeducted: json['is_deducted'] as bool? ?? true,
  incurredOn: json['incurred_on'] as String?,
  reversesExpenseId: (json['reverses_expense_id'] as num?)?.toInt(),
  isReversed: json['is_reversed'] as bool? ?? false,
  notes: json['notes'] as String?,
  recordedAt: json['recorded_at'] as String?,
);

Map<String, dynamic> _$PoolExpenseToJson(_PoolExpense instance) =>
    <String, dynamic>{
      'id': instance.id,
      'investor_deal_id': instance.investorDealId,
      'investment_period_id': instance.investmentPeriodId,
      'kind': instance.kind,
      'kind_label': instance.kindLabel,
      'name': instance.name,
      'amount': instance.amount,
      'is_landed': instance.isLanded,
      'is_deducted': instance.isDeducted,
      'incurred_on': instance.incurredOn,
      'reverses_expense_id': instance.reversesExpenseId,
      'is_reversed': instance.isReversed,
      'notes': instance.notes,
      'recorded_at': instance.recordedAt,
    };
