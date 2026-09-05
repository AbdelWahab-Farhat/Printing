// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_batch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockBatch {

 int get id;@JsonKey(name: 'warehouse_id') int get warehouseId;@JsonKey(name: 'stock_item_id') int get stockItemId;@JsonKey(name: 'stock_item') StockItemRef? get item;/// Money, as a string: it is summed, and must reach the screen exactly as stored.
@JsonKey(name: 'unit_cost') String get unitCost;@JsonKey(name: 'quantity_received') String get quantityReceived;@JsonKey(name: 'quantity_remaining') String get quantityRemaining;@JsonKey(name: 'quantity_consumed') String get quantityConsumed; String get unit;@JsonKey(name: 'unit_label') String get unitLabel;/// The deal whose money bought this layer, and its code — **null on the ordinary layer the
/// company paid for itself**, which is most of them. What makes «هل هذه الدفعة لمستثمر؟»
/// answerable on the shelf itself rather than by hunting through the deals.
@JsonKey(name: 'investor_deal_id') int? get investorDealId;@JsonKey(name: 'investor_deal_code') String? get investorDealCode;/// Who is in that deal and what each put in — so «مَن يملك هذه البضاعة؟» is answered on the
/// shelf rather than by opening the deal.
@JsonKey(name: 'investor_deal_investors') List<BatchFunder> get investorDealInvestors;@JsonKey(name: 'source_type') String get sourceType;@JsonKey(name: 'source_type_label') String get sourceTypeLabel;/// The FIFO key. Not [createdAt]: a layer relocated by a transfer keeps the age of the stock
/// it actually is, so goods do not get younger by moving shelves.
@JsonKey(name: 'received_at') DateTime? get receivedAt;@JsonKey(name: 'revalued_at') DateTime? get revaluedAt;@JsonKey(name: 'stock_movement_id') int? get stockMovementId;@JsonKey(name: 'purchase_order_id') int? get purchaseOrderId;@JsonKey(name: 'split_from_batch_id') int? get splitFromBatchId;@JsonKey(name: 'can_be_revalued') bool get canBeRevalued;@JsonKey(name: 'is_partly_consumed') bool get isPartlyConsumed;@JsonKey(name: 'is_uncosted') bool get isUncosted;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockBatchCopyWith<StockBatch> get copyWith => _$StockBatchCopyWithImpl<StockBatch>(this as StockBatch, _$identity);

  /// Serializes this StockBatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.item, item) || other.item == item)&&(identical(other.unitCost, unitCost) || other.unitCost == unitCost)&&(identical(other.quantityReceived, quantityReceived) || other.quantityReceived == quantityReceived)&&(identical(other.quantityRemaining, quantityRemaining) || other.quantityRemaining == quantityRemaining)&&(identical(other.quantityConsumed, quantityConsumed) || other.quantityConsumed == quantityConsumed)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.investorDealId, investorDealId) || other.investorDealId == investorDealId)&&(identical(other.investorDealCode, investorDealCode) || other.investorDealCode == investorDealCode)&&const DeepCollectionEquality().equals(other.investorDealInvestors, investorDealInvestors)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.sourceTypeLabel, sourceTypeLabel) || other.sourceTypeLabel == sourceTypeLabel)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.revaluedAt, revaluedAt) || other.revaluedAt == revaluedAt)&&(identical(other.stockMovementId, stockMovementId) || other.stockMovementId == stockMovementId)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.splitFromBatchId, splitFromBatchId) || other.splitFromBatchId == splitFromBatchId)&&(identical(other.canBeRevalued, canBeRevalued) || other.canBeRevalued == canBeRevalued)&&(identical(other.isPartlyConsumed, isPartlyConsumed) || other.isPartlyConsumed == isPartlyConsumed)&&(identical(other.isUncosted, isUncosted) || other.isUncosted == isUncosted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,warehouseId,stockItemId,item,unitCost,quantityReceived,quantityRemaining,quantityConsumed,unit,unitLabel,investorDealId,investorDealCode,const DeepCollectionEquality().hash(investorDealInvestors),sourceType,sourceTypeLabel,receivedAt,revaluedAt,stockMovementId,purchaseOrderId,splitFromBatchId,canBeRevalued,isPartlyConsumed,isUncosted,createdAt]);

