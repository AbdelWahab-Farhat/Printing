// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_arrival.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockArrival _$StockArrivalFromJson(Map<String, dynamic> json) =>
    _StockArrival(
      id: (json['id'] as num).toInt(),
      vendorId: (json['vendor_id'] as num).toInt(),
      vendor: json['vendor'] == null
          ? null
          : ArrivalRef.fromJson(json['vendor'] as Map<String, dynamic>),
      purchaseOrderId: (json['purchase_order_id'] as num?)?.toInt(),
      warehouseId: (json['warehouse_id'] as num?)?.toInt(),
      warehouse: json['warehouse'] == null
          ? null
          : ArrivalRef.fromJson(json['warehouse'] as Map<String, dynamic>),
      invoiceNumber: json['invoice_number'] as String?,
      notes: json['notes'] as String?,
      receivedBy: (json['received_by'] as num).toInt(),
      receivedByUser: json['received_by_user'] == null
          ? null
          : ArrivalRef.fromJson(
              json['received_by_user'] as Map<String, dynamic>,
            ),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => StockArrivalItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StockArrivalItem>[],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$StockArrivalToJson(_StockArrival instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendor_id': instance.vendorId,
      'vendor': instance.vendor?.toJson(),
      'purchase_order_id': instance.purchaseOrderId,
      'warehouse_id': instance.warehouseId,
      'warehouse': instance.warehouse?.toJson(),
      'invoice_number': instance.invoiceNumber,
      'notes': instance.notes,
      'received_by': instance.receivedBy,
      'received_by_user': instance.receivedByUser?.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

_StockArrivalItem _$StockArrivalItemFromJson(Map<String, dynamic> json) =>
    _StockArrivalItem(
      id: (json['id'] as num).toInt(),
      quantity: json['quantity'] as String,
      stockItemId: (json['stock_item_id'] as num).toInt(),
      stockItem: json['stock_item'] == null
          ? null
          : StockItemRef.fromJson(json['stock_item'] as Map<String, dynamic>),
      unitCost: json['unit_cost'] as String?,
      totalCost: json['total_cost'] as String?,
      stockMovementId: (json['stock_movement_id'] as num).toInt(),
    );

Map<String, dynamic> _$StockArrivalItemToJson(_StockArrivalItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
      'stock_item_id': instance.stockItemId,
      'stock_item': instance.stockItem?.toJson(),
      'unit_cost': instance.unitCost,
      'total_cost': instance.totalCost,
      'stock_movement_id': instance.stockMovementId,
    };

_ArrivalRef _$ArrivalRefFromJson(Map<String, dynamic> json) =>
    _ArrivalRef(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$ArrivalRefToJson(_ArrivalRef instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
