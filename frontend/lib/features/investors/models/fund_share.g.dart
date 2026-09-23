// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FundShare _$FundShareFromJson(Map<String, dynamic> json) => _FundShare(
  capital: json['capital'] as String? ?? '0.00',
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
      'capital': instance.capital,
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
