// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockMovement _$StockMovementFromJson(
  Map<String, dynamic> json,
) => _StockMovement(
  id: (json['id'] as num).toInt(),
  movementType: $enumDecode(
    _$MovementTypeEnumMap,
    json['movement_type'],
    unknownValue: MovementType.unknown,
  ),
  movementTypeLabel: json['movement_type_label'] as String,
  quantity: json['quantity'] as String,
  stockItemId: (json['stock_item_id'] as num).toInt(),
  item: json['stock_item'] == null
      ? null
      : StockItemRef.fromJson(json['stock_item'] as Map<String, dynamic>),
  fromWarehouseId: (json['from_warehouse_id'] as num?)?.toInt(),
  fromWarehouse: json['from_warehouse'] == null
      ? null
      : MovementPlace.fromJson(json['from_warehouse'] as Map<String, dynamic>),
  toWarehouseId: (json['to_warehouse_id'] as num?)?.toInt(),
  toWarehouse: json['to_warehouse'] == null
      ? null
      : MovementPlace.fromJson(json['to_warehouse'] as Map<String, dynamic>),
  referenceId: (json['reference_id'] as num?)?.toInt(),
  employeeId: (json['employee_id'] as num?)?.toInt(),
  employee: json['employee'] == null
      ? null
      : MovementActor.fromJson(json['employee'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
  signedQuantity: json['signed_quantity'] as String?,
  balanceAfter: json['balance_after'] as String?,
  unitCost: json['unit_cost'] as String?,
  totalCost: json['total_cost'] as String?,
  uncostedQuantity: json['uncosted_quantity'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$StockMovementToJson(_StockMovement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'movement_type': _$MovementTypeEnumMap[instance.movementType]!,
      'movement_type_label': instance.movementTypeLabel,
      'quantity': instance.quantity,
      'stock_item_id': instance.stockItemId,
      'stock_item': instance.item?.toJson(),
      'from_warehouse_id': instance.fromWarehouseId,
      'from_warehouse': instance.fromWarehouse?.toJson(),
      'to_warehouse_id': instance.toWarehouseId,
      'to_warehouse': instance.toWarehouse?.toJson(),
      'reference_id': instance.referenceId,
      'employee_id': instance.employeeId,
      'employee': instance.employee?.toJson(),
      'notes': instance.notes,
      'signed_quantity': instance.signedQuantity,
      'balance_after': instance.balanceAfter,
      'unit_cost': instance.unitCost,
      'total_cost': instance.totalCost,
      'uncosted_quantity': instance.uncostedQuantity,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$MovementTypeEnumMap = {
  MovementType.purchaseArrival: 'purchase_arrival',
  MovementType.internalTransfer: 'internal_transfer',
  MovementType.orderFulfillment: 'order_fulfillment',
  MovementType.adjustment: 'adjustment',
  MovementType.orderReversal: 'order_reversal',
  MovementType.scrapLoss: 'scrap_loss',
  MovementType.unknown: 'unknown',
};

_MovementPlace _$MovementPlaceFromJson(Map<String, dynamic> json) =>
    _MovementPlace(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$MovementPlaceToJson(_MovementPlace instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_MovementActor _$MovementActorFromJson(Map<String, dynamic> json) =>
    _MovementActor(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      employeeCode: json['employee_code'] as String?,
    );

Map<String, dynamic> _$MovementActorToJson(_MovementActor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'employee_code': instance.employeeCode,
    };