@override
String toString() {
  return 'StockBatch(id: $id, warehouseId: $warehouseId, stockItemId: $stockItemId, item: $item, unitCost: $unitCost, quantityReceived: $quantityReceived, quantityRemaining: $quantityRemaining, quantityConsumed: $quantityConsumed, unit: $unit, unitLabel: $unitLabel, investorDealId: $investorDealId, investorDealCode: $investorDealCode, investorDealInvestors: $investorDealInvestors, sourceType: $sourceType, sourceTypeLabel: $sourceTypeLabel, receivedAt: $receivedAt, revaluedAt: $revaluedAt, stockMovementId: $stockMovementId, purchaseOrderId: $purchaseOrderId, splitFromBatchId: $splitFromBatchId, canBeRevalued: $canBeRevalued, isPartlyConsumed: $isPartlyConsumed, isUncosted: $isUncosted, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StockBatchCopyWith<$Res>  {
  factory $StockBatchCopyWith(StockBatch value, $Res Function(StockBatch) _then) = _$StockBatchCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'warehouse_id') int warehouseId,@JsonKey(name: 'stock_item_id') int stockItemId,@JsonKey(name: 'stock_item') StockItemRef? item,@JsonKey(name: 'unit_cost') String unitCost,@JsonKey(name: 'quantity_received') String quantityReceived,@JsonKey(name: 'quantity_remaining') String quantityRemaining,@JsonKey(name: 'quantity_consumed') String quantityConsumed, String unit,@JsonKey(name: 'unit_label') String unitLabel,@JsonKey(name: 'investor_deal_id') int? investorDealId,@JsonKey(name: 'investor_deal_code') String? investorDealCode,@JsonKey(name: 'investor_deal_investors') List<BatchFunder> investorDealInvestors,@JsonKey(name: 'source_type') String sourceType,@JsonKey(name: 'source_type_label') String sourceTypeLabel,@JsonKey(name: 'received_at') DateTime? receivedAt,@JsonKey(name: 'revalued_at') DateTime? revaluedAt,@JsonKey(name: 'stock_movement_id') int? stockMovementId,@JsonKey(name: 'purchase_order_id') int? purchaseOrderId,@JsonKey(name: 'split_from_batch_id') int? splitFromBatchId,@JsonKey(name: 'can_be_revalued') bool canBeRevalued,@JsonKey(name: 'is_partly_consumed') bool isPartlyConsumed,@JsonKey(name: 'is_uncosted') bool isUncosted,@JsonKey(name: 'created_at') DateTime? createdAt
});


