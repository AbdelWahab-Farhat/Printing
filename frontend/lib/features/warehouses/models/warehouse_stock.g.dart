// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WarehouseStock _$WarehouseStockFromJson(Map<String, dynamic> json) =>
    _WarehouseStock(
      id: (json['id'] as num).toInt(),
      warehouseId: (json['warehouse_id'] as num).toInt(),
      productVariantId: (json['product_variant_id'] as num).toInt(),
      quantity: json['quantity'] as String,
      lowStockThreshold: json['low_stock_threshold'] as String?,
      isLowStock: json['is_low_stock'] as bool? ?? false,
      variant: json['product_variant'] == null
          ? null
          : StockVariant.fromJson(
              json['product_variant'] as Map<String, dynamic>,
            ),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$WarehouseStockToJson(_WarehouseStock instance) =>
    <String, dynamic>{
      'id': instance.id,
      'warehouse_id': instance.warehouseId,
      'product_variant_id': instance.productVariantId,
      'quantity': instance.quantity,
      'low_stock_threshold': instance.lowStockThreshold,
      'is_low_stock': instance.isLowStock,
      'product_variant': instance.variant?.toJson(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

_StockVariant _$StockVariantFromJson(Map<String, dynamic> json) =>
    _StockVariant(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String,
      productId: (json['product_id'] as num).toInt(),
      productName: json['product_name'] as String,
    );

Map<String, dynamic> _$StockVariantToJson(_StockVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'product_id': instance.productId,
      'product_name': instance.productName,
    };
