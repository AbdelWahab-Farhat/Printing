// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompanySettings _$CompanySettingsFromJson(Map<String, dynamic> json) =>
    _CompanySettings(
      investorProfitSharePercent:
          json['investor_profit_share_percent'] as String? ?? '50.00',
      profitPeriodMonths: (json['profit_period_months'] as num?)?.toInt() ?? 1,
      settlementPeriodMonths:
          (json['settlement_period_months'] as num?)?.toInt() ?? 6,
      entryGraceDays: (json['entry_grace_days'] as num?)?.toInt() ?? 3,
      minimumTermMonths: (json['minimum_term_months'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$CompanySettingsToJson(_CompanySettings instance) =>
    <String, dynamic>{
      'investor_profit_share_percent': instance.investorProfitSharePercent,
      'profit_period_months': instance.profitPeriodMonths,
      'settlement_period_months': instance.settlementPeriodMonths,
      'entry_grace_days': instance.entryGraceDays,
      'minimum_term_months': instance.minimumTermMonths,
      'updated_at': instance.updatedAt,
    };
