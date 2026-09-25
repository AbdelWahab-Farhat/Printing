// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletEntry _$WalletEntryFromJson(Map<String, dynamic> json) => _WalletEntry(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  typeLabel: json['type_label'] as String,
  category: json['category'] as String?,
  amount: json['amount'] as String,
  signedAmount: json['signed_amount'] as String,
  method: json['method'] as String?,
  reference: json['reference'] as String?,
  deal: json['deal'] == null
      ? null
      : WalletEntryDeal.fromJson(json['deal'] as Map<String, dynamic>),
  period: json['period'] == null
      ? null
      : WalletEntryPeriod.fromJson(json['period'] as Map<String, dynamic>),
  fundUnits: json['fund_units'] == null
      ? null
      : WalletEntryUnits.fromJson(json['fund_units'] as Map<String, dynamic>),
  reversesEntryId: (json['reverses_entry_id'] as num?)?.toInt(),
  isReversed: json['is_reversed'] as bool? ?? false,
  canBeReversed: json['can_be_reversed'] as bool? ?? false,
  occurredAt: json['occurred_at'] == null
      ? null
      : DateTime.parse(json['occurred_at'] as String),
  notes: json['notes'] as String?,
  recordedBy: json['recorded_by'] == null
      ? null
      : WalletEntryActor.fromJson(json['recorded_by'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WalletEntryToJson(_WalletEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'type_label': instance.typeLabel,
      'category': instance.category,
      'amount': instance.amount,
      'signed_amount': instance.signedAmount,
      'method': instance.method,
      'reference': instance.reference,
      'deal': instance.deal?.toJson(),
      'period': instance.period?.toJson(),
      'fund_units': instance.fundUnits?.toJson(),
      'reverses_entry_id': instance.reversesEntryId,
      'is_reversed': instance.isReversed,
      'can_be_reversed': instance.canBeReversed,
      'occurred_at': instance.occurredAt?.toIso8601String(),
      'notes': instance.notes,
      'recorded_by': instance.recordedBy?.toJson(),
    };

_WalletEntryDeal _$WalletEntryDealFromJson(Map<String, dynamic> json) =>
    _WalletEntryDeal(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      isFund: json['is_fund'] as bool? ?? false,
    );

Map<String, dynamic> _$WalletEntryDealToJson(_WalletEntryDeal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'is_fund': instance.isFund,
    };

_WalletEntryPeriod _$WalletEntryPeriodFromJson(Map<String, dynamic> json) =>
    _WalletEntryPeriod(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
    );

Map<String, dynamic> _$WalletEntryPeriodToJson(_WalletEntryPeriod instance) =>
    <String, dynamic>{'id': instance.id, 'code': instance.code};

_WalletEntryUnits _$WalletEntryUnitsFromJson(Map<String, dynamic> json) =>
    _WalletEntryUnits(
      units: json['units'] as String,
      unitPrice: json['unit_price'] as String,
      lockedUntil: json['locked_until'] as String?,
    );

Map<String, dynamic> _$WalletEntryUnitsToJson(_WalletEntryUnits instance) =>
    <String, dynamic>{
      'units': instance.units,
      'unit_price': instance.unitPrice,
      'locked_until': instance.lockedUntil,
    };

_WalletEntryActor _$WalletEntryActorFromJson(Map<String, dynamic> json) =>
    _WalletEntryActor(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$WalletEntryActorToJson(_WalletEntryActor instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
