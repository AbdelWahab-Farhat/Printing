// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_portfolio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvestorPortfolio _$InvestorPortfolioFromJson(Map<String, dynamic> json) =>
    _InvestorPortfolio(
      investor: InvestorIdentity.fromJson(
        json['investor'] as Map<String, dynamic>,
      ),
      capitalInWallet: json['capital_in_wallet'] as String,
      capitalInDeals: json['capital_in_deals'] as String,
      capitalTotal: json['capital_total'] as String,
      profitInDeals: json['profit_in_deals'] as String,
      profitAvailable: json['profit_available'] as String,
      profitWithdrawn: json['profit_withdrawn'] as String,
      deals:
          (json['deals'] as List<dynamic>?)
              ?.map((e) => InvestorDealLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <InvestorDealLine>[],
    );

Map<String, dynamic> _$InvestorPortfolioToJson(_InvestorPortfolio instance) =>
    <String, dynamic>{
      'investor': instance.investor.toJson(),
      'capital_in_wallet': instance.capitalInWallet,
      'capital_in_deals': instance.capitalInDeals,
      'capital_total': instance.capitalTotal,
      'profit_in_deals': instance.profitInDeals,
      'profit_available': instance.profitAvailable,
      'profit_withdrawn': instance.profitWithdrawn,
      'deals': instance.deals.map((e) => e.toJson()).toList(),
    };

_InvestorIdentity _$InvestorIdentityFromJson(Map<String, dynamic> json) =>
    _InvestorIdentity(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$InvestorIdentityToJson(_InvestorIdentity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

_InvestorDealLine _$InvestorDealLineFromJson(Map<String, dynamic> json) =>
    _InvestorDealLine(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String?,
      status: json['status'] as String?,
      statusLabel: json['status_label'] as String?,
      sharePercent: json['share_percent'] as String,
      capital: json['capital'] as String,
      profit: json['profit'] as String,
    );

Map<String, dynamic> _$InvestorDealLineToJson(_InvestorDealLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'share_percent': instance.sharePercent,
      'capital': instance.capital,
      'profit': instance.profit,
    };
