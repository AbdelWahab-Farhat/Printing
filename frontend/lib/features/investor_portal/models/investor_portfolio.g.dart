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
      fund: json['fund'] == null
          ? null
          : FundShare.fromJson(json['fund'] as Map<String, dynamic>),
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
      'fund': instance.fund?.toJson(),
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

_FundShare _$FundShareFromJson(Map<String, dynamic> json) => _FundShare(
  units: json['units'] as String,
  unitPrice: json['unit_price'] as String,
  value: json['value'] as String,
  sharePercent: json['share_percent'] as String,
  shareStartsNextPeriod: json['share_starts_next_period'] as bool? ?? false,
  unlockedUnits: json['unlocked_units'] as String? ?? '0.000000',
  period: json['period'] == null
      ? null
      : FundPeriodBrief.fromJson(json['period'] as Map<String, dynamic>),
  deposits:
      (json['deposits'] as List<dynamic>?)
          ?.map((e) => FundDeposit.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FundDeposit>[],
);

Map<String, dynamic> _$FundShareToJson(_FundShare instance) =>
    <String, dynamic>{
      'units': instance.units,
      'unit_price': instance.unitPrice,
      'value': instance.value,
      'share_percent': instance.sharePercent,
      'share_starts_next_period': instance.shareStartsNextPeriod,
      'unlocked_units': instance.unlockedUnits,
      'period': instance.period?.toJson(),
      'deposits': instance.deposits.map((e) => e.toJson()).toList(),
    };

_FundPeriodBrief _$FundPeriodBriefFromJson(Map<String, dynamic> json) =>
    _FundPeriodBrief(
      code: json['code'] as String,
      startsOn: json['starts_on'] as String,
      endsOn: json['ends_on'] as String,
      acceptsCapital: json['accepts_capital'] as bool? ?? false,
    );

Map<String, dynamic> _$FundPeriodBriefToJson(_FundPeriodBrief instance) =>
    <String, dynamic>{
      'code': instance.code,
      'starts_on': instance.startsOn,
      'ends_on': instance.endsOn,
      'accepts_capital': instance.acceptsCapital,
    };

_FundDeposit _$FundDepositFromJson(Map<String, dynamic> json) => _FundDeposit(
  units: json['units'] as String,
  amount: json['amount'] as String,
  lockedUntil: json['locked_until'] as String?,
  isLocked: json['is_locked'] as bool? ?? true,
);

Map<String, dynamic> _$FundDepositToJson(_FundDeposit instance) =>
    <String, dynamic>{
      'units': instance.units,
      'amount': instance.amount,
      'locked_until': instance.lockedUntil,
      'is_locked': instance.isLocked,
    };
