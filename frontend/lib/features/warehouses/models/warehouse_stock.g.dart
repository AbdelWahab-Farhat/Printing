// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WarehouseStock _$WarehouseStockFromJson(Map<String, dynamic> json) =>
    _WarehouseStock(
      id: (json['id'] as num).toInt(),
      warehouseId: (json['warehouse_id'] as num).toInt(),
      stockItemId: (json['stock_item_id'] as num).toInt(),
      quantity: json['quantity'] as String,
      unit: json['unit'] as String,
      unitLabel: json['unit_label'] as String,
      lowStockThreshold: json['low_stock_threshold'] as String?,
      isLowStock: json['is_low_stock'] as bool? ?? false,
      item: json['stock_item'] == null
          ? null
          : StockItemRef.fromJson(json['stock_item'] as Map<String, dynamic>),
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
      'stock_item_id': instance.stockItemId,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'unit_label': instance.unitLabel,
      'low_stock_threshold': instance.lowStockThreshold,
      'is_low_stock': instance.isLowStock,
      'stock_item': instance.item?.toJson(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

_StockItemRef _$StockItemRefFromJson(Map<String, dynamic> json) =>
    _StockItemRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      widthCm: (json['width_cm'] as num?)?.toInt(),
      heightCm: (json['height_cm'] as num?)?.toInt(),
      displayName: json['display_name'] as String,
    );

Map<String, dynamic> _$StockItemRefToJson(_StockItemRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'width_cm': instance.widthCm,
      'height_cm': instance.heightCm,
      'display_name': instance.displayName,
    };
