// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capital_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CapitalRequest _$CapitalRequestFromJson(Map<String, dynamic> json) =>
    _CapitalRequest(
      id: (json['id'] as num).toInt(),
      investmentPoolId: (json['investment_pool_id'] as num).toInt(),
      investorId: (json['investor_id'] as num).toInt(),
      investor: json['investor'] == null
          ? null
          : CapitalRequestInvestor.fromJson(
              json['investor'] as Map<String, dynamic>,
            ),
      direction: json['direction'] as String,
      directionLabel: json['direction_label'] as String,
      amount: json['amount'] as String,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      canBeCancelled: json['can_be_cancelled'] as bool? ?? false,
      requestedAt: json['requested_at'] as String?,
      effectivePeriodId: (json['effective_period_id'] as num?)?.toInt(),
      appliedEntryId: (json['applied_entry_id'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$CapitalRequestToJson(_CapitalRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'investment_pool_id': instance.investmentPoolId,
      'investor_id': instance.investorId,
      'investor': instance.investor?.toJson(),
      'direction': instance.direction,
      'direction_label': instance.directionLabel,
      'amount': instance.amount,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'can_be_cancelled': instance.canBeCancelled,
      'requested_at': instance.requestedAt,
      'effective_period_id': instance.effectivePeriodId,
      'applied_entry_id': instance.appliedEntryId,
      'notes': instance.notes,
    };

_CapitalRequestInvestor _$CapitalRequestInvestorFromJson(
  Map<String, dynamic> json,
) => _CapitalRequestInvestor(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
);

Map<String, dynamic> _$CapitalRequestInvestorToJson(
  _CapitalRequestInvestor instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

_PeriodOpened _$PeriodOpenedFromJson(Map<String, dynamic> json) =>
    _PeriodOpened(
      applied:
          (json['applied'] as List<dynamic>?)
              ?.map((e) => CapitalRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CapitalRequest>[],
      short:
          json['short'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$PeriodOpenedToJson(_PeriodOpened instance) =>
    <String, dynamic>{
      'applied': instance.applied.map((e) => e.toJson()).toList(),
      'short': instance.short,
    };
