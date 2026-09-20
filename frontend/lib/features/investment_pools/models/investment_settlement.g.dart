// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_settlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvestmentSettlement _$InvestmentSettlementFromJson(
  Map<String, dynamic> json,
) => _InvestmentSettlement(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String?,
  investmentPoolId: (json['investment_pool_id'] as num).toInt(),
  periodFromId: (json['period_from_id'] as num?)?.toInt(),
  periodToId: (json['period_to_id'] as num?)?.toInt(),
  settledOn: json['settled_on'] as String?,
  approvedBy: (json['approved_by'] as num?)?.toInt(),
  approvedByName: json['approved_by_name'] as String?,
  totalCapital: json['total_capital'] as String? ?? '0.00',
  investorCapital: json['investor_capital'] as String? ?? '0.00',
  companyCapital: json['company_capital'] as String? ?? '0.00',
  deployableCash: json['deployable_cash'] as String? ?? '0.00',
  stockAtCost: json['stock_at_cost'] as String? ?? '0.00',
  undeployedCurrentProfit:
      json['undeployed_current_profit'] as String? ?? '0.00',
  receivables: json['receivables'] as String? ?? '0.00',
  liabilities: json['liabilities'] as String? ?? '0.00',
  distributedProfitToDate:
      json['distributed_profit_to_date'] as String? ?? '0.00',
  damageToDate: json['damage_to_date'] as String? ?? '0.00',
  shortageToDate: json['shortage_to_date'] as String? ?? '0.00',
  reconstructedCash: json['reconstructed_cash'] as String? ?? '0.00',
  drift: json['drift'] as String? ?? '0.00',
  hasDrift: json['has_drift'] as bool? ?? false,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$InvestmentSettlementToJson(
  _InvestmentSettlement instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'investment_pool_id': instance.investmentPoolId,
  'period_from_id': instance.periodFromId,
  'period_to_id': instance.periodToId,
  'settled_on': instance.settledOn,
  'approved_by': instance.approvedBy,
  'approved_by_name': instance.approvedByName,
  'total_capital': instance.totalCapital,
  'investor_capital': instance.investorCapital,
  'company_capital': instance.companyCapital,
  'deployable_cash': instance.deployableCash,
  'stock_at_cost': instance.stockAtCost,
  'undeployed_current_profit': instance.undeployedCurrentProfit,
  'receivables': instance.receivables,
  'liabilities': instance.liabilities,
  'distributed_profit_to_date': instance.distributedProfitToDate,
  'damage_to_date': instance.damageToDate,
  'shortage_to_date': instance.shortageToDate,
  'reconstructed_cash': instance.reconstructedCash,
  'drift': instance.drift,
  'has_drift': instance.hasDrift,
  'notes': instance.notes,
  'created_at': instance.createdAt,
};

_SettlementSnapshot _$SettlementSnapshotFromJson(Map<String, dynamic> json) =>
    _SettlementSnapshot(
      totalCapital: json['total_capital'] as String? ?? '0.00',
      investorCapital: json['investor_capital'] as String? ?? '0.00',
      companyCapital: json['company_capital'] as String? ?? '0.00',
      deployableCash: json['deployable_cash'] as String? ?? '0.00',
      stockAtCost: json['stock_at_cost'] as String? ?? '0.00',
      undeployedCurrentProfit:
          json['undeployed_current_profit'] as String? ?? '0.00',
      receivables: json['receivables'] as String? ?? '0.00',
      liabilities: json['liabilities'] as String? ?? '0.00',
      distributedProfitToDate:
          json['distributed_profit_to_date'] as String? ?? '0.00',
      companyAbsorbedLoss: json['company_absorbed_loss'] as String? ?? '0.00',
      damageToDate: json['damage_to_date'] as String? ?? '0.00',
      shortageToDate: json['shortage_to_date'] as String? ?? '0.00',
      bookValue: json['book_value'] as String? ?? '0.00',
      reconstructedCash: json['reconstructed_cash'] as String? ?? '0.00',
      reconstructedValue: json['reconstructed_value'] as String? ?? '0.00',
      drift: json['drift'] as String? ?? '0.00',
      periodFromId: (json['period_from_id'] as num?)?.toInt(),
      periodToId: (json['period_to_id'] as num?)?.toInt(),
      lastSettledOn: json['last_settled_on'] as String?,
      nextSettlementDueOn: json['next_settlement_due_on'] as String?,
      settlementIsOverdue: json['settlement_is_overdue'] as bool? ?? false,
      settlementPeriodMonths:
          (json['settlement_period_months'] as num?)?.toInt() ?? 6,
    );

Map<String, dynamic> _$SettlementSnapshotToJson(_SettlementSnapshot instance) =>
    <String, dynamic>{
      'total_capital': instance.totalCapital,
      'investor_capital': instance.investorCapital,
      'company_capital': instance.companyCapital,
      'deployable_cash': instance.deployableCash,
      'stock_at_cost': instance.stockAtCost,
      'undeployed_current_profit': instance.undeployedCurrentProfit,
      'receivables': instance.receivables,
      'liabilities': instance.liabilities,
      'distributed_profit_to_date': instance.distributedProfitToDate,
      'company_absorbed_loss': instance.companyAbsorbedLoss,
      'damage_to_date': instance.damageToDate,
      'shortage_to_date': instance.shortageToDate,
      'book_value': instance.bookValue,
      'reconstructed_cash': instance.reconstructedCash,
      'reconstructed_value': instance.reconstructedValue,
      'drift': instance.drift,
      'period_from_id': instance.periodFromId,
      'period_to_id': instance.periodToId,
      'last_settled_on': instance.lastSettledOn,
      'next_settlement_due_on': instance.nextSettlementDueOn,
      'settlement_is_overdue': instance.settlementIsOverdue,
      'settlement_period_months': instance.settlementPeriodMonths,
    };
