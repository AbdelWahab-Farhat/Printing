// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_stock_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WarehouseStockSummary _$WarehouseStockSummaryFromJson(
  Map<String, dynamic> json,
) => _WarehouseStockSummary(
  totalLines: (json['total_lines'] as num?)?.toInt() ?? 0,
  totalQuantity: json['total_quantity'] as String? ?? '0.000',
  lowStockCount: (json['low_stock_count'] as num?)?.toInt() ?? 0,
  outOfStockCount: (json['out_of_stock_count'] as num?)?.toInt() ?? 0,
  healthyCount: (json['healthy_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$WarehouseStockSummaryToJson(
  _WarehouseStockSummary instance,
) => <String, dynamic>{
  'total_lines': instance.totalLines,
  'total_quantity': instance.totalQuantity,
  'low_stock_count': instance.lowStockCount,
  'out_of_stock_count': instance.outOfStockCount,
  'healthy_count': instance.healthyCount,
};
