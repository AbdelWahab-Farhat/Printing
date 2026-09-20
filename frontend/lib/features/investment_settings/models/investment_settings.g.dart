// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvestmentSettings _$InvestmentSettingsFromJson(
  Map<String, dynamic> json,
) => _InvestmentSettings(
  investorProfitSharePercent: json['investor_profit_share_percent'] as String,
  periodMonths: (json['investment_period_months'] as num).toInt(),
  subscriptionWindowDays: (json['investment_subscription_window_days'] as num)
      .toInt(),
  settlementMonths: (json['investment_settlement_months'] as num).toInt(),
  capitalLockMonths: (json['investment_capital_lock_months'] as num).toInt(),
);

Map<String, dynamic> _$InvestmentSettingsToJson(_InvestmentSettings instance) =>
    <String, dynamic>{
      'investor_profit_share_percent': instance.investorProfitSharePercent,
      'investment_period_months': instance.periodMonths,
      'investment_subscription_window_days': instance.subscriptionWindowDays,
      'investment_settlement_months': instance.settlementMonths,
      'investment_capital_lock_months': instance.capitalLockMonths,
    };
