// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderTicket _$OrderTicketFromJson(Map<String, dynamic> json) => _OrderTicket(
  kind: $enumDecode(
    _$OrderTicketKindEnumMap,
    json['kind'],
    unknownValue: OrderTicketKind.unknown,
  ),
  kindLabel: json['kind_label'] as String,
  id: (json['id'] as num).toInt(),
  code: json['code'] as String?,
  title: json['title'] as String,
  status: json['status'] as String,
  statusLabel: json['status_label'] as String,
  isOpen: json['is_open'] as bool? ?? false,
  activityAt: json['activity_at'] == null
      ? null
      : DateTime.parse(json['activity_at'] as String),
);

Map<String, dynamic> _$OrderTicketToJson(_OrderTicket instance) =>
    <String, dynamic>{
      'kind': _$OrderTicketKindEnumMap[instance.kind]!,
      'kind_label': instance.kindLabel,
      'id': instance.id,
      'code': instance.code,
      'title': instance.title,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'is_open': instance.isOpen,
      'activity_at': instance.activityAt?.toIso8601String(),
    };

const _$OrderTicketKindEnumMap = {
  OrderTicketKind.internal: 'internal',
  OrderTicketKind.design: 'design',
  OrderTicketKind.support: 'support',
  OrderTicketKind.unknown: 'unknown',
};
