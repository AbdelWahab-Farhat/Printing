// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockBatch _$StockBatchFromJson(Map<String, dynamic> json) => _StockBatch(
  id: (json['id'] as num).toInt(),
  warehouseId: (json['warehouse_id'] as num).toInt(),
  stockItemId: (json['stock_item_id'] as num).toInt(),
  item: json['stock_item'] == null
      ? null
      : StockItemRef.fromJson(json['stock_item'] as Map<String, dynamic>),
  unitCost: json['unit_cost'] as String,
  quantityReceived: json['quantity_received'] as String,
  quantityRemaining: json['quantity_remaining'] as String,
  quantityConsumed: json['quantity_consumed'] as String,
  unit: json['unit'] as String,
  unitLabel: json['unit_label'] as String,
  investorDealId: (json['investor_deal_id'] as num?)?.toInt(),
  investorDealCode: json['investor_deal_code'] as String?,
  investorDealInvestors:
      (json['investor_deal_investors'] as List<dynamic>?)
          ?.map((e) => BatchFunder.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BatchFunder>[],
  sourceType: json['source_type'] as String,
  sourceTypeLabel: json['source_type_label'] as String,
  receivedAt: json['received_at'] == null
      ? null
      : DateTime.parse(json['received_at'] as String),
  revaluedAt: json['revalued_at'] == null
      ? null
      : DateTime.parse(json['revalued_at'] as String),
  stockMovementId: (json['stock_movement_id'] as num?)?.toInt(),
  purchaseOrderId: (json['purchase_order_id'] as num?)?.toInt(),
  splitFromBatchId: (json['split_from_batch_id'] as num?)?.toInt(),
  canBeRevalued: json['can_be_revalued'] as bool? ?? false,
  isPartlyConsumed: json['is_partly_consumed'] as bool? ?? false,
  isUncosted: json['is_uncosted'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$StockBatchToJson(_StockBatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'warehouse_id': instance.warehouseId,
      'stock_item_id': instance.stockItemId,
      'stock_item': instance.item?.toJson(),
      'unit_cost': instance.unitCost,
      'quantity_received': instance.quantityReceived,
      'quantity_remaining': instance.quantityRemaining,
      'quantity_consumed': instance.quantityConsumed,
      'unit': instance.unit,
      'unit_label': instance.unitLabel,
      'investor_deal_id': instance.investorDealId,
      'investor_deal_code': instance.investorDealCode,
      'investor_deal_investors': instance.investorDealInvestors
          .map((e) => e.toJson())
          .toList(),
      'source_type': instance.sourceType,
      'source_type_label': instance.sourceTypeLabel,
      'received_at': instance.receivedAt?.toIso8601String(),
      'revalued_at': instance.revaluedAt?.toIso8601String(),
      'stock_movement_id': instance.stockMovementId,
      'purchase_order_id': instance.purchaseOrderId,
      'split_from_batch_id': instance.splitFromBatchId,
      'can_be_revalued': instance.canBeRevalued,
      'is_partly_consumed': instance.isPartlyConsumed,
      'is_uncosted': instance.isUncosted,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_BatchFunder _$BatchFunderFromJson(Map<String, dynamic> json) => _BatchFunder(
  investorId: (json['investor_id'] as num).toInt(),
  name: json['name'] as String,
  committedAmount: json['committed_amount'] as String,
  sharePercent: json['share_percent'] as String,
);

Map<String, dynamic> _$BatchFunderToJson(_BatchFunder instance) =>
    <String, dynamic>{
      'investor_id': instance.investorId,
      'name': instance.name,
      'committed_amount': instance.committedAmount,
      'share_percent': instance.sharePercent,
    };
