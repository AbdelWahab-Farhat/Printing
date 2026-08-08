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
      productVariantId: (json['product_variant_id'] as num).toInt(),
      variant: json['product_variant'] == null
          ? null
          : StockVariant.fromJson(
              json['product_variant'] as Map<String, dynamic>,
            ),
      stockMovementId: (json['stock_movement_id'] as num).toInt(),
    );

Map<String, dynamic> _$StockArrivalItemToJson(_StockArrivalItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
      'product_variant_id': instance.productVariantId,
      'product_variant': instance.variant?.toJson(),
      'stock_movement_id': instance.stockMovementId,
    };

_ArrivalRef _$ArrivalRefFromJson(Map<String, dynamic> json) =>
    _ArrivalRef(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$ArrivalRefToJson(_ArrivalRef instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
