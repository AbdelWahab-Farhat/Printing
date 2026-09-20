// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'returned_goods_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReturnedGoodsQuestion {

 int get id;@JsonKey(name: 'investment_pool_id') int get investmentPoolId;@JsonKey(name: 'order_id') int get orderId;@JsonKey(name: 'order_item_id') int get orderItemId;@JsonKey(name: 'order_code') String? get orderCode;@JsonKey(name: 'stock_item_id') int get stockItemId;@JsonKey(name: 'stock_item_name') String? get stockItemName; String get quantity;/// **What the answer is worth**, and the screen should show it: «تالفة» charges exactly this
/// to the pool and takes the goods off the shelf. The person answering is deciding a figure,
/// not ticking a box.
 String get cost;/// `open`, `good` or `damaged`.
 String get verdict;@JsonKey(name: 'verdict_label') String get verdictLabel;@JsonKey(name: 'is_open') bool get isOpen;@JsonKey(name: 'answered_at') String? get answeredAt;@JsonKey(name: 'answered_by') int? get answeredBy;@JsonKey(name: 'answered_by_name') String? get answeredByName;/// The difference between «we checked» and «something happened». «صالحة» leaves it null,
/// because the goods really are back and really are usable.
@JsonKey(name: 'damage_movement_id') int? get damageMovementId; String? get notes;
/// Create a copy of ReturnedGoodsQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReturnedGoodsQuestionCopyWith<ReturnedGoodsQuestion> get copyWith => _$ReturnedGoodsQuestionCopyWithImpl<ReturnedGoodsQuestion>(this as ReturnedGoodsQuestion, _$identity);

  /// Serializes this ReturnedGoodsQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReturnedGoodsQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.investmentPoolId, investmentPoolId) || other.investmentPoolId == investmentPoolId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderItemId, orderItemId) || other.orderItemId == orderItemId)&&(identical(other.orderCode, orderCode) || other.orderCode == orderCode)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.stockItemName, stockItemName) || other.stockItemName == stockItemName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.verdictLabel, verdictLabel) || other.verdictLabel == verdictLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.answeredAt, answeredAt) || other.answeredAt == answeredAt)&&(identical(other.answeredBy, answeredBy) || other.answeredBy == answeredBy)&&(identical(other.answeredByName, answeredByName) || other.answeredByName == answeredByName)&&(identical(other.damageMovementId, damageMovementId) || other.damageMovementId == damageMovementId)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investmentPoolId,orderId,orderItemId,orderCode,stockItemId,stockItemName,quantity,cost,verdict,verdictLabel,isOpen,answeredAt,answeredBy,answeredByName,damageMovementId,notes);

