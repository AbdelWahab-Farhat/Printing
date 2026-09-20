// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvestmentPeriod _$InvestmentPeriodFromJson(Map<String, dynamic> json) =>
    _InvestmentPeriod(
      id: (json['id'] as num).toInt(),
      investmentPoolId: (json['investment_pool_id'] as num).toInt(),
      startsOn: json['starts_on'] as String?,
      endsOn: json['ends_on'] as String?,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      isOpen: json['is_open'] as bool? ?? true,
      isOverdue: json['is_overdue'] as bool? ?? false,
      daysOverdue: (json['days_overdue'] as num?)?.toInt() ?? 0,
      blockedByReturnedGoods:
          json['blocked_by_returned_goods'] as bool? ?? false,
      closedAt: json['closed_at'] as String?,
      snapshot: json['snapshot'] == null
          ? null
          : PeriodSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$InvestmentPeriodToJson(_InvestmentPeriod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'investment_pool_id': instance.investmentPoolId,
      'starts_on': instance.startsOn,
      'ends_on': instance.endsOn,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'is_open': instance.isOpen,
      'is_overdue': instance.isOverdue,
      'days_overdue': instance.daysOverdue,
      'blocked_by_returned_goods': instance.blockedByReturnedGoods,
      'closed_at': instance.closedAt,
      'snapshot': instance.snapshot?.toJson(),
      'notes': instance.notes,
    };

_PeriodSnapshot _$PeriodSnapshotFromJson(Map<String, dynamic> json) =>
    _PeriodSnapshot(
      openingCash: json['opening_cash'] as String,
      closingCash: json['closing_cash'] as String,
      openingStockCost: json['opening_stock_cost'] as String,
      closingStockCost: json['closing_stock_cost'] as String,
      realizedMargin: json['realized_margin'] as String,
      deductibleExpenses: json['deductible_expenses'] as String,
      damageCost: json['damage_cost'] as String,
      shortageCost: json['shortage_cost'] as String,
      netProfit: json['net_profit'] as String,
      investorSharePercentApplied:
          json['investor_share_percent_applied'] as String,
      investorCapitalWeightApplied:
          json['investor_capital_weight_applied'] as String,
      totalPoolCapital: json['total_pool_capital'] as String,
      totalInvestorCapital: json['total_investor_capital'] as String,
    );

Map<String, dynamic> _$PeriodSnapshotToJson(_PeriodSnapshot instance) =>
    <String, dynamic>{
      'opening_cash': instance.openingCash,
      'closing_cash': instance.closingCash,
      'opening_stock_cost': instance.openingStockCost,
      'closing_stock_cost': instance.closingStockCost,
      'realized_margin': instance.realizedMargin,
      'deductible_expenses': instance.deductibleExpenses,
      'damage_cost': instance.damageCost,
      'shortage_cost': instance.shortageCost,
      'net_profit': instance.netProfit,
      'investor_share_percent_applied': instance.investorSharePercentApplied,
      'investor_capital_weight_applied': instance.investorCapitalWeightApplied,
      'total_pool_capital': instance.totalPoolCapital,
      'total_investor_capital': instance.totalInvestorCapital,
    };

_PeriodFigures _$PeriodFiguresFromJson(Map<String, dynamic> json) =>
    _PeriodFigures(
      realizedMargin: json['realized_margin'] as String,
      deductibleExpenses: json['deductible_expenses'] as String,
      recordedOnlyExpenses: json['recorded_only_expenses'] as String? ?? '0.00',
      damageCost: json['damage_cost'] as String,
      shortageCost: json['shortage_cost'] as String,
      netProfit: json['net_profit'] as String,
      hasUnansweredReturns: json['has_unanswered_returns'] as bool? ?? false,
      period: json['period'] == null
          ? null
          : InvestmentPeriod.fromJson(json['period'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PeriodFiguresToJson(_PeriodFigures instance) =>
    <String, dynamic>{
      'realized_margin': instance.realizedMargin,
      'deductible_expenses': instance.deductibleExpenses,
      'recorded_only_expenses': instance.recordedOnlyExpenses,
      'damage_cost': instance.damageCost,
      'shortage_cost': instance.shortageCost,
      'net_profit': instance.netProfit,
      'has_unanswered_returns': instance.hasUnansweredReturns,
      'period': instance.period?.toJson(),
    };