$StockItemRefCopyWith<$Res>? get item;

}
/// @nodoc
class _$StockBatchCopyWithImpl<$Res>
    implements $StockBatchCopyWith<$Res> {
  _$StockBatchCopyWithImpl(this._self, this._then);

  final StockBatch _self;
  final $Res Function(StockBatch) _then;

/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? warehouseId = null,Object? stockItemId = null,Object? item = freezed,Object? unitCost = null,Object? quantityReceived = null,Object? quantityRemaining = null,Object? quantityConsumed = null,Object? unit = null,Object? unitLabel = null,Object? investorDealId = freezed,Object? investorDealCode = freezed,Object? investorDealInvestors = null,Object? sourceType = null,Object? sourceTypeLabel = null,Object? receivedAt = freezed,Object? revaluedAt = freezed,Object? stockMovementId = freezed,Object? purchaseOrderId = freezed,Object? splitFromBatchId = freezed,Object? canBeRevalued = null,Object? isPartlyConsumed = null,Object? isUncosted = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,warehouseId: null == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as StockItemRef?,unitCost: null == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as String,quantityReceived: null == quantityReceived ? _self.quantityReceived : quantityReceived // ignore: cast_nullable_to_non_nullable
as String,quantityRemaining: null == quantityRemaining ? _self.quantityRemaining : quantityRemaining // ignore: cast_nullable_to_non_nullable
as String,quantityConsumed: null == quantityConsumed ? _self.quantityConsumed : quantityConsumed // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,investorDealId: freezed == investorDealId ? _self.investorDealId : investorDealId // ignore: cast_nullable_to_non_nullable
as int?,investorDealCode: freezed == investorDealCode ? _self.investorDealCode : investorDealCode // ignore: cast_nullable_to_non_nullable
as String?,investorDealInvestors: null == investorDealInvestors ? _self.investorDealInvestors : investorDealInvestors // ignore: cast_nullable_to_non_nullable
as List<BatchFunder>,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String,sourceTypeLabel: null == sourceTypeLabel ? _self.sourceTypeLabel : sourceTypeLabel // ignore: cast_nullable_to_non_nullable
as String,receivedAt: freezed == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revaluedAt: freezed == revaluedAt ? _self.revaluedAt : revaluedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stockMovementId: freezed == stockMovementId ? _self.stockMovementId : stockMovementId // ignore: cast_nullable_to_non_nullable
as int?,purchaseOrderId: freezed == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as int?,splitFromBatchId: freezed == splitFromBatchId ? _self.splitFromBatchId : splitFromBatchId // ignore: cast_nullable_to_non_nullable
as int?,canBeRevalued: null == canBeRevalued ? _self.canBeRevalued : canBeRevalued // ignore: cast_nullable_to_non_nullable
as bool,isPartlyConsumed: null == isPartlyConsumed ? _self.isPartlyConsumed : isPartlyConsumed // ignore: cast_nullable_to_non_nullable
as bool,isUncosted: null == isUncosted ? _self.isUncosted : isUncosted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemRefCopyWith<$Res>? get item {
    if (_self.item == null) {
    return null;
  }

  return $StockItemRefCopyWith<$Res>(_self.item!, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}


/// Adds pattern-matching-related methods to [StockBatch].
extension StockBatchPatterns on StockBatch {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockBatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockBatch() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockBatch value)  $default,){
final _that = this;
switch (_that) {
case _StockBatch():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockBatch value)?  $default,){
final _that = this;
switch (_that) {
case _StockBatch() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'warehouse_id')  int warehouseId, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item')  StockItemRef? item, @JsonKey(name: 'unit_cost')  String unitCost, @JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining, @JsonKey(name: 'quantity_consumed')  String quantityConsumed,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'investor_deal_id')  int? investorDealId, @JsonKey(name: 'investor_deal_code')  String? investorDealCode, @JsonKey(name: 'investor_deal_investors')  List<BatchFunder> investorDealInvestors, @JsonKey(name: 'source_type')  String sourceType, @JsonKey(name: 'source_type_label')  String sourceTypeLabel, @JsonKey(name: 'received_at')  DateTime? receivedAt, @JsonKey(name: 'revalued_at')  DateTime? revaluedAt, @JsonKey(name: 'stock_movement_id')  int? stockMovementId, @JsonKey(name: 'purchase_order_id')  int? purchaseOrderId, @JsonKey(name: 'split_from_batch_id')  int? splitFromBatchId, @JsonKey(name: 'can_be_revalued')  bool canBeRevalued, @JsonKey(name: 'is_partly_consumed')  bool isPartlyConsumed, @JsonKey(name: 'is_uncosted')  bool isUncosted, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockBatch() when $default != null:
return $default(_that.id,_that.warehouseId,_that.stockItemId,_that.item,_that.unitCost,_that.quantityReceived,_that.quantityRemaining,_that.quantityConsumed,_that.unit,_that.unitLabel,_that.investorDealId,_that.investorDealCode,_that.investorDealInvestors,_that.sourceType,_that.sourceTypeLabel,_that.receivedAt,_that.revaluedAt,_that.stockMovementId,_that.purchaseOrderId,_that.splitFromBatchId,_that.canBeRevalued,_that.isPartlyConsumed,_that.isUncosted,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'warehouse_id')  int warehouseId, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item')  StockItemRef? item, @JsonKey(name: 'unit_cost')  String unitCost, @JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining, @JsonKey(name: 'quantity_consumed')  String quantityConsumed,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'investor_deal_id')  int? investorDealId, @JsonKey(name: 'investor_deal_code')  String? investorDealCode, @JsonKey(name: 'investor_deal_investors')  List<BatchFunder> investorDealInvestors, @JsonKey(name: 'source_type')  String sourceType, @JsonKey(name: 'source_type_label')  String sourceTypeLabel, @JsonKey(name: 'received_at')  DateTime? receivedAt, @JsonKey(name: 'revalued_at')  DateTime? revaluedAt, @JsonKey(name: 'stock_movement_id')  int? stockMovementId, @JsonKey(name: 'purchase_order_id')  int? purchaseOrderId, @JsonKey(name: 'split_from_batch_id')  int? splitFromBatchId, @JsonKey(name: 'can_be_revalued')  bool canBeRevalued, @JsonKey(name: 'is_partly_consumed')  bool isPartlyConsumed, @JsonKey(name: 'is_uncosted')  bool isUncosted, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _StockBatch():
return $default(_that.id,_that.warehouseId,_that.stockItemId,_that.item,_that.unitCost,_that.quantityReceived,_that.quantityRemaining,_that.quantityConsumed,_that.unit,_that.unitLabel,_that.investorDealId,_that.investorDealCode,_that.investorDealInvestors,_that.sourceType,_that.sourceTypeLabel,_that.receivedAt,_that.revaluedAt,_that.stockMovementId,_that.purchaseOrderId,_that.splitFromBatchId,_that.canBeRevalued,_that.isPartlyConsumed,_that.isUncosted,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'warehouse_id')  int warehouseId, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item')  StockItemRef? item, @JsonKey(name: 'unit_cost')  String unitCost, @JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining, @JsonKey(name: 'quantity_consumed')  String quantityConsumed,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'investor_deal_id')  int? investorDealId, @JsonKey(name: 'investor_deal_code')  String? investorDealCode, @JsonKey(name: 'investor_deal_investors')  List<BatchFunder> investorDealInvestors, @JsonKey(name: 'source_type')  String sourceType, @JsonKey(name: 'source_type_label')  String sourceTypeLabel, @JsonKey(name: 'received_at')  DateTime? receivedAt, @JsonKey(name: 'revalued_at')  DateTime? revaluedAt, @JsonKey(name: 'stock_movement_id')  int? stockMovementId, @JsonKey(name: 'purchase_order_id')  int? purchaseOrderId, @JsonKey(name: 'split_from_batch_id')  int? splitFromBatchId, @JsonKey(name: 'can_be_revalued')  bool canBeRevalued, @JsonKey(name: 'is_partly_consumed')  bool isPartlyConsumed, @JsonKey(name: 'is_uncosted')  bool isUncosted, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _StockBatch() when $default != null:
return $default(_that.id,_that.warehouseId,_that.stockItemId,_that.item,_that.unitCost,_that.quantityReceived,_that.quantityRemaining,_that.quantityConsumed,_that.unit,_that.unitLabel,_that.investorDealId,_that.investorDealCode,_that.investorDealInvestors,_that.sourceType,_that.sourceTypeLabel,_that.receivedAt,_that.revaluedAt,_that.stockMovementId,_that.purchaseOrderId,_that.splitFromBatchId,_that.canBeRevalued,_that.isPartlyConsumed,_that.isUncosted,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockBatch extends StockBatch {
  const _StockBatch({required this.id, @JsonKey(name: 'warehouse_id') required this.warehouseId, @JsonKey(name: 'stock_item_id') required this.stockItemId, @JsonKey(name: 'stock_item') this.item, @JsonKey(name: 'unit_cost') required this.unitCost, @JsonKey(name: 'quantity_received') required this.quantityReceived, @JsonKey(name: 'quantity_remaining') required this.quantityRemaining, @JsonKey(name: 'quantity_consumed') required this.quantityConsumed, required this.unit, @JsonKey(name: 'unit_label') required this.unitLabel, @JsonKey(name: 'investor_deal_id') this.investorDealId, @JsonKey(name: 'investor_deal_code') this.investorDealCode, @JsonKey(name: 'investor_deal_investors') final  List<BatchFunder> investorDealInvestors = const <BatchFunder>[], @JsonKey(name: 'source_type') required this.sourceType, @JsonKey(name: 'source_type_label') required this.sourceTypeLabel, @JsonKey(name: 'received_at') this.receivedAt, @JsonKey(name: 'revalued_at') this.revaluedAt, @JsonKey(name: 'stock_movement_id') this.stockMovementId, @JsonKey(name: 'purchase_order_id') this.purchaseOrderId, @JsonKey(name: 'split_from_batch_id') this.splitFromBatchId, @JsonKey(name: 'can_be_revalued') this.canBeRevalued = false, @JsonKey(name: 'is_partly_consumed') this.isPartlyConsumed = false, @JsonKey(name: 'is_uncosted') this.isUncosted = false, @JsonKey(name: 'created_at') this.createdAt}): _investorDealInvestors = investorDealInvestors,super._();
  factory _StockBatch.fromJson(Map<String, dynamic> json) => _$StockBatchFromJson(json);

@override final  int id;
@override@JsonKey(name: 'warehouse_id') final  int warehouseId;
@override@JsonKey(name: 'stock_item_id') final  int stockItemId;
@override@JsonKey(name: 'stock_item') final  StockItemRef? item;
/// Money, as a string: it is summed, and must reach the screen exactly as stored.
@override@JsonKey(name: 'unit_cost') final  String unitCost;
@override@JsonKey(name: 'quantity_received') final  String quantityReceived;
@override@JsonKey(name: 'quantity_remaining') final  String quantityRemaining;
@override@JsonKey(name: 'quantity_consumed') final  String quantityConsumed;
@override final  String unit;
@override@JsonKey(name: 'unit_label') final  String unitLabel;
/// The deal whose money bought this layer, and its code — **null on the ordinary layer the
/// company paid for itself**, which is most of them. What makes «هل هذه الدفعة لمستثمر؟»
/// answerable on the shelf itself rather than by hunting through the deals.
@override@JsonKey(name: 'investor_deal_id') final  int? investorDealId;
@override@JsonKey(name: 'investor_deal_code') final  String? investorDealCode;
/// Who is in that deal and what each put in — so «مَن يملك هذه البضاعة؟» is answered on the
/// shelf rather than by opening the deal.
 final  List<BatchFunder> _investorDealInvestors;
/// Who is in that deal and what each put in — so «مَن يملك هذه البضاعة؟» is answered on the
/// shelf rather than by opening the deal.
@override@JsonKey(name: 'investor_deal_investors') List<BatchFunder> get investorDealInvestors {
  if (_investorDealInvestors is EqualUnmodifiableListView) return _investorDealInvestors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_investorDealInvestors);
}

@override@JsonKey(name: 'source_type') final  String sourceType;
@override@JsonKey(name: 'source_type_label') final  String sourceTypeLabel;
/// The FIFO key. Not [createdAt]: a layer relocated by a transfer keeps the age of the stock
/// it actually is, so goods do not get younger by moving shelves.
@override@JsonKey(name: 'received_at') final  DateTime? receivedAt;
@override@JsonKey(name: 'revalued_at') final  DateTime? revaluedAt;
@override@JsonKey(name: 'stock_movement_id') final  int? stockMovementId;
@override@JsonKey(name: 'purchase_order_id') final  int? purchaseOrderId;
@override@JsonKey(name: 'split_from_batch_id') final  int? splitFromBatchId;
@override@JsonKey(name: 'can_be_revalued') final  bool canBeRevalued;
@override@JsonKey(name: 'is_partly_consumed') final  bool isPartlyConsumed;
@override@JsonKey(name: 'is_uncosted') final  bool isUncosted;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockBatchCopyWith<_StockBatch> get copyWith => __$StockBatchCopyWithImpl<_StockBatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockBatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.item, item) || other.item == item)&&(identical(other.unitCost, unitCost) || other.unitCost == unitCost)&&(identical(other.quantityReceived, quantityReceived) || other.quantityReceived == quantityReceived)&&(identical(other.quantityRemaining, quantityRemaining) || other.quantityRemaining == quantityRemaining)&&(identical(other.quantityConsumed, quantityConsumed) || other.quantityConsumed == quantityConsumed)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.investorDealId, investorDealId) || other.investorDealId == investorDealId)&&(identical(other.investorDealCode, investorDealCode) || other.investorDealCode == investorDealCode)&&const DeepCollectionEquality().equals(other._investorDealInvestors, _investorDealInvestors)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.sourceTypeLabel, sourceTypeLabel) || other.sourceTypeLabel == sourceTypeLabel)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.revaluedAt, revaluedAt) || other.revaluedAt == revaluedAt)&&(identical(other.stockMovementId, stockMovementId) || other.stockMovementId == stockMovementId)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.splitFromBatchId, splitFromBatchId) || other.splitFromBatchId == splitFromBatchId)&&(identical(other.canBeRevalued, canBeRevalued) || other.canBeRevalued == canBeRevalued)&&(identical(other.isPartlyConsumed, isPartlyConsumed) || other.isPartlyConsumed == isPartlyConsumed)&&(identical(other.isUncosted, isUncosted) || other.isUncosted == isUncosted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,warehouseId,stockItemId,item,unitCost,quantityReceived,quantityRemaining,quantityConsumed,unit,unitLabel,investorDealId,investorDealCode,const DeepCollectionEquality().hash(_investorDealInvestors),sourceType,sourceTypeLabel,receivedAt,revaluedAt,stockMovementId,purchaseOrderId,splitFromBatchId,canBeRevalued,isPartlyConsumed,isUncosted,createdAt]);