@override
String toString() {
  return 'ReturnedGoodsQuestion(id: $id, investmentPoolId: $investmentPoolId, orderId: $orderId, orderItemId: $orderItemId, orderCode: $orderCode, stockItemId: $stockItemId, stockItemName: $stockItemName, quantity: $quantity, cost: $cost, verdict: $verdict, verdictLabel: $verdictLabel, isOpen: $isOpen, answeredAt: $answeredAt, answeredBy: $answeredBy, answeredByName: $answeredByName, damageMovementId: $damageMovementId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ReturnedGoodsQuestionCopyWith<$Res>  {
  factory $ReturnedGoodsQuestionCopyWith(ReturnedGoodsQuestion value, $Res Function(ReturnedGoodsQuestion) _then) = _$ReturnedGoodsQuestionCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'investment_pool_id') int investmentPoolId,@JsonKey(name: 'order_id') int orderId,@JsonKey(name: 'order_item_id') int orderItemId,@JsonKey(name: 'order_code') String? orderCode,@JsonKey(name: 'stock_item_id') int stockItemId,@JsonKey(name: 'stock_item_name') String? stockItemName, String quantity, String cost, String verdict,@JsonKey(name: 'verdict_label') String verdictLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'answered_at') String? answeredAt,@JsonKey(name: 'answered_by') int? answeredBy,@JsonKey(name: 'answered_by_name') String? answeredByName,@JsonKey(name: 'damage_movement_id') int? damageMovementId, String? notes
});




}
/// @nodoc
class _$ReturnedGoodsQuestionCopyWithImpl<$Res>
    implements $ReturnedGoodsQuestionCopyWith<$Res> {
  _$ReturnedGoodsQuestionCopyWithImpl(this._self, this._then);

  final ReturnedGoodsQuestion _self;
  final $Res Function(ReturnedGoodsQuestion) _then;

/// Create a copy of ReturnedGoodsQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? investmentPoolId = null,Object? orderId = null,Object? orderItemId = null,Object? orderCode = freezed,Object? stockItemId = null,Object? stockItemName = freezed,Object? quantity = null,Object? cost = null,Object? verdict = null,Object? verdictLabel = null,Object? isOpen = null,Object? answeredAt = freezed,Object? answeredBy = freezed,Object? answeredByName = freezed,Object? damageMovementId = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investmentPoolId: null == investmentPoolId ? _self.investmentPoolId : investmentPoolId // ignore: cast_nullable_to_non_nullable
as int,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,orderItemId: null == orderItemId ? _self.orderItemId : orderItemId // ignore: cast_nullable_to_non_nullable
as int,orderCode: freezed == orderCode ? _self.orderCode : orderCode // ignore: cast_nullable_to_non_nullable
as String?,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,stockItemName: freezed == stockItemName ? _self.stockItemName : stockItemName // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as String,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as String,verdictLabel: null == verdictLabel ? _self.verdictLabel : verdictLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,answeredAt: freezed == answeredAt ? _self.answeredAt : answeredAt // ignore: cast_nullable_to_non_nullable
as String?,answeredBy: freezed == answeredBy ? _self.answeredBy : answeredBy // ignore: cast_nullable_to_non_nullable
as int?,answeredByName: freezed == answeredByName ? _self.answeredByName : answeredByName // ignore: cast_nullable_to_non_nullable
as String?,damageMovementId: freezed == damageMovementId ? _self.damageMovementId : damageMovementId // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReturnedGoodsQuestion].
extension ReturnedGoodsQuestionPatterns on ReturnedGoodsQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReturnedGoodsQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReturnedGoodsQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReturnedGoodsQuestion value)  $default,){
final _that = this;
switch (_that) {
case _ReturnedGoodsQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReturnedGoodsQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _ReturnedGoodsQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'order_id')  int orderId, @JsonKey(name: 'order_item_id')  int orderItemId, @JsonKey(name: 'order_code')  String? orderCode, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item_name')  String? stockItemName,  String quantity,  String cost,  String verdict, @JsonKey(name: 'verdict_label')  String verdictLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'answered_at')  String? answeredAt, @JsonKey(name: 'answered_by')  int? answeredBy, @JsonKey(name: 'answered_by_name')  String? answeredByName, @JsonKey(name: 'damage_movement_id')  int? damageMovementId,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReturnedGoodsQuestion() when $default != null:
return $default(_that.id,_that.investmentPoolId,_that.orderId,_that.orderItemId,_that.orderCode,_that.stockItemId,_that.stockItemName,_that.quantity,_that.cost,_that.verdict,_that.verdictLabel,_that.isOpen,_that.answeredAt,_that.answeredBy,_that.answeredByName,_that.damageMovementId,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'order_id')  int orderId, @JsonKey(name: 'order_item_id')  int orderItemId, @JsonKey(name: 'order_code')  String? orderCode, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item_name')  String? stockItemName,  String quantity,  String cost,  String verdict, @JsonKey(name: 'verdict_label')  String verdictLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'answered_at')  String? answeredAt, @JsonKey(name: 'answered_by')  int? answeredBy, @JsonKey(name: 'answered_by_name')  String? answeredByName, @JsonKey(name: 'damage_movement_id')  int? damageMovementId,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _ReturnedGoodsQuestion():
return $default(_that.id,_that.investmentPoolId,_that.orderId,_that.orderItemId,_that.orderCode,_that.stockItemId,_that.stockItemName,_that.quantity,_that.cost,_that.verdict,_that.verdictLabel,_that.isOpen,_that.answeredAt,_that.answeredBy,_that.answeredByName,_that.damageMovementId,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'order_id')  int orderId, @JsonKey(name: 'order_item_id')  int orderItemId, @JsonKey(name: 'order_code')  String? orderCode, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item_name')  String? stockItemName,  String quantity,  String cost,  String verdict, @JsonKey(name: 'verdict_label')  String verdictLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'answered_at')  String? answeredAt, @JsonKey(name: 'answered_by')  int? answeredBy, @JsonKey(name: 'answered_by_name')  String? answeredByName, @JsonKey(name: 'damage_movement_id')  int? damageMovementId,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _ReturnedGoodsQuestion() when $default != null:
return $default(_that.id,_that.investmentPoolId,_that.orderId,_that.orderItemId,_that.orderCode,_that.stockItemId,_that.stockItemName,_that.quantity,_that.cost,_that.verdict,_that.verdictLabel,_that.isOpen,_that.answeredAt,_that.answeredBy,_that.answeredByName,_that.damageMovementId,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReturnedGoodsQuestion implements ReturnedGoodsQuestion {
  const _ReturnedGoodsQuestion({required this.id, @JsonKey(name: 'investment_pool_id') required this.investmentPoolId, @JsonKey(name: 'order_id') required this.orderId, @JsonKey(name: 'order_item_id') required this.orderItemId, @JsonKey(name: 'order_code') this.orderCode, @JsonKey(name: 'stock_item_id') required this.stockItemId, @JsonKey(name: 'stock_item_name') this.stockItemName, required this.quantity, required this.cost, required this.verdict, @JsonKey(name: 'verdict_label') required this.verdictLabel, @JsonKey(name: 'is_open') this.isOpen = true, @JsonKey(name: 'answered_at') this.answeredAt, @JsonKey(name: 'answered_by') this.answeredBy, @JsonKey(name: 'answered_by_name') this.answeredByName, @JsonKey(name: 'damage_movement_id') this.damageMovementId, this.notes});
  factory _ReturnedGoodsQuestion.fromJson(Map<String, dynamic> json) => _$ReturnedGoodsQuestionFromJson(json);

@override final  int id;
@override@JsonKey(name: 'investment_pool_id') final  int investmentPoolId;
@override@JsonKey(name: 'order_id') final  int orderId;
@override@JsonKey(name: 'order_item_id') final  int orderItemId;
@override@JsonKey(name: 'order_code') final  String? orderCode;
@override@JsonKey(name: 'stock_item_id') final  int stockItemId;
@override@JsonKey(name: 'stock_item_name') final  String? stockItemName;
@override final  String quantity;
/// **What the answer is worth**, and the screen should show it: «تالفة» charges exactly this
/// to the pool and takes the goods off the shelf. The person answering is deciding a figure,
/// not ticking a box.
@override final  String cost;
/// `open`, `good` or `damaged`.
@override final  String verdict;
@override@JsonKey(name: 'verdict_label') final  String verdictLabel;
@override@JsonKey(name: 'is_open') final  bool isOpen;
@override@JsonKey(name: 'answered_at') final  String? answeredAt;
@override@JsonKey(name: 'answered_by') final  int? answeredBy;
@override@JsonKey(name: 'answered_by_name') final  String? answeredByName;
/// The difference between «we checked» and «something happened». «صالحة» leaves it null,
/// because the goods really are back and really are usable.
@override@JsonKey(name: 'damage_movement_id') final  int? damageMovementId;
@override final  String? notes;

/// Create a copy of ReturnedGoodsQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReturnedGoodsQuestionCopyWith<_ReturnedGoodsQuestion> get copyWith => __$ReturnedGoodsQuestionCopyWithImpl<_ReturnedGoodsQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReturnedGoodsQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReturnedGoodsQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.investmentPoolId, investmentPoolId) || other.investmentPoolId == investmentPoolId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderItemId, orderItemId) || other.orderItemId == orderItemId)&&(identical(other.orderCode, orderCode) || other.orderCode == orderCode)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.stockItemName, stockItemName) || other.stockItemName == stockItemName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.verdictLabel, verdictLabel) || other.verdictLabel == verdictLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.answeredAt, answeredAt) || other.answeredAt == answeredAt)&&(identical(other.answeredBy, answeredBy) || other.answeredBy == answeredBy)&&(identical(other.answeredByName, answeredByName) || other.answeredByName == answeredByName)&&(identical(other.damageMovementId, damageMovementId) || other.damageMovementId == damageMovementId)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investmentPoolId,orderId,orderItemId,orderCode,stockItemId,stockItemName,quantity,cost,verdict,verdictLabel,isOpen,answeredAt,answeredBy,answeredByName,damageMovementId,notes);

@override
String toString() {
  return 'ReturnedGoodsQuestion(id: $id, investmentPoolId: $investmentPoolId, orderId: $orderId, orderItemId: $orderItemId, orderCode: $orderCode, stockItemId: $stockItemId, stockItemName: $stockItemName, quantity: $quantity, cost: $cost, verdict: $verdict, verdictLabel: $verdictLabel, isOpen: $isOpen, answeredAt: $answeredAt, answeredBy: $answeredBy, answeredByName: $answeredByName, damageMovementId: $damageMovementId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ReturnedGoodsQuestionCopyWith<$Res> implements $ReturnedGoodsQuestionCopyWith<$Res> {
  factory _$ReturnedGoodsQuestionCopyWith(_ReturnedGoodsQuestion value, $Res Function(_ReturnedGoodsQuestion) _then) = __$ReturnedGoodsQuestionCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'investment_pool_id') int investmentPoolId,@JsonKey(name: 'order_id') int orderId,@JsonKey(name: 'order_item_id') int orderItemId,@JsonKey(name: 'order_code') String? orderCode,@JsonKey(name: 'stock_item_id') int stockItemId,@JsonKey(name: 'stock_item_name') String? stockItemName, String quantity, String cost, String verdict,@JsonKey(name: 'verdict_label') String verdictLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'answered_at') String? answeredAt,@JsonKey(name: 'answered_by') int? answeredBy,@JsonKey(name: 'answered_by_name') String? answeredByName,@JsonKey(name: 'damage_movement_id') int? damageMovementId, String? notes
});




}
/// @nodoc
class __$ReturnedGoodsQuestionCopyWithImpl<$Res>
    implements _$ReturnedGoodsQuestionCopyWith<$Res> {
  __$ReturnedGoodsQuestionCopyWithImpl(this._self, this._then);

  final _ReturnedGoodsQuestion _self;
  final $Res Function(_ReturnedGoodsQuestion) _then;

/// Create a copy of ReturnedGoodsQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? investmentPoolId = null,Object? orderId = null,Object? orderItemId = null,Object? orderCode = freezed,Object? stockItemId = null,Object? stockItemName = freezed,Object? quantity = null,Object? cost = null,Object? verdict = null,Object? verdictLabel = null,Object? isOpen = null,Object? answeredAt = freezed,Object? answeredBy = freezed,Object? answeredByName = freezed,Object? damageMovementId = freezed,Object? notes = freezed,}) {
  return _then(_ReturnedGoodsQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investmentPoolId: null == investmentPoolId ? _self.investmentPoolId : investmentPoolId // ignore: cast_nullable_to_non_nullable
as int,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,orderItemId: null == orderItemId ? _self.orderItemId : orderItemId // ignore: cast_nullable_to_non_nullable
as int,orderCode: freezed == orderCode ? _self.orderCode : orderCode // ignore: cast_nullable_to_non_nullable
as String?,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,stockItemName: freezed == stockItemName ? _self.stockItemName : stockItemName // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as String,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as String,verdictLabel: null == verdictLabel ? _self.verdictLabel : verdictLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,answeredAt: freezed == answeredAt ? _self.answeredAt : answeredAt // ignore: cast_nullable_to_non_nullable
as String?,answeredBy: freezed == answeredBy ? _self.answeredBy : answeredBy // ignore: cast_nullable_to_non_nullable
as int?,answeredByName: freezed == answeredByName ? _self.answeredByName : answeredByName // ignore: cast_nullable_to_non_nullable
as String?,damageMovementId: freezed == damageMovementId ? _self.damageMovementId : damageMovementId // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
