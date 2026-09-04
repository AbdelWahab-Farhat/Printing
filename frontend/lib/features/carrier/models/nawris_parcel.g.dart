// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nawris_parcel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NawrisParcel _$NawrisParcelFromJson(Map<String, dynamic> json) =>
    _NawrisParcel(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      reference: json['reference'] as String?,
      barCode: json['bar_code'] as String?,
      government: json['government'] as String?,
      area: json['area'] as String?,
      amountToCollect: json['amount_to_collect'] as String?,
      deliveryPriceDeducted: json['delivery_price_deducted'] as String?,
      collectedAmount: json['collected_amount'] as String?,
      remoteStatusCode: (json['remote_status_code'] as num?)?.toInt(),
      remoteStatusText: json['remote_status_text'] as String?,
      isOpen: json['is_open'] as bool? ?? false,
      hasOpenConflict: json['has_open_conflict'] as bool? ?? false,
      dispatchedAt: json['dispatched_at'] == null
          ? null
          : DateTime.parse(json['dispatched_at'] as String),
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
    );

Map<String, dynamic> _$NawrisParcelToJson(_NawrisParcel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'reference': instance.reference,
      'bar_code': instance.barCode,
      'government': instance.government,
      'area': instance.area,
      'amount_to_collect': instance.amountToCollect,
      'delivery_price_deducted': instance.deliveryPriceDeducted,
      'collected_amount': instance.collectedAmount,
      'remote_status_code': instance.remoteStatusCode,
      'remote_status_text': instance.remoteStatusText,
      'is_open': instance.isOpen,
      'has_open_conflict': instance.hasOpenConflict,
      'dispatched_at': instance.dispatchedAt?.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
    };
