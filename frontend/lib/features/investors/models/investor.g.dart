// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Investor _$InvestorFromJson(Map<String, dynamic> json) => _Investor(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String?,
  notes: json['notes'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  hasLogin: json['has_login'] as bool? ?? false,
  totals: json['totals'] == null
      ? null
      : InvestorTotals.fromJson(json['totals'] as Map<String, dynamic>),
  balances: json['balances'] == null
      ? null
      : InvestorBalances.fromJson(json['balances'] as Map<String, dynamic>),
  profitFigures: json['profit_figures'] == null
      ? null
      : ProfitFigures.fromJson(json['profit_figures'] as Map<String, dynamic>),
  fund: json['fund'] == null
      ? null
      : FundShare.fromJson(json['fund'] as Map<String, dynamic>),
);

Map<String, dynamic> _$InvestorToJson(_Investor instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'phone': instance.phone,
  'notes': instance.notes,
  'is_active': instance.isActive,
  'has_login': instance.hasLogin,
  'totals': instance.totals?.toJson(),
  'balances': instance.balances?.toJson(),
  'profit_figures': instance.profitFigures?.toJson(),
  'fund': instance.fund?.toJson(),
};

_InvestorBalances _$InvestorBalancesFromJson(Map<String, dynamic> json) =>
    _InvestorBalances(
      wallet: WalletPots.fromJson(json['wallet'] as Map<String, dynamic>),
      deals:
          (json['deals'] as List<dynamic>?)
              ?.map((e) => DealPots.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DealPots>[],
    );

Map<String, dynamic> _$InvestorBalancesToJson(_InvestorBalances instance) =>
    <String, dynamic>{
      'wallet': instance.wallet.toJson(),
      'deals': instance.deals.map((e) => e.toJson()).toList(),
    };

_WalletPots _$WalletPotsFromJson(Map<String, dynamic> json) => _WalletPots(
  capital: json['capital'] as String,
  profit: json['profit'] as String,
);

Map<String, dynamic> _$WalletPotsToJson(_WalletPots instance) =>
    <String, dynamic>{'capital': instance.capital, 'profit': instance.profit};

_DealPots _$DealPotsFromJson(Map<String, dynamic> json) => _DealPots(
  investorDealId: (json['investor_deal_id'] as num).toInt(),
  capital: json['capital'] as String,
  profit: json['profit'] as String,
);

Map<String, dynamic> _$DealPotsToJson(_DealPots instance) => <String, dynamic>{
  'investor_deal_id': instance.investorDealId,
  'capital': instance.capital,
  'profit': instance.profit,
};

_InvestorTotals _$InvestorTotalsFromJson(Map<String, dynamic> json) =>
    _InvestorTotals(
      capital: json['capital'] as String,
      profit: json['profit'] as String,
      walletCapital: json['wallet_capital'] as String,
      walletProfit: json['wallet_profit'] as String,
    );

Map<String, dynamic> _$InvestorTotalsToJson(_InvestorTotals instance) =>
    <String, dynamic>{
      'capital': instance.capital,
      'profit': instance.profit,
      'wallet_capital': instance.walletCapital,
      'wallet_profit': instance.walletProfit,
    };

_ProfitFigures _$ProfitFiguresFromJson(Map<String, dynamic> json) =>
    _ProfitFigures(
      awaitingDelivery: json['awaiting_delivery'] as String,
      ordersAwaitingDelivery:
          (json['orders_awaiting_delivery'] as num?)?.toInt() ?? 0,
      pending: json['pending'] as String,
      available: json['available'] as String,
    );

Map<String, dynamic> _$ProfitFiguresToJson(_ProfitFigures instance) =>
    <String, dynamic>{
      'awaiting_delivery': instance.awaitingDelivery,
      'orders_awaiting_delivery': instance.ordersAwaitingDelivery,
      'pending': instance.pending,
      'available': instance.available,
    };
