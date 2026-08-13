// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_cost_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductionCostEntry _$ProductionCostEntryFromJson(Map<String, dynamic> json) =>
    _ProductionCostEntry(
      id: (json['id'] as num).toInt(),
      orderId: (json['order_id'] as num).toInt(),
      orderItemId: (json['order_item_id'] as num).toInt(),
      costType: json['cost_type'] as String,
      costTypeLabel: json['cost_type_label'] as String,
      amount: json['amount'] as String,
      quantity: json['quantity'] as String?,
      rate: json['rate'] as String?,
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by'] == null
          ? null
          : ProductionCostRecorder.fromJson(
              json['recorded_by'] as Map<String, dynamic>,
            ),
      incurredAt: json['incurred_at'] == null
          ? null
          : DateTime.parse(json['incurred_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ProductionCostEntryToJson(
  _ProductionCostEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'order_item_id': instance.orderItemId,
  'cost_type': instance.costType,
  'cost_type_label': instance.costTypeLabel,
  'amount': instance.amount,
  'quantity': instance.quantity,
  'rate': instance.rate,
  'notes': instance.notes,
  'recorded_by': instance.recordedBy?.toJson(),
  'incurred_at': instance.incurredAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
};

_ProductionCostRecorder _$ProductionCostRecorderFromJson(
  Map<String, dynamic> json,
) => _ProductionCostRecorder(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$ProductionCostRecorderToJson(
  _ProductionCostRecorder instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};
