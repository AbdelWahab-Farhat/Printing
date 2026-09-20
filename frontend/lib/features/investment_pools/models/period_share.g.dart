// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PeriodShare _$PeriodShareFromJson(Map<String, dynamic> json) => _PeriodShare(
  id: (json['id'] as num).toInt(),
  investmentPeriodId: (json['investment_period_id'] as num).toInt(),
  investorId: (json['investor_id'] as num).toInt(),
  investorName: json['investor_name'] as String?,
  isCompany: json['is_company'] as bool? ?? false,
  capital: json['capital'] as String? ?? '0.00',
  sharePercent: json['share_percent'] as String? ?? '0.0000',
  netShare: json['net_share'] as String? ?? '0.00',
);

Map<String, dynamic> _$PeriodShareToJson(_PeriodShare instance) =>
    <String, dynamic>{
      'id': instance.id,
      'investment_period_id': instance.investmentPeriodId,
      'investor_id': instance.investorId,
      'investor_name': instance.investorName,
      'is_company': instance.isCompany,
      'capital': instance.capital,
      'share_percent': instance.sharePercent,
      'net_share': instance.netShare,
    };
