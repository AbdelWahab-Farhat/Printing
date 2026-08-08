// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PurchaseOrder _$PurchaseOrderFromJson(Map<String, dynamic> json) =>
    _PurchaseOrder(
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
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <PurchaseOrderItem>[],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PurchaseOrderToJson(_PurchaseOrder instance) =>
    <String, dynamic>{
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

_PurchaseOrderItem _$PurchaseOrderItemFromJson(Map<String, dynamic> json) =>
    _PurchaseOrderItem(
      id: (json['id'] as num).toInt(),
      productVariantId: (json['product_variant_id'] as num).toInt(),
      variant: json['product_variant'] == null
          ? null
          : StockVariant.fromJson(
              json['product_variant'] as Map<String, dynamic>,
            ),
      quantityOrdered: json['quantity_ordered'] as String,
      quantityReceived: json['quantity_received'] as String,
      quantityRemaining: json['quantity_remaining'] as String,
    );

Map<String, dynamic> _$PurchaseOrderItemToJson(_PurchaseOrderItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_variant_id': instance.productVariantId,
      'product_variant': instance.variant?.toJson(),
      'quantity_ordered': instance.quantityOrdered,
      'quantity_received': instance.quantityReceived,
      'quantity_remaining': instance.quantityRemaining,
    };
