// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_standing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FundValuation _$FundValuationFromJson(Map<String, dynamic> json) =>
    _FundValuation(
      cash: json['cash'] as String,
      stockOnShelf: json['stock_on_shelf'] as String,
      goodsInFlight: json['goods_in_flight'] as String,
      receivablesAtCost: json['receivables_at_cost'] as String,
      profitOwed: json['profit_owed'] as String,
      total: json['total'] as String,
    );

Map<String, dynamic> _$FundValuationToJson(_FundValuation instance) =>
    <String, dynamic>{
      'cash': instance.cash,
      'stock_on_shelf': instance.stockOnShelf,
      'goods_in_flight': instance.goodsInFlight,
      'receivables_at_cost': instance.receivablesAtCost,
      'profit_owed': instance.profitOwed,
      'total': instance.total,
    };

_FundPeriod _$FundPeriodFromJson(Map<String, dynamic> json) => _FundPeriod(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  status: json['status'] as String,
  statusLabel: json['status_label'] as String,
  startsOn: json['starts_on'] as String,
  endsOn: json['ends_on'] as String,
  subscriptionClosesOn: json['subscription_closes_on'] as String,
  isDueToClose: json['is_due_to_close'] as bool,
  overdueDays: (json['overdue_days'] as num?)?.toInt(),
  owedOrders: (json['owed_orders'] as num?)?.toInt(),
  periodMonths: (json['period_months'] as num).toInt(),
  investorProfitSharePercent: json['investor_profit_share_percent'] as String,
  openingStockCost: json['opening_stock_cost'] as String,
  openingCash: json['opening_cash'] as String,
  acceptsCapital: json['accepts_capital'] as bool? ?? false,
  subscriptionServesNextPeriod:
      json['subscription_serves_next_period'] as bool? ?? false,
  capitalLockMonths: (json['capital_lock_months'] as num?)?.toInt() ?? 12,
  endsSettlementCycle: json['ends_settlement_cycle'] as bool? ?? false,
  overrideReason: json['override_reason'] as String?,
  closedAt: json['closed_at'] as String?,
  netProfit: json['net_profit'] as String?,
  investorsPool: json['investors_pool'] as String?,
  companyShare: json['company_share'] as String?,
  salesRevenue: json['sales_revenue'] as String?,
  closingStockCost: json['closing_stock_cost'] as String?,
  closingCash: json['closing_cash'] as String?,
);

Map<String, dynamic> _$FundPeriodToJson(_FundPeriod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'starts_on': instance.startsOn,
      'ends_on': instance.endsOn,
      'subscription_closes_on': instance.subscriptionClosesOn,
      'is_due_to_close': instance.isDueToClose,
      'overdue_days': instance.overdueDays,
      'owed_orders': instance.owedOrders,
      'period_months': instance.periodMonths,
      'investor_profit_share_percent': instance.investorProfitSharePercent,
      'opening_stock_cost': instance.openingStockCost,
      'opening_cash': instance.openingCash,
      'accepts_capital': instance.acceptsCapital,
      'subscription_serves_next_period': instance.subscriptionServesNextPeriod,
      'capital_lock_months': instance.capitalLockMonths,
      'ends_settlement_cycle': instance.endsSettlementCycle,
      'override_reason': instance.overrideReason,
      'closed_at': instance.closedAt,
      'net_profit': instance.netProfit,
      'investors_pool': instance.investorsPool,
      'company_share': instance.companyShare,
      'sales_revenue': instance.salesRevenue,
      'closing_stock_cost': instance.closingStockCost,
      'closing_cash': instance.closingCash,
    };

_FundHolder _$FundHolderFromJson(Map<String, dynamic> json) => _FundHolder(
  investorId: (json['investor_id'] as num).toInt(),
  name: json['name'] as String,
  units: json['units'] as String,
  sharePercent: json['share_percent'] as String,
  capital: json['capital'] as String,
  profit: json['profit'] as String,
  shareStartsNextPeriod: json['share_starts_next_period'] as bool? ?? false,
  nextSharePercent: json['next_share_percent'] as String? ?? '0.000000',
);

Map<String, dynamic> _$FundHolderToJson(_FundHolder instance) =>
    <String, dynamic>{
      'investor_id': instance.investorId,
      'name': instance.name,
      'units': instance.units,
      'share_percent': instance.sharePercent,
      'capital': instance.capital,
      'profit': instance.profit,
      'share_starts_next_period': instance.shareStartsNextPeriod,
      'next_share_percent': instance.nextSharePercent,
    };

_FundStanding _$FundStandingFromJson(Map<String, dynamic> json) =>
    _FundStanding(
      valuation: FundValuation.fromJson(
        json['valuation'] as Map<String, dynamic>,
      ),
      period: json['period'] == null
          ? null
          : FundPeriod.fromJson(json['period'] as Map<String, dynamic>),
      unitPrice: json['unit_price'] as String? ?? '1.000000',
      unitsOutstanding: json['units_outstanding'] as String? ?? '0.000000',
      investors:
          (json['investors'] as List<dynamic>?)
              ?.map((e) => FundHolder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <FundHolder>[],
      waitingPeriods:
          (json['waiting_periods'] as List<dynamic>?)
              ?.map((e) => FundPeriod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <FundPeriod>[],
      defaultPlainSalePrice: json['default_plain_sale_price'] as String?,
      subscribable:
          (json['subscribable'] as List<dynamic>?)
              ?.map((e) => FundSubscriber.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <FundSubscriber>[],
    );

Map<String, dynamic> _$FundStandingToJson(
  _FundStanding instance,
) => <String, dynamic>{
  'valuation': instance.valuation.toJson(),
  'period': instance.period?.toJson(),
  'unit_price': instance.unitPrice,
  'units_outstanding': instance.unitsOutstanding,
  'investors': instance.investors.map((e) => e.toJson()).toList(),
  'waiting_periods': instance.waitingPeriods.map((e) => e.toJson()).toList(),
  'default_plain_sale_price': instance.defaultPlainSalePrice,
  'subscribable': instance.subscribable.map((e) => e.toJson()).toList(),
};

_FundSubscriber _$FundSubscriberFromJson(Map<String, dynamic> json) =>
    _FundSubscriber(
      investorId: (json['investor_id'] as num).toInt(),
      name: json['name'] as String,
      walletCapital: json['wallet_capital'] as String,
      walletProfit: json['wallet_profit'] as String,
    );

Map<String, dynamic> _$FundSubscriberToJson(_FundSubscriber instance) =>
    <String, dynamic>{
      'investor_id': instance.investorId,
      'name': instance.name,
      'wallet_capital': instance.walletCapital,
      'wallet_profit': instance.walletProfit,
    };

_DepositReceipt _$DepositReceiptFromJson(Map<String, dynamic> json) =>
    _DepositReceipt(
      units: json['units'] as String,
      unitPrice: json['unit_price'] as String,
      lockedUntil: json['locked_until'] as String?,
    );

Map<String, dynamic> _$DepositReceiptToJson(_DepositReceipt instance) =>
    <String, dynamic>{
      'units': instance.units,
      'unit_price': instance.unitPrice,
      'locked_until': instance.lockedUntil,
    };
