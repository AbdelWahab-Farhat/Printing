// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_expenses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PeriodExpenseRef _$PeriodExpenseRefFromJson(Map<String, dynamic> json) =>
    _PeriodExpenseRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$PeriodExpenseRefToJson(_PeriodExpenseRef instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_PeriodExpenseReversal _$PeriodExpenseReversalFromJson(
  Map<String, dynamic> json,
) => _PeriodExpenseReversal(
  id: (json['id'] as num).toInt(),
  incurredOn: json['incurred_on'] as String?,
  reason: json['reason'] as String?,
  periodCode: json['period_code'] as String?,
);

Map<String, dynamic> _$PeriodExpenseReversalToJson(
  _PeriodExpenseReversal instance,
) => <String, dynamic>{
  'id': instance.id,
  'incurred_on': instance.incurredOn,
  'reason': instance.reason,
  'period_code': instance.periodCode,
};

_PeriodExpense _$PeriodExpenseFromJson(
  Map<String, dynamic> json,
) => _PeriodExpense(
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
  counted: json['counted'] as bool? ?? true,
  recordedAfterClose: json['recorded_after_close'] as bool? ?? false,
  isReversed: json['is_reversed'] as bool? ?? false,
  canReverse: json['can_reverse'] as bool? ?? false,
  reversal: json['reversal'] == null
      ? null
      : PeriodExpenseReversal.fromJson(
          json['reversal'] as Map<String, dynamic>,
        ),
  investorsAmount: json['investors_amount'] as String? ?? '0.00',
  investors:
      (json['investors'] as List<dynamic>?)
          ?.map((e) => PeriodInvestorShare.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PeriodInvestorShare>[],
);

Map<String, dynamic> _$PeriodExpenseToJson(_PeriodExpense instance) =>
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
      'counted': instance.counted,
      'recorded_after_close': instance.recordedAfterClose,
      'is_reversed': instance.isReversed,
      'can_reverse': instance.canReverse,
      'reversal': instance.reversal?.toJson(),
      'investors_amount': instance.investorsAmount,
      'investors': instance.investors.map((e) => e.toJson()).toList(),
    };

_PeriodExpensesTotals _$PeriodExpensesTotalsFromJson(
  Map<String, dynamic> json,
) => _PeriodExpensesTotals(
  expensesTotal: json['expenses_total'] as String? ?? '0.00',
  investorsTotal: json['investors_total'] as String? ?? '0.00',
  frozenTotal: json['frozen_total'] as String?,
);

Map<String, dynamic> _$PeriodExpensesTotalsToJson(
  _PeriodExpensesTotals instance,
) => <String, dynamic>{
  'expenses_total': instance.expensesTotal,
  'investors_total': instance.investorsTotal,
  'frozen_total': instance.frozenTotal,
};

_PeriodExpenses _$PeriodExpensesFromJson(Map<String, dynamic> json) =>
    _PeriodExpenses(
      period: FundPeriod.fromJson(json['period'] as Map<String, dynamic>),
      expenses:
          (json['expenses'] as List<dynamic>?)
              ?.map((e) => PeriodExpense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PeriodExpense>[],
      corrections:
          (json['corrections'] as List<dynamic>?)
              ?.map((e) => PeriodExpense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PeriodExpense>[],
      totals: json['totals'] == null
          ? const PeriodExpensesTotals()
          : PeriodExpensesTotals.fromJson(
              json['totals'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PeriodExpensesToJson(_PeriodExpenses instance) =>
    <String, dynamic>{
      'period': instance.period.toJson(),
      'expenses': instance.expenses.map((e) => e.toJson()).toList(),
      'corrections': instance.corrections.map((e) => e.toJson()).toList(),
      'totals': instance.totals.toJson(),
    };