@override
String toString() {
  return 'StockBatch(id: $id, warehouseId: $warehouseId, stockItemId: $stockItemId, item: $item, unitCost: $unitCost, quantityReceived: $quantityReceived, quantityRemaining: $quantityRemaining, quantityConsumed: $quantityConsumed, unit: $unit, unitLabel: $unitLabel, investorDealId: $investorDealId, investorDealCode: $investorDealCode, investorDealInvestors: $investorDealInvestors, sourceType: $sourceType, sourceTypeLabel: $sourceTypeLabel, receivedAt: $receivedAt, revaluedAt: $revaluedAt, stockMovementId: $stockMovementId, purchaseOrderId: $purchaseOrderId, splitFromBatchId: $splitFromBatchId, canBeRevalued: $canBeRevalued, isPartlyConsumed: $isPartlyConsumed, isUncosted: $isUncosted, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StockBatchCopyWith<$Res> implements $StockBatchCopyWith<$Res> {
  factory _$StockBatchCopyWith(_StockBatch value, $Res Function(_StockBatch) _then) = __$StockBatchCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'warehouse_id') int warehouseId,@JsonKey(name: 'stock_item_id') int stockItemId,@JsonKey(name: 'stock_item') StockItemRef? item,@JsonKey(name: 'unit_cost') String unitCost,@JsonKey(name: 'quantity_received') String quantityReceived,@JsonKey(name: 'quantity_remaining') String quantityRemaining,@JsonKey(name: 'quantity_consumed') String quantityConsumed, String unit,@JsonKey(name: 'unit_label') String unitLabel,@JsonKey(name: 'investor_deal_id') int? investorDealId,@JsonKey(name: 'investor_deal_code') String? investorDealCode,@JsonKey(name: 'investor_deal_investors') List<BatchFunder> investorDealInvestors,@JsonKey(name: 'source_type') String sourceType,@JsonKey(name: 'source_type_label') String sourceTypeLabel,@JsonKey(name: 'received_at') DateTime? receivedAt,@JsonKey(name: 'revalued_at') DateTime? revaluedAt,@JsonKey(name: 'stock_movement_id') int? stockMovementId,@JsonKey(name: 'purchase_order_id') int? purchaseOrderId,@JsonKey(name: 'split_from_batch_id') int? splitFromBatchId,@JsonKey(name: 'can_be_revalued') bool canBeRevalued,@JsonKey(name: 'is_partly_consumed') bool isPartlyConsumed,@JsonKey(name: 'is_uncosted') bool isUncosted,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $StockItemRefCopyWith<$Res>? get item;

}
/// @nodoc
class __$StockBatchCopyWithImpl<$Res>
    implements _$StockBatchCopyWith<$Res> {
  __$StockBatchCopyWithImpl(this._self, this._then);

  final _StockBatch _self;
  final $Res Function(_StockBatch) _then;

/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? warehouseId = null,Object? stockItemId = null,Object? item = freezed,Object? unitCost = null,Object? quantityReceived = null,Object? quantityRemaining = null,Object? quantityConsumed = null,Object? unit = null,Object? unitLabel = null,Object? investorDealId = freezed,Object? investorDealCode = freezed,Object? investorDealInvestors = null,Object? sourceType = null,Object? sourceTypeLabel = null,Object? receivedAt = freezed,Object? revaluedAt = freezed,Object? stockMovementId = freezed,Object? purchaseOrderId = freezed,Object? splitFromBatchId = freezed,Object? canBeRevalued = null,Object? isPartlyConsumed = null,Object? isUncosted = null,Object? createdAt = freezed,}) {
  return _then(_StockBatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,warehouseId: null == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as StockItemRef?,unitCost: null == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as String,quantityReceived: null == quantityReceived ? _self.quantityReceived : quantityReceived // ignore: cast_nullable_to_non_nullable
as String,quantityRemaining: null == quantityRemaining ? _self.quantityRemaining : quantityRemaining // ignore: cast_nullable_to_non_nullable
as String,quantityConsumed: null == quantityConsumed ? _self.quantityConsumed : quantityConsumed // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,investorDealId: freezed == investorDealId ? _self.investorDealId : investorDealId // ignore: cast_nullable_to_non_nullable
as int?,investorDealCode: freezed == investorDealCode ? _self.investorDealCode : investorDealCode // ignore: cast_nullable_to_non_nullable
as String?,investorDealInvestors: null == investorDealInvestors ? _self._investorDealInvestors : investorDealInvestors // ignore: cast_nullable_to_non_nullable
as List<BatchFunder>,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String,sourceTypeLabel: null == sourceTypeLabel ? _self.sourceTypeLabel : sourceTypeLabel // ignore: cast_nullable_to_non_nullable
as String,receivedAt: freezed == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revaluedAt: freezed == revaluedAt ? _self.revaluedAt : revaluedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stockMovementId: freezed == stockMovementId ? _self.stockMovementId : stockMovementId // ignore: cast_nullable_to_non_nullable
as int?,purchaseOrderId: freezed == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as int?,splitFromBatchId: freezed == splitFromBatchId ? _self.splitFromBatchId : splitFromBatchId // ignore: cast_nullable_to_non_nullable
as int?,canBeRevalued: null == canBeRevalued ? _self.canBeRevalued : canBeRevalued // ignore: cast_nullable_to_non_nullable
as bool,isPartlyConsumed: null == isPartlyConsumed ? _self.isPartlyConsumed : isPartlyConsumed // ignore: cast_nullable_to_non_nullable
as bool,isUncosted: null == isUncosted ? _self.isUncosted : isUncosted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemRefCopyWith<$Res>? get item {
    if (_self.item == null) {
    return null;
  }

  return $StockItemRefCopyWith<$Res>(_self.item!, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}


/// @nodoc
mixin _$BatchFunder {

@JsonKey(name: 'investor_id') int get investorId; String get name;@JsonKey(name: 'committed_amount') String get committedAmount;@JsonKey(name: 'share_percent') String get sharePercent;
/// Create a copy of BatchFunder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchFunderCopyWith<BatchFunder> get copyWith => _$BatchFunderCopyWithImpl<BatchFunder>(this as BatchFunder, _$identity);

  /// Serializes this BatchFunder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BatchFunder&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.committedAmount, committedAmount) || other.committedAmount == committedAmount)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,committedAmount,sharePercent);

@override
String toString() {
  return 'BatchFunder(investorId: $investorId, name: $name, committedAmount: $committedAmount, sharePercent: $sharePercent)';
}


}

/// @nodoc
abstract mixin class $BatchFunderCopyWith<$Res>  {
  factory $BatchFunderCopyWith(BatchFunder value, $Res Function(BatchFunder) _then) = _$BatchFunderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name,@JsonKey(name: 'committed_amount') String committedAmount,@JsonKey(name: 'share_percent') String sharePercent
});




}
/// @nodoc
class _$BatchFunderCopyWithImpl<$Res>
    implements $BatchFunderCopyWith<$Res> {
  _$BatchFunderCopyWithImpl(this._self, this._then);

  final BatchFunder _self;
  final $Res Function(BatchFunder) _then;

/// Create a copy of BatchFunder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investorId = null,Object? name = null,Object? committedAmount = null,Object? sharePercent = null,}) {
  return _then(_self.copyWith(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,committedAmount: null == committedAmount ? _self.committedAmount : committedAmount // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BatchFunder].
extension BatchFunderPatterns on BatchFunder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BatchFunder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BatchFunder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BatchFunder value)  $default,){
final _that = this;
switch (_that) {
case _BatchFunder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BatchFunder value)?  $default,){
final _that = this;
switch (_that) {
case _BatchFunder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name, @JsonKey(name: 'committed_amount')  String committedAmount, @JsonKey(name: 'share_percent')  String sharePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BatchFunder() when $default != null:
return $default(_that.investorId,_that.name,_that.committedAmount,_that.sharePercent);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name, @JsonKey(name: 'committed_amount')  String committedAmount, @JsonKey(name: 'share_percent')  String sharePercent)  $default,) {final _that = this;
switch (_that) {
case _BatchFunder():
return $default(_that.investorId,_that.name,_that.committedAmount,_that.sharePercent);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_id')  int investorId,  String name, @JsonKey(name: 'committed_amount')  String committedAmount, @JsonKey(name: 'share_percent')  String sharePercent)?  $default,) {final _that = this;
switch (_that) {
case _BatchFunder() when $default != null:
return $default(_that.investorId,_that.name,_that.committedAmount,_that.sharePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BatchFunder extends BatchFunder {
  const _BatchFunder({@JsonKey(name: 'investor_id') required this.investorId, required this.name, @JsonKey(name: 'committed_amount') required this.committedAmount, @JsonKey(name: 'share_percent') required this.sharePercent}): super._();
  factory _BatchFunder.fromJson(Map<String, dynamic> json) => _$BatchFunderFromJson(json);

@override@JsonKey(name: 'investor_id') final  int investorId;
@override final  String name;
@override@JsonKey(name: 'committed_amount') final  String committedAmount;
@override@JsonKey(name: 'share_percent') final  String sharePercent;

/// Create a copy of BatchFunder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BatchFunderCopyWith<_BatchFunder> get copyWith => __$BatchFunderCopyWithImpl<_BatchFunder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BatchFunderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BatchFunder&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.committedAmount, committedAmount) || other.committedAmount == committedAmount)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,committedAmount,sharePercent);

@override
String toString() {
  return 'BatchFunder(investorId: $investorId, name: $name, committedAmount: $committedAmount, sharePercent: $sharePercent)';
}


}

/// @nodoc
abstract mixin class _$BatchFunderCopyWith<$Res> implements $BatchFunderCopyWith<$Res> {
  factory _$BatchFunderCopyWith(_BatchFunder value, $Res Function(_BatchFunder) _then) = __$BatchFunderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name,@JsonKey(name: 'committed_amount') String committedAmount,@JsonKey(name: 'share_percent') String sharePercent
});




}
/// @nodoc
class __$BatchFunderCopyWithImpl<$Res>
    implements _$BatchFunderCopyWith<$Res> {
  __$BatchFunderCopyWithImpl(this._self, this._then);

  final _BatchFunder _self;
  final $Res Function(_BatchFunder) _then;

/// Create a copy of BatchFunder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investorId = null,Object? name = null,Object? committedAmount = null,Object? sharePercent = null,}) {
  return _then(_BatchFunder(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,committedAmount: null == committedAmount ? _self.committedAmount : committedAmount // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
