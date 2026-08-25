// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PurchaseOrder _$PurchaseOrderFromJson(
  Map<String, dynamic> json,
) => _PurchaseOrder(
  id: (json['id'] as num).toInt(),
  vendorId: (json['vendor_id'] as num).toInt(),
  vendor: json['vendor'] == null
      ? null
      : ArrivalRef.fromJson(json['vendor'] as Map<String, dynamic>),
  warehouseId: (json['warehouse_id'] as num?)?.toInt(),
  warehouse: json['warehouse'] == null
      ? null
      : ArrivalRef.fromJson(json['warehouse'] as Map<String, dynamic>),
  status: $enumDecode(
    _$PurchaseOrderStatusEnumMap,
    json['status'],
    unknownValue: PurchaseOrderStatus.unknown,
  ),
  statusLabel: json['status_label'] as String,
  orderDate: json['order_date'] as String,
  expectedDate: json['expected_date'] as String?,
  notes: json['notes'] as String?,
  totalAmount: json['total_amount'] as String?,
  totalAdditionalCost: json['total_additional_cost'] as String?,
  additionalCosts:
      (json['additional_costs'] as List<dynamic>?)
          ?.map(
            (e) =>
                PurchaseOrderAdditionalCost.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <PurchaseOrderAdditionalCost>[],
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PurchaseOrderItem>[],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PurchaseOrderToJson(
  _PurchaseOrder instance,
) => <String, dynamic>{
  'id': instance.id,
  'vendor_id': instance.vendorId,
  'vendor': instance.vendor?.toJson(),
  'warehouse_id': instance.warehouseId,
  'warehouse': instance.warehouse?.toJson(),
  'status': _$PurchaseOrderStatusEnumMap[instance.status]!,
  'status_label': instance.statusLabel,
  'order_date': instance.orderDate,
  'expected_date': instance.expectedDate,
  'notes': instance.notes,
  'total_amount': instance.totalAmount,
  'total_additional_cost': instance.totalAdditionalCost,
  'additional_costs': instance.additionalCosts.map((e) => e.toJson()).toList(),
  'items': instance.items.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$PurchaseOrderStatusEnumMap = {
  PurchaseOrderStatus.fresh: 'new',
  PurchaseOrderStatus.arrived: 'arrived',
  PurchaseOrderStatus.completed: 'completed',
  PurchaseOrderStatus.cancelled: 'cancelled',
  PurchaseOrderStatus.unknown: 'unknown',
};

_PurchaseOrderAdditionalCost _$PurchaseOrderAdditionalCostFromJson(
  Map<String, dynamic> json,
) => _PurchaseOrderAdditionalCost(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  amount: json['amount'] as String,
);

Map<String, dynamic> _$PurchaseOrderAdditionalCostToJson(
  _PurchaseOrderAdditionalCost instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'amount': instance.amount,
};

_PurchaseOrderItem _$PurchaseOrderItemFromJson(Map<String, dynamic> json) =>
    _PurchaseOrderItem(
      id: (json['id'] as num).toInt(),
      stockItemId: (json['stock_item_id'] as num).toInt(),
      stockItem: json['stock_item'] == null
          ? null
          : StockItemRef.fromJson(json['stock_item'] as Map<String, dynamic>),
      quantityOrdered: json['quantity_ordered'] as String,
      quantityReceived: json['quantity_received'] as String,
      quantityRemaining: json['quantity_remaining'] as String,
      baseTotalCost: json['base_total_cost'] as String?,
      baseUnitCost: json['base_unit_cost'] as String?,
      allocatedAdditionalCost: json['allocated_additional_cost'] as String?,
      finalUnitCost: json['final_unit_cost'] as String?,
      finalTotalCost: json['final_total_cost'] as String?,
      unit: json['unit'] as String?,
      unitLabel: json['unit_label'] as String?,
    );

Map<String, dynamic> _$PurchaseOrderItemToJson(_PurchaseOrderItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'stock_item_id': instance.stockItemId,
      'stock_item': instance.stockItem?.toJson(),
      'quantity_ordered': instance.quantityOrdered,
      'quantity_received': instance.quantityReceived,
      'quantity_remaining': instance.quantityRemaining,
      'base_total_cost': instance.baseTotalCost,
      'base_unit_cost': instance.baseUnitCost,
      'allocated_additional_cost': instance.allocatedAdditionalCost,
      'final_unit_cost': instance.finalUnitCost,
      'final_total_cost': instance.finalTotalCost,
      'unit': instance.unit,
      'unit_label': instance.unitLabel,
    };
