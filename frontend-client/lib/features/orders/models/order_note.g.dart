// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderNote _$OrderNoteFromJson(Map<String, dynamic> json) => _OrderNote(
  id: (json['id'] as num).toInt(),
  stage:
      $enumDecodeNullable(
        _$OrderStageEnumMap,
        json['stage'],
        unknownValue: OrderStage.unknown,
      ) ??
      OrderStage.unknown,
  stageLabel: json['stage_label'] as String,
  text: json['text'] as String,
  writtenAt: json['written_at'] == null
      ? null
      : DateTime.parse(json['written_at'] as String),
);

Map<String, dynamic> _$OrderNoteToJson(_OrderNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'stage': _$OrderStageEnumMap[instance.stage]!,
      'stage_label': instance.stageLabel,
      'text': instance.text,
      'written_at': instance.writtenAt?.toIso8601String(),
    };

const _$OrderStageEnumMap = {
  OrderStage.underReview: 'under_review',
  OrderStage.preparing: 'preparing',
  OrderStage.designing: 'designing',
  OrderStage.producing: 'producing',
  OrderStage.ready: 'ready',
  OrderStage.onTheWay: 'on_the_way',
  OrderStage.delivered: 'delivered',
  OrderStage.returned: 'returned',
  OrderStage.cancelled: 'cancelled',
  OrderStage.rejected: 'rejected',
  OrderStage.unknown: 'unknown',
};
