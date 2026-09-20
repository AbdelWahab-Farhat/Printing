// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'returned_goods_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReturnedGoodsQuestion _$ReturnedGoodsQuestionFromJson(
  Map<String, dynamic> json,
) => _ReturnedGoodsQuestion(
  id: (json['id'] as num).toInt(),
  investmentPoolId: (json['investment_pool_id'] as num).toInt(),
  orderId: (json['order_id'] as num).toInt(),
  orderItemId: (json['order_item_id'] as num).toInt(),
  orderCode: json['order_code'] as String?,
  stockItemId: (json['stock_item_id'] as num).toInt(),
  stockItemName: json['stock_item_name'] as String?,
  quantity: json['quantity'] as String,
  cost: json['cost'] as String,
  verdict: json['verdict'] as String,
  verdictLabel: json['verdict_label'] as String,
  isOpen: json['is_open'] as bool? ?? true,
  answeredAt: json['answered_at'] as String?,
  answeredBy: (json['answered_by'] as num?)?.toInt(),
  answeredByName: json['answered_by_name'] as String?,
  damageMovementId: (json['damage_movement_id'] as num?)?.toInt(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ReturnedGoodsQuestionToJson(
  _ReturnedGoodsQuestion instance,
) => <String, dynamic>{
  'id': instance.id,
  'investment_pool_id': instance.investmentPoolId,
  'order_id': instance.orderId,
  'order_item_id': instance.orderItemId,
  'order_code': instance.orderCode,
  'stock_item_id': instance.stockItemId,
  'stock_item_name': instance.stockItemName,
  'quantity': instance.quantity,
  'cost': instance.cost,
  'verdict': instance.verdict,
  'verdict_label': instance.verdictLabel,
  'is_open': instance.isOpen,
  'answered_at': instance.answeredAt,
  'answered_by': instance.answeredBy,
  'answered_by_name': instance.answeredByName,
  'damage_movement_id': instance.damageMovementId,
  'notes': instance.notes,
};
