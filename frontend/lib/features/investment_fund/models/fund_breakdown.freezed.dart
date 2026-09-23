// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FundCashEntry {

 int get id; String get type;@JsonKey(name: 'type_label') String get typeLabel;/// أدخل هذا الصفُّ مالاً أم أخرجه — من نوعه في الخادم، لا من إشارةٍ تُخمَّن هنا.
@JsonKey(name: 'is_inflow') bool get isInflow;/// المبلغُ بإشارته: «-3000.00» لما خرج.
@JsonKey(name: 'signed_amount') String get signedAmount;/// ما بقي في الخزينة بعد هذا الصفّ — يُحسب في الخادم على الدفتر كلِّه، فالصفحةُ الثانية لا
/// تبدأ من صفر.
@JsonKey(name: 'balance_after') String get balanceAfter;@JsonKey(name: 'occurred_at') DateTime? get occurredAt;/// «طلبية ORD-12 · محمد»، «أمر شراء #3 · مصنع الأكياس»، «عبدالرحمن» — يبنيه الخادم.
 String? get description;/// إلى أين تُفتح الحركة، إن كان لها بابٌ في التطبيق.
@JsonKey(name: 'order_id') int? get orderId;@JsonKey(name: 'purchase_order_id') int? get purchaseOrderId;@JsonKey(name: 'investor_id') int? get investorId; String? get notes;
/// Create a copy of FundCashEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundCashEntryCopyWith<FundCashEntry> get copyWith => _$FundCashEntryCopyWithImpl<FundCashEntry>(this as FundCashEntry, _$identity);

  /// Serializes this FundCashEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundCashEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.isInflow, isInflow) || other.isInflow == isInflow)&&(identical(other.signedAmount, signedAmount) || other.signedAmount == signedAmount)&&(identical(other.balanceAfter, balanceAfter) || other.balanceAfter == balanceAfter)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,typeLabel,isInflow,signedAmount,balanceAfter,occurredAt,description,orderId,purchaseOrderId,investorId,notes);

@override
String toString() {
  return 'FundCashEntry(id: $id, type: $type, typeLabel: $typeLabel, isInflow: $isInflow, signedAmount: $signedAmount, balanceAfter: $balanceAfter, occurredAt: $occurredAt, description: $description, orderId: $orderId, purchaseOrderId: $purchaseOrderId, investorId: $investorId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $FundCashEntryCopyWith<$Res>  {
  factory $FundCashEntryCopyWith(FundCashEntry value, $Res Function(FundCashEntry) _then) = _$FundCashEntryCopyWithImpl;
@useResult
$Res call({
 int id, String type,@JsonKey(name: 'type_label') String typeLabel,@JsonKey(name: 'is_inflow') bool isInflow,@JsonKey(name: 'signed_amount') String signedAmount,@JsonKey(name: 'balance_after') String balanceAfter,@JsonKey(name: 'occurred_at') DateTime? occurredAt, String? description,@JsonKey(name: 'order_id') int? orderId,@JsonKey(name: 'purchase_order_id') int? purchaseOrderId,@JsonKey(name: 'investor_id') int? investorId, String? notes
});




}
/// @nodoc
class _$FundCashEntryCopyWithImpl<$Res>
    implements $FundCashEntryCopyWith<$Res> {
  _$FundCashEntryCopyWithImpl(this._self, this._then);

  final FundCashEntry _self;
  final $Res Function(FundCashEntry) _then;

/// Create a copy of FundCashEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? typeLabel = null,Object? isInflow = null,Object? signedAmount = null,Object? balanceAfter = null,Object? occurredAt = freezed,Object? description = freezed,Object? orderId = freezed,Object? purchaseOrderId = freezed,Object? investorId = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,isInflow: null == isInflow ? _self.isInflow : isInflow // ignore: cast_nullable_to_non_nullable
as bool,signedAmount: null == signedAmount ? _self.signedAmount : signedAmount // ignore: cast_nullable_to_non_nullable
as String,balanceAfter: null == balanceAfter ? _self.balanceAfter : balanceAfter // ignore: cast_nullable_to_non_nullable
as String,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,purchaseOrderId: freezed == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as int?,investorId: freezed == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FundCashEntry].
extension FundCashEntryPatterns on FundCashEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundCashEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundCashEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundCashEntry value)  $default,){
final _that = this;
switch (_that) {
case _FundCashEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundCashEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FundCashEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel, @JsonKey(name: 'is_inflow')  bool isInflow, @JsonKey(name: 'signed_amount')  String signedAmount, @JsonKey(name: 'balance_after')  String balanceAfter, @JsonKey(name: 'occurred_at')  DateTime? occurredAt,  String? description, @JsonKey(name: 'order_id')  int? orderId, @JsonKey(name: 'purchase_order_id')  int? purchaseOrderId, @JsonKey(name: 'investor_id')  int? investorId,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundCashEntry() when $default != null:
return $default(_that.id,_that.type,_that.typeLabel,_that.isInflow,_that.signedAmount,_that.balanceAfter,_that.occurredAt,_that.description,_that.orderId,_that.purchaseOrderId,_that.investorId,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel, @JsonKey(name: 'is_inflow')  bool isInflow, @JsonKey(name: 'signed_amount')  String signedAmount, @JsonKey(name: 'balance_after')  String balanceAfter, @JsonKey(name: 'occurred_at')  DateTime? occurredAt,  String? description, @JsonKey(name: 'order_id')  int? orderId, @JsonKey(name: 'purchase_order_id')  int? purchaseOrderId, @JsonKey(name: 'investor_id')  int? investorId,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _FundCashEntry():
return $default(_that.id,_that.type,_that.typeLabel,_that.isInflow,_that.signedAmount,_that.balanceAfter,_that.occurredAt,_that.description,_that.orderId,_that.purchaseOrderId,_that.investorId,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel, @JsonKey(name: 'is_inflow')  bool isInflow, @JsonKey(name: 'signed_amount')  String signedAmount, @JsonKey(name: 'balance_after')  String balanceAfter, @JsonKey(name: 'occurred_at')  DateTime? occurredAt,  String? description, @JsonKey(name: 'order_id')  int? orderId, @JsonKey(name: 'purchase_order_id')  int? purchaseOrderId, @JsonKey(name: 'investor_id')  int? investorId,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _FundCashEntry() when $default != null:
return $default(_that.id,_that.type,_that.typeLabel,_that.isInflow,_that.signedAmount,_that.balanceAfter,_that.occurredAt,_that.description,_that.orderId,_that.purchaseOrderId,_that.investorId,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundCashEntry implements FundCashEntry {
  const _FundCashEntry({required this.id, required this.type, @JsonKey(name: 'type_label') required this.typeLabel, @JsonKey(name: 'is_inflow') required this.isInflow, @JsonKey(name: 'signed_amount') required this.signedAmount, @JsonKey(name: 'balance_after') required this.balanceAfter, @JsonKey(name: 'occurred_at') this.occurredAt, this.description, @JsonKey(name: 'order_id') this.orderId, @JsonKey(name: 'purchase_order_id') this.purchaseOrderId, @JsonKey(name: 'investor_id') this.investorId, this.notes});
  factory _FundCashEntry.fromJson(Map<String, dynamic> json) => _$FundCashEntryFromJson(json);

@override final  int id;
@override final  String type;
@override@JsonKey(name: 'type_label') final  String typeLabel;
/// أدخل هذا الصفُّ مالاً أم أخرجه — من نوعه في الخادم، لا من إشارةٍ تُخمَّن هنا.
@override@JsonKey(name: 'is_inflow') final  bool isInflow;
/// المبلغُ بإشارته: «-3000.00» لما خرج.
@override@JsonKey(name: 'signed_amount') final  String signedAmount;
/// ما بقي في الخزينة بعد هذا الصفّ — يُحسب في الخادم على الدفتر كلِّه، فالصفحةُ الثانية لا
/// تبدأ من صفر.
@override@JsonKey(name: 'balance_after') final  String balanceAfter;
@override@JsonKey(name: 'occurred_at') final  DateTime? occurredAt;
/// «طلبية ORD-12 · محمد»، «أمر شراء #3 · مصنع الأكياس»، «عبدالرحمن» — يبنيه الخادم.
@override final  String? description;
/// إلى أين تُفتح الحركة، إن كان لها بابٌ في التطبيق.
@override@JsonKey(name: 'order_id') final  int? orderId;
@override@JsonKey(name: 'purchase_order_id') final  int? purchaseOrderId;
@override@JsonKey(name: 'investor_id') final  int? investorId;
@override final  String? notes;

/// Create a copy of FundCashEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundCashEntryCopyWith<_FundCashEntry> get copyWith => __$FundCashEntryCopyWithImpl<_FundCashEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundCashEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundCashEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.isInflow, isInflow) || other.isInflow == isInflow)&&(identical(other.signedAmount, signedAmount) || other.signedAmount == signedAmount)&&(identical(other.balanceAfter, balanceAfter) || other.balanceAfter == balanceAfter)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,typeLabel,isInflow,signedAmount,balanceAfter,occurredAt,description,orderId,purchaseOrderId,investorId,notes);

@override
String toString() {
  return 'FundCashEntry(id: $id, type: $type, typeLabel: $typeLabel, isInflow: $isInflow, signedAmount: $signedAmount, balanceAfter: $balanceAfter, occurredAt: $occurredAt, description: $description, orderId: $orderId, purchaseOrderId: $purchaseOrderId, investorId: $investorId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$FundCashEntryCopyWith<$Res> implements $FundCashEntryCopyWith<$Res> {
  factory _$FundCashEntryCopyWith(_FundCashEntry value, $Res Function(_FundCashEntry) _then) = __$FundCashEntryCopyWithImpl;
@override @useResult
$Res call({
 int id, String type,@JsonKey(name: 'type_label') String typeLabel,@JsonKey(name: 'is_inflow') bool isInflow,@JsonKey(name: 'signed_amount') String signedAmount,@JsonKey(name: 'balance_after') String balanceAfter,@JsonKey(name: 'occurred_at') DateTime? occurredAt, String? description,@JsonKey(name: 'order_id') int? orderId,@JsonKey(name: 'purchase_order_id') int? purchaseOrderId,@JsonKey(name: 'investor_id') int? investorId, String? notes
});




}
/// @nodoc
class __$FundCashEntryCopyWithImpl<$Res>
    implements _$FundCashEntryCopyWith<$Res> {
  __$FundCashEntryCopyWithImpl(this._self, this._then);

  final _FundCashEntry _self;
  final $Res Function(_FundCashEntry) _then;

/// Create a copy of FundCashEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? typeLabel = null,Object? isInflow = null,Object? signedAmount = null,Object? balanceAfter = null,Object? occurredAt = freezed,Object? description = freezed,Object? orderId = freezed,Object? purchaseOrderId = freezed,Object? investorId = freezed,Object? notes = freezed,}) {
  return _then(_FundCashEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,isInflow: null == isInflow ? _self.isInflow : isInflow // ignore: cast_nullable_to_non_nullable
as bool,signedAmount: null == signedAmount ? _self.signedAmount : signedAmount // ignore: cast_nullable_to_non_nullable
as String,balanceAfter: null == balanceAfter ? _self.balanceAfter : balanceAfter // ignore: cast_nullable_to_non_nullable
as String,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,purchaseOrderId: freezed == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as int?,investorId: freezed == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FundShelfMaterial {

@JsonKey(name: 'stock_item_id') int? get stockItemId; String? get code; String? get name;@JsonKey(name: 'unit_label') String? get unitLabel; String get quantity;/// بالتكلفة المجمّدة يوم وصلت — ما يدخل به الرفُّ قيمةَ الصندوق.
 String get value; int get batches;
/// Create a copy of FundShelfMaterial
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundShelfMaterialCopyWith<FundShelfMaterial> get copyWith => _$FundShelfMaterialCopyWithImpl<FundShelfMaterial>(this as FundShelfMaterial, _$identity);

  /// Serializes this FundShelfMaterial to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundShelfMaterial&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.value, value) || other.value == value)&&(identical(other.batches, batches) || other.batches == batches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stockItemId,code,name,unitLabel,quantity,value,batches);

@override
String toString() {
  return 'FundShelfMaterial(stockItemId: $stockItemId, code: $code, name: $name, unitLabel: $unitLabel, quantity: $quantity, value: $value, batches: $batches)';
}


}

/// @nodoc
abstract mixin class $FundShelfMaterialCopyWith<$Res>  {
  factory $FundShelfMaterialCopyWith(FundShelfMaterial value, $Res Function(FundShelfMaterial) _then) = _$FundShelfMaterialCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'stock_item_id') int? stockItemId, String? code, String? name,@JsonKey(name: 'unit_label') String? unitLabel, String quantity, String value, int batches
});




}
/// @nodoc
class _$FundShelfMaterialCopyWithImpl<$Res>
    implements $FundShelfMaterialCopyWith<$Res> {
  _$FundShelfMaterialCopyWithImpl(this._self, this._then);

  final FundShelfMaterial _self;
  final $Res Function(FundShelfMaterial) _then;

/// Create a copy of FundShelfMaterial
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stockItemId = freezed,Object? code = freezed,Object? name = freezed,Object? unitLabel = freezed,Object? quantity = null,Object? value = null,Object? batches = null,}) {
  return _then(_self.copyWith(
stockItemId: freezed == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,batches: null == batches ? _self.batches : batches // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FundShelfMaterial].
extension FundShelfMaterialPatterns on FundShelfMaterial {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundShelfMaterial value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundShelfMaterial() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundShelfMaterial value)  $default,){
final _that = this;
switch (_that) {
case _FundShelfMaterial():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundShelfMaterial value)?  $default,){
final _that = this;
switch (_that) {
case _FundShelfMaterial() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'stock_item_id')  int? stockItemId,  String? code,  String? name, @JsonKey(name: 'unit_label')  String? unitLabel,  String quantity,  String value,  int batches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundShelfMaterial() when $default != null:
return $default(_that.stockItemId,_that.code,_that.name,_that.unitLabel,_that.quantity,_that.value,_that.batches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'stock_item_id')  int? stockItemId,  String? code,  String? name, @JsonKey(name: 'unit_label')  String? unitLabel,  String quantity,  String value,  int batches)  $default,) {final _that = this;
switch (_that) {
case _FundShelfMaterial():
return $default(_that.stockItemId,_that.code,_that.name,_that.unitLabel,_that.quantity,_that.value,_that.batches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'stock_item_id')  int? stockItemId,  String? code,  String? name, @JsonKey(name: 'unit_label')  String? unitLabel,  String quantity,  String value,  int batches)?  $default,) {final _that = this;
switch (_that) {
case _FundShelfMaterial() when $default != null:
return $default(_that.stockItemId,_that.code,_that.name,_that.unitLabel,_that.quantity,_that.value,_that.batches);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundShelfMaterial implements FundShelfMaterial {
  const _FundShelfMaterial({@JsonKey(name: 'stock_item_id') this.stockItemId, this.code, this.name, @JsonKey(name: 'unit_label') this.unitLabel, required this.quantity, required this.value, this.batches = 0});
  factory _FundShelfMaterial.fromJson(Map<String, dynamic> json) => _$FundShelfMaterialFromJson(json);

@override@JsonKey(name: 'stock_item_id') final  int? stockItemId;
@override final  String? code;
@override final  String? name;
@override@JsonKey(name: 'unit_label') final  String? unitLabel;
@override final  String quantity;
/// بالتكلفة المجمّدة يوم وصلت — ما يدخل به الرفُّ قيمةَ الصندوق.
@override final  String value;
@override@JsonKey() final  int batches;

/// Create a copy of FundShelfMaterial
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundShelfMaterialCopyWith<_FundShelfMaterial> get copyWith => __$FundShelfMaterialCopyWithImpl<_FundShelfMaterial>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundShelfMaterialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundShelfMaterial&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.value, value) || other.value == value)&&(identical(other.batches, batches) || other.batches == batches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stockItemId,code,name,unitLabel,quantity,value,batches);

@override
String toString() {
  return 'FundShelfMaterial(stockItemId: $stockItemId, code: $code, name: $name, unitLabel: $unitLabel, quantity: $quantity, value: $value, batches: $batches)';
}


}

/// @nodoc
abstract mixin class _$FundShelfMaterialCopyWith<$Res> implements $FundShelfMaterialCopyWith<$Res> {
  factory _$FundShelfMaterialCopyWith(_FundShelfMaterial value, $Res Function(_FundShelfMaterial) _then) = __$FundShelfMaterialCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'stock_item_id') int? stockItemId, String? code, String? name,@JsonKey(name: 'unit_label') String? unitLabel, String quantity, String value, int batches
});




}
/// @nodoc
class __$FundShelfMaterialCopyWithImpl<$Res>
    implements _$FundShelfMaterialCopyWith<$Res> {
  __$FundShelfMaterialCopyWithImpl(this._self, this._then);

  final _FundShelfMaterial _self;
  final $Res Function(_FundShelfMaterial) _then;

/// Create a copy of FundShelfMaterial
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stockItemId = freezed,Object? code = freezed,Object? name = freezed,Object? unitLabel = freezed,Object? quantity = null,Object? value = null,Object? batches = null,}) {
  return _then(_FundShelfMaterial(
stockItemId: freezed == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,batches: null == batches ? _self.batches : batches // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FundShelf {

/// رقمُ اللوحة بعينه، لا جمعُ الصفوف: كلُّ صفٍّ مقرَّبٌ لنفسه.
 String get total; List<FundShelfMaterial> get materials;
/// Create a copy of FundShelf
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundShelfCopyWith<FundShelf> get copyWith => _$FundShelfCopyWithImpl<FundShelf>(this as FundShelf, _$identity);

  /// Serializes this FundShelf to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundShelf&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.materials, materials));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(materials));

@override
String toString() {
  return 'FundShelf(total: $total, materials: $materials)';
}


}

/// @nodoc
abstract mixin class $FundShelfCopyWith<$Res>  {
  factory $FundShelfCopyWith(FundShelf value, $Res Function(FundShelf) _then) = _$FundShelfCopyWithImpl;
@useResult
$Res call({
 String total, List<FundShelfMaterial> materials
});




}
/// @nodoc
class _$FundShelfCopyWithImpl<$Res>
    implements $FundShelfCopyWith<$Res> {
  _$FundShelfCopyWithImpl(this._self, this._then);

  final FundShelf _self;
  final $Res Function(FundShelf) _then;

/// Create a copy of FundShelf
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? materials = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,materials: null == materials ? _self.materials : materials // ignore: cast_nullable_to_non_nullable
as List<FundShelfMaterial>,
  ));
}

}


/// Adds pattern-matching-related methods to [FundShelf].
extension FundShelfPatterns on FundShelf {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundShelf value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundShelf() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundShelf value)  $default,){
final _that = this;
switch (_that) {
case _FundShelf():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundShelf value)?  $default,){
final _that = this;
switch (_that) {
case _FundShelf() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String total,  List<FundShelfMaterial> materials)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundShelf() when $default != null:
return $default(_that.total,_that.materials);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String total,  List<FundShelfMaterial> materials)  $default,) {final _that = this;
switch (_that) {
case _FundShelf():
return $default(_that.total,_that.materials);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String total,  List<FundShelfMaterial> materials)?  $default,) {final _that = this;
switch (_that) {
case _FundShelf() when $default != null:
return $default(_that.total,_that.materials);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundShelf implements FundShelf {
  const _FundShelf({required this.total, final  List<FundShelfMaterial> materials = const <FundShelfMaterial>[]}): _materials = materials;
  factory _FundShelf.fromJson(Map<String, dynamic> json) => _$FundShelfFromJson(json);

/// رقمُ اللوحة بعينه، لا جمعُ الصفوف: كلُّ صفٍّ مقرَّبٌ لنفسه.
@override final  String total;
 final  List<FundShelfMaterial> _materials;
@override@JsonKey() List<FundShelfMaterial> get materials {
  if (_materials is EqualUnmodifiableListView) return _materials;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_materials);
}


/// Create a copy of FundShelf
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundShelfCopyWith<_FundShelf> get copyWith => __$FundShelfCopyWithImpl<_FundShelf>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundShelfToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundShelf&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._materials, _materials));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(_materials));

@override
String toString() {
  return 'FundShelf(total: $total, materials: $materials)';
}


}

/// @nodoc
abstract mixin class _$FundShelfCopyWith<$Res> implements $FundShelfCopyWith<$Res> {
  factory _$FundShelfCopyWith(_FundShelf value, $Res Function(_FundShelf) _then) = __$FundShelfCopyWithImpl;
@override @useResult
$Res call({
 String total, List<FundShelfMaterial> materials
});




}
/// @nodoc
class __$FundShelfCopyWithImpl<$Res>
    implements _$FundShelfCopyWith<$Res> {
  __$FundShelfCopyWithImpl(this._self, this._then);

  final _FundShelf _self;
  final $Res Function(_FundShelf) _then;

/// Create a copy of FundShelf
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? materials = null,}) {
  return _then(_FundShelf(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,materials: null == materials ? _self._materials : materials // ignore: cast_nullable_to_non_nullable
as List<FundShelfMaterial>,
  ));
}


}


/// @nodoc
mixin _$FundGoodsLine {

@JsonKey(name: 'stock_item_id') int? get stockItemId; String? get code; String? get name;@JsonKey(name: 'unit_label') String? get unitLabel; String get quantity; String get cost;
/// Create a copy of FundGoodsLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundGoodsLineCopyWith<FundGoodsLine> get copyWith => _$FundGoodsLineCopyWithImpl<FundGoodsLine>(this as FundGoodsLine, _$identity);

  /// Serializes this FundGoodsLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundGoodsLine&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.cost, cost) || other.cost == cost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stockItemId,code,name,unitLabel,quantity,cost);

@override
String toString() {
  return 'FundGoodsLine(stockItemId: $stockItemId, code: $code, name: $name, unitLabel: $unitLabel, quantity: $quantity, cost: $cost)';
}


}

/// @nodoc
abstract mixin class $FundGoodsLineCopyWith<$Res>  {
  factory $FundGoodsLineCopyWith(FundGoodsLine value, $Res Function(FundGoodsLine) _then) = _$FundGoodsLineCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'stock_item_id') int? stockItemId, String? code, String? name,@JsonKey(name: 'unit_label') String? unitLabel, String quantity, String cost
});




}
/// @nodoc
class _$FundGoodsLineCopyWithImpl<$Res>
    implements $FundGoodsLineCopyWith<$Res> {
  _$FundGoodsLineCopyWithImpl(this._self, this._then);

  final FundGoodsLine _self;
  final $Res Function(FundGoodsLine) _then;

/// Create a copy of FundGoodsLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stockItemId = freezed,Object? code = freezed,Object? name = freezed,Object? unitLabel = freezed,Object? quantity = null,Object? cost = null,}) {
  return _then(_self.copyWith(
stockItemId: freezed == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FundGoodsLine].
extension FundGoodsLinePatterns on FundGoodsLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundGoodsLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundGoodsLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundGoodsLine value)  $default,){
final _that = this;
switch (_that) {
case _FundGoodsLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundGoodsLine value)?  $default,){
final _that = this;
switch (_that) {
case _FundGoodsLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'stock_item_id')  int? stockItemId,  String? code,  String? name, @JsonKey(name: 'unit_label')  String? unitLabel,  String quantity,  String cost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundGoodsLine() when $default != null:
return $default(_that.stockItemId,_that.code,_that.name,_that.unitLabel,_that.quantity,_that.cost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'stock_item_id')  int? stockItemId,  String? code,  String? name, @JsonKey(name: 'unit_label')  String? unitLabel,  String quantity,  String cost)  $default,) {final _that = this;
switch (_that) {
case _FundGoodsLine():
return $default(_that.stockItemId,_that.code,_that.name,_that.unitLabel,_that.quantity,_that.cost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'stock_item_id')  int? stockItemId,  String? code,  String? name, @JsonKey(name: 'unit_label')  String? unitLabel,  String quantity,  String cost)?  $default,) {final _that = this;
switch (_that) {
case _FundGoodsLine() when $default != null:
return $default(_that.stockItemId,_that.code,_that.name,_that.unitLabel,_that.quantity,_that.cost);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundGoodsLine implements FundGoodsLine {
  const _FundGoodsLine({@JsonKey(name: 'stock_item_id') this.stockItemId, this.code, this.name, @JsonKey(name: 'unit_label') this.unitLabel, required this.quantity, required this.cost});
  factory _FundGoodsLine.fromJson(Map<String, dynamic> json) => _$FundGoodsLineFromJson(json);

@override@JsonKey(name: 'stock_item_id') final  int? stockItemId;
@override final  String? code;
@override final  String? name;
@override@JsonKey(name: 'unit_label') final  String? unitLabel;
@override final  String quantity;
@override final  String cost;

/// Create a copy of FundGoodsLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundGoodsLineCopyWith<_FundGoodsLine> get copyWith => __$FundGoodsLineCopyWithImpl<_FundGoodsLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundGoodsLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundGoodsLine&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.cost, cost) || other.cost == cost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stockItemId,code,name,unitLabel,quantity,cost);

@override
String toString() {
  return 'FundGoodsLine(stockItemId: $stockItemId, code: $code, name: $name, unitLabel: $unitLabel, quantity: $quantity, cost: $cost)';
}


}

/// @nodoc
abstract mixin class _$FundGoodsLineCopyWith<$Res> implements $FundGoodsLineCopyWith<$Res> {
  factory _$FundGoodsLineCopyWith(_FundGoodsLine value, $Res Function(_FundGoodsLine) _then) = __$FundGoodsLineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'stock_item_id') int? stockItemId, String? code, String? name,@JsonKey(name: 'unit_label') String? unitLabel, String quantity, String cost
});




}
/// @nodoc
class __$FundGoodsLineCopyWithImpl<$Res>
    implements _$FundGoodsLineCopyWith<$Res> {
  __$FundGoodsLineCopyWithImpl(this._self, this._then);

  final _FundGoodsLine _self;
  final $Res Function(_FundGoodsLine) _then;

/// Create a copy of FundGoodsLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stockItemId = freezed,Object? code = freezed,Object? name = freezed,Object? unitLabel = freezed,Object? quantity = null,Object? cost = null,}) {
  return _then(_FundGoodsLine(
stockItemId: freezed == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FundGoodsOrder {

@JsonKey(name: 'order_id') int get orderId; String get code; String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'customer_name') String? get customerName;@JsonKey(name: 'placed_at') DateTime? get placedAt;@JsonKey(name: 'delivered_at') DateTime? get deliveredAt;@JsonKey(name: 'grand_total') String get grandTotal;@JsonKey(name: 'paid_amount') String get paidAmount;/// ما بقي على العميل، لا أقلَّ من صفر.
 String get remaining;/// تكلفةُ بضاعة الصندوق فيها — ما تدخل به قيمتَه.
 String get cost; List<FundGoodsLine> get goods;
/// Create a copy of FundGoodsOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundGoodsOrderCopyWith<FundGoodsOrder> get copyWith => _$FundGoodsOrderCopyWithImpl<FundGoodsOrder>(this as FundGoodsOrder, _$identity);

  /// Serializes this FundGoodsOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundGoodsOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.cost, cost) || other.cost == cost)&&const DeepCollectionEquality().equals(other.goods, goods));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,code,status,statusLabel,customerName,placedAt,deliveredAt,grandTotal,paidAmount,remaining,cost,const DeepCollectionEquality().hash(goods));

@override
String toString() {
  return 'FundGoodsOrder(orderId: $orderId, code: $code, status: $status, statusLabel: $statusLabel, customerName: $customerName, placedAt: $placedAt, deliveredAt: $deliveredAt, grandTotal: $grandTotal, paidAmount: $paidAmount, remaining: $remaining, cost: $cost, goods: $goods)';
}


}

/// @nodoc
abstract mixin class $FundGoodsOrderCopyWith<$Res>  {
  factory $FundGoodsOrderCopyWith(FundGoodsOrder value, $Res Function(FundGoodsOrder) _then) = _$FundGoodsOrderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'order_id') int orderId, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'placed_at') DateTime? placedAt,@JsonKey(name: 'delivered_at') DateTime? deliveredAt,@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'paid_amount') String paidAmount, String remaining, String cost, List<FundGoodsLine> goods
});




}
/// @nodoc
class _$FundGoodsOrderCopyWithImpl<$Res>
    implements $FundGoodsOrderCopyWith<$Res> {
  _$FundGoodsOrderCopyWithImpl(this._self, this._then);

  final FundGoodsOrder _self;
  final $Res Function(FundGoodsOrder) _then;

/// Create a copy of FundGoodsOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? customerName = freezed,Object? placedAt = freezed,Object? deliveredAt = freezed,Object? grandTotal = null,Object? paidAmount = null,Object? remaining = null,Object? cost = null,Object? goods = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as String,goods: null == goods ? _self.goods : goods // ignore: cast_nullable_to_non_nullable
as List<FundGoodsLine>,
  ));
}

}


/// Adds pattern-matching-related methods to [FundGoodsOrder].
extension FundGoodsOrderPatterns on FundGoodsOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundGoodsOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundGoodsOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundGoodsOrder value)  $default,){
final _that = this;
switch (_that) {
case _FundGoodsOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundGoodsOrder value)?  $default,){
final _that = this;
switch (_that) {
case _FundGoodsOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'placed_at')  DateTime? placedAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'paid_amount')  String paidAmount,  String remaining,  String cost,  List<FundGoodsLine> goods)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundGoodsOrder() when $default != null:
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.placedAt,_that.deliveredAt,_that.grandTotal,_that.paidAmount,_that.remaining,_that.cost,_that.goods);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'placed_at')  DateTime? placedAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'paid_amount')  String paidAmount,  String remaining,  String cost,  List<FundGoodsLine> goods)  $default,) {final _that = this;
switch (_that) {
case _FundGoodsOrder():
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.placedAt,_that.deliveredAt,_that.grandTotal,_that.paidAmount,_that.remaining,_that.cost,_that.goods);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'placed_at')  DateTime? placedAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'paid_amount')  String paidAmount,  String remaining,  String cost,  List<FundGoodsLine> goods)?  $default,) {final _that = this;
switch (_that) {
case _FundGoodsOrder() when $default != null:
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.placedAt,_that.deliveredAt,_that.grandTotal,_that.paidAmount,_that.remaining,_that.cost,_that.goods);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundGoodsOrder implements FundGoodsOrder {
  const _FundGoodsOrder({@JsonKey(name: 'order_id') required this.orderId, required this.code, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'customer_name') this.customerName, @JsonKey(name: 'placed_at') this.placedAt, @JsonKey(name: 'delivered_at') this.deliveredAt, @JsonKey(name: 'grand_total') required this.grandTotal, @JsonKey(name: 'paid_amount') required this.paidAmount, required this.remaining, required this.cost, final  List<FundGoodsLine> goods = const <FundGoodsLine>[]}): _goods = goods;
  factory _FundGoodsOrder.fromJson(Map<String, dynamic> json) => _$FundGoodsOrderFromJson(json);

@override@JsonKey(name: 'order_id') final  int orderId;
@override final  String code;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'customer_name') final  String? customerName;
@override@JsonKey(name: 'placed_at') final  DateTime? placedAt;
@override@JsonKey(name: 'delivered_at') final  DateTime? deliveredAt;
@override@JsonKey(name: 'grand_total') final  String grandTotal;
@override@JsonKey(name: 'paid_amount') final  String paidAmount;
/// ما بقي على العميل، لا أقلَّ من صفر.
@override final  String remaining;
/// تكلفةُ بضاعة الصندوق فيها — ما تدخل به قيمتَه.
@override final  String cost;
 final  List<FundGoodsLine> _goods;
@override@JsonKey() List<FundGoodsLine> get goods {
  if (_goods is EqualUnmodifiableListView) return _goods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_goods);
}


/// Create a copy of FundGoodsOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundGoodsOrderCopyWith<_FundGoodsOrder> get copyWith => __$FundGoodsOrderCopyWithImpl<_FundGoodsOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundGoodsOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundGoodsOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.cost, cost) || other.cost == cost)&&const DeepCollectionEquality().equals(other._goods, _goods));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,code,status,statusLabel,customerName,placedAt,deliveredAt,grandTotal,paidAmount,remaining,cost,const DeepCollectionEquality().hash(_goods));

@override
String toString() {
  return 'FundGoodsOrder(orderId: $orderId, code: $code, status: $status, statusLabel: $statusLabel, customerName: $customerName, placedAt: $placedAt, deliveredAt: $deliveredAt, grandTotal: $grandTotal, paidAmount: $paidAmount, remaining: $remaining, cost: $cost, goods: $goods)';
}


}

/// @nodoc
abstract mixin class _$FundGoodsOrderCopyWith<$Res> implements $FundGoodsOrderCopyWith<$Res> {
  factory _$FundGoodsOrderCopyWith(_FundGoodsOrder value, $Res Function(_FundGoodsOrder) _then) = __$FundGoodsOrderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'order_id') int orderId, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'placed_at') DateTime? placedAt,@JsonKey(name: 'delivered_at') DateTime? deliveredAt,@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'paid_amount') String paidAmount, String remaining, String cost, List<FundGoodsLine> goods
});




}
/// @nodoc
class __$FundGoodsOrderCopyWithImpl<$Res>
    implements _$FundGoodsOrderCopyWith<$Res> {
  __$FundGoodsOrderCopyWithImpl(this._self, this._then);

  final _FundGoodsOrder _self;
  final $Res Function(_FundGoodsOrder) _then;

/// Create a copy of FundGoodsOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? customerName = freezed,Object? placedAt = freezed,Object? deliveredAt = freezed,Object? grandTotal = null,Object? paidAmount = null,Object? remaining = null,Object? cost = null,Object? goods = null,}) {
  return _then(_FundGoodsOrder(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as String,goods: null == goods ? _self._goods : goods // ignore: cast_nullable_to_non_nullable
as List<FundGoodsLine>,
  ));
}


}


/// @nodoc
mixin _$FundGoodsOut {

 String get total; List<FundGoodsOrder> get orders;
/// Create a copy of FundGoodsOut
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundGoodsOutCopyWith<FundGoodsOut> get copyWith => _$FundGoodsOutCopyWithImpl<FundGoodsOut>(this as FundGoodsOut, _$identity);

  /// Serializes this FundGoodsOut to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundGoodsOut&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.orders, orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(orders));

@override
String toString() {
  return 'FundGoodsOut(total: $total, orders: $orders)';
}


}

/// @nodoc
abstract mixin class $FundGoodsOutCopyWith<$Res>  {
  factory $FundGoodsOutCopyWith(FundGoodsOut value, $Res Function(FundGoodsOut) _then) = _$FundGoodsOutCopyWithImpl;
@useResult
$Res call({
 String total, List<FundGoodsOrder> orders
});




}
/// @nodoc
class _$FundGoodsOutCopyWithImpl<$Res>
    implements $FundGoodsOutCopyWith<$Res> {
  _$FundGoodsOutCopyWithImpl(this._self, this._then);

  final FundGoodsOut _self;
  final $Res Function(FundGoodsOut) _then;

/// Create a copy of FundGoodsOut
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? orders = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<FundGoodsOrder>,
  ));
}

}


/// Adds pattern-matching-related methods to [FundGoodsOut].
extension FundGoodsOutPatterns on FundGoodsOut {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundGoodsOut value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundGoodsOut() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundGoodsOut value)  $default,){
final _that = this;
switch (_that) {
case _FundGoodsOut():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundGoodsOut value)?  $default,){
final _that = this;
switch (_that) {
case _FundGoodsOut() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String total,  List<FundGoodsOrder> orders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundGoodsOut() when $default != null:
return $default(_that.total,_that.orders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String total,  List<FundGoodsOrder> orders)  $default,) {final _that = this;
switch (_that) {
case _FundGoodsOut():
return $default(_that.total,_that.orders);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String total,  List<FundGoodsOrder> orders)?  $default,) {final _that = this;
switch (_that) {
case _FundGoodsOut() when $default != null:
return $default(_that.total,_that.orders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundGoodsOut implements FundGoodsOut {
  const _FundGoodsOut({required this.total, final  List<FundGoodsOrder> orders = const <FundGoodsOrder>[]}): _orders = orders;
  factory _FundGoodsOut.fromJson(Map<String, dynamic> json) => _$FundGoodsOutFromJson(json);

@override final  String total;
 final  List<FundGoodsOrder> _orders;
@override@JsonKey() List<FundGoodsOrder> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}


/// Create a copy of FundGoodsOut
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundGoodsOutCopyWith<_FundGoodsOut> get copyWith => __$FundGoodsOutCopyWithImpl<_FundGoodsOut>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundGoodsOutToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundGoodsOut&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._orders, _orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(_orders));

@override
String toString() {
  return 'FundGoodsOut(total: $total, orders: $orders)';
}


}

/// @nodoc
abstract mixin class _$FundGoodsOutCopyWith<$Res> implements $FundGoodsOutCopyWith<$Res> {
  factory _$FundGoodsOutCopyWith(_FundGoodsOut value, $Res Function(_FundGoodsOut) _then) = __$FundGoodsOutCopyWithImpl;
@override @useResult
$Res call({
 String total, List<FundGoodsOrder> orders
});




}
/// @nodoc
class __$FundGoodsOutCopyWithImpl<$Res>
    implements _$FundGoodsOutCopyWith<$Res> {
  __$FundGoodsOutCopyWithImpl(this._self, this._then);

  final _FundGoodsOut _self;
  final $Res Function(_FundGoodsOut) _then;

/// Create a copy of FundGoodsOut
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? orders = null,}) {
  return _then(_FundGoodsOut(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<FundGoodsOrder>,
  ));
}


}


/// @nodoc
mixin _$FundProfitAdjustment {

 String get kind; String get label; String get amount;
/// Create a copy of FundProfitAdjustment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundProfitAdjustmentCopyWith<FundProfitAdjustment> get copyWith => _$FundProfitAdjustmentCopyWithImpl<FundProfitAdjustment>(this as FundProfitAdjustment, _$identity);

  /// Serializes this FundProfitAdjustment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundProfitAdjustment&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,label,amount);

@override
String toString() {
  return 'FundProfitAdjustment(kind: $kind, label: $label, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $FundProfitAdjustmentCopyWith<$Res>  {
  factory $FundProfitAdjustmentCopyWith(FundProfitAdjustment value, $Res Function(FundProfitAdjustment) _then) = _$FundProfitAdjustmentCopyWithImpl;
@useResult
$Res call({
 String kind, String label, String amount
});




}
/// @nodoc
class _$FundProfitAdjustmentCopyWithImpl<$Res>
    implements $FundProfitAdjustmentCopyWith<$Res> {
  _$FundProfitAdjustmentCopyWithImpl(this._self, this._then);

  final FundProfitAdjustment _self;
  final $Res Function(FundProfitAdjustment) _then;

/// Create a copy of FundProfitAdjustment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? label = null,Object? amount = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FundProfitAdjustment].
extension FundProfitAdjustmentPatterns on FundProfitAdjustment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundProfitAdjustment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundProfitAdjustment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundProfitAdjustment value)  $default,){
final _that = this;
switch (_that) {
case _FundProfitAdjustment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundProfitAdjustment value)?  $default,){
final _that = this;
switch (_that) {
case _FundProfitAdjustment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String label,  String amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundProfitAdjustment() when $default != null:
return $default(_that.kind,_that.label,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String label,  String amount)  $default,) {final _that = this;
switch (_that) {
case _FundProfitAdjustment():
return $default(_that.kind,_that.label,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String label,  String amount)?  $default,) {final _that = this;
switch (_that) {
case _FundProfitAdjustment() when $default != null:
return $default(_that.kind,_that.label,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundProfitAdjustment implements FundProfitAdjustment {
  const _FundProfitAdjustment({required this.kind, required this.label, required this.amount});
  factory _FundProfitAdjustment.fromJson(Map<String, dynamic> json) => _$FundProfitAdjustmentFromJson(json);

@override final  String kind;
@override final  String label;
@override final  String amount;

/// Create a copy of FundProfitAdjustment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundProfitAdjustmentCopyWith<_FundProfitAdjustment> get copyWith => __$FundProfitAdjustmentCopyWithImpl<_FundProfitAdjustment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundProfitAdjustmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundProfitAdjustment&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,label,amount);

@override
String toString() {
  return 'FundProfitAdjustment(kind: $kind, label: $label, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$FundProfitAdjustmentCopyWith<$Res> implements $FundProfitAdjustmentCopyWith<$Res> {
  factory _$FundProfitAdjustmentCopyWith(_FundProfitAdjustment value, $Res Function(_FundProfitAdjustment) _then) = __$FundProfitAdjustmentCopyWithImpl;
@override @useResult
$Res call({
 String kind, String label, String amount
});




}
/// @nodoc
class __$FundProfitAdjustmentCopyWithImpl<$Res>
    implements _$FundProfitAdjustmentCopyWith<$Res> {
  __$FundProfitAdjustmentCopyWithImpl(this._self, this._then);

  final _FundProfitAdjustment _self;
  final $Res Function(_FundProfitAdjustment) _then;

/// Create a copy of FundProfitAdjustment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? label = null,Object? amount = null,}) {
  return _then(_FundProfitAdjustment(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FundUnreleasedProfit {

 String get total;/// بطاقةُ شاشة الفترة نفسُها: رمزُ الطلبية، وحالتُها، ونصيبُ كلِّ شريكٍ منها.
 List<PeriodOrder> get orders; List<FundProfitAdjustment> get adjustments;
/// Create a copy of FundUnreleasedProfit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundUnreleasedProfitCopyWith<FundUnreleasedProfit> get copyWith => _$FundUnreleasedProfitCopyWithImpl<FundUnreleasedProfit>(this as FundUnreleasedProfit, _$identity);

  /// Serializes this FundUnreleasedProfit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundUnreleasedProfit&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.orders, orders)&&const DeepCollectionEquality().equals(other.adjustments, adjustments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(orders),const DeepCollectionEquality().hash(adjustments));

@override
String toString() {
  return 'FundUnreleasedProfit(total: $total, orders: $orders, adjustments: $adjustments)';
}


}

/// @nodoc
abstract mixin class $FundUnreleasedProfitCopyWith<$Res>  {
  factory $FundUnreleasedProfitCopyWith(FundUnreleasedProfit value, $Res Function(FundUnreleasedProfit) _then) = _$FundUnreleasedProfitCopyWithImpl;
@useResult
$Res call({
 String total, List<PeriodOrder> orders, List<FundProfitAdjustment> adjustments
});




}
/// @nodoc
class _$FundUnreleasedProfitCopyWithImpl<$Res>
    implements $FundUnreleasedProfitCopyWith<$Res> {
  _$FundUnreleasedProfitCopyWithImpl(this._self, this._then);

  final FundUnreleasedProfit _self;
  final $Res Function(FundUnreleasedProfit) _then;

/// Create a copy of FundUnreleasedProfit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? orders = null,Object? adjustments = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<PeriodOrder>,adjustments: null == adjustments ? _self.adjustments : adjustments // ignore: cast_nullable_to_non_nullable
as List<FundProfitAdjustment>,
  ));
}

}


/// Adds pattern-matching-related methods to [FundUnreleasedProfit].
extension FundUnreleasedProfitPatterns on FundUnreleasedProfit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundUnreleasedProfit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundUnreleasedProfit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundUnreleasedProfit value)  $default,){
final _that = this;
switch (_that) {
case _FundUnreleasedProfit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundUnreleasedProfit value)?  $default,){
final _that = this;
switch (_that) {
case _FundUnreleasedProfit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String total,  List<PeriodOrder> orders,  List<FundProfitAdjustment> adjustments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundUnreleasedProfit() when $default != null:
return $default(_that.total,_that.orders,_that.adjustments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String total,  List<PeriodOrder> orders,  List<FundProfitAdjustment> adjustments)  $default,) {final _that = this;
switch (_that) {
case _FundUnreleasedProfit():
return $default(_that.total,_that.orders,_that.adjustments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String total,  List<PeriodOrder> orders,  List<FundProfitAdjustment> adjustments)?  $default,) {final _that = this;
switch (_that) {
case _FundUnreleasedProfit() when $default != null:
return $default(_that.total,_that.orders,_that.adjustments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundUnreleasedProfit implements FundUnreleasedProfit {
  const _FundUnreleasedProfit({this.total = '0.00', final  List<PeriodOrder> orders = const <PeriodOrder>[], final  List<FundProfitAdjustment> adjustments = const <FundProfitAdjustment>[]}): _orders = orders,_adjustments = adjustments;
  factory _FundUnreleasedProfit.fromJson(Map<String, dynamic> json) => _$FundUnreleasedProfitFromJson(json);

@override@JsonKey() final  String total;
/// بطاقةُ شاشة الفترة نفسُها: رمزُ الطلبية، وحالتُها، ونصيبُ كلِّ شريكٍ منها.
 final  List<PeriodOrder> _orders;
/// بطاقةُ شاشة الفترة نفسُها: رمزُ الطلبية، وحالتُها، ونصيبُ كلِّ شريكٍ منها.
@override@JsonKey() List<PeriodOrder> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}

 final  List<FundProfitAdjustment> _adjustments;
@override@JsonKey() List<FundProfitAdjustment> get adjustments {
  if (_adjustments is EqualUnmodifiableListView) return _adjustments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_adjustments);
}


/// Create a copy of FundUnreleasedProfit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundUnreleasedProfitCopyWith<_FundUnreleasedProfit> get copyWith => __$FundUnreleasedProfitCopyWithImpl<_FundUnreleasedProfit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundUnreleasedProfitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundUnreleasedProfit&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._orders, _orders)&&const DeepCollectionEquality().equals(other._adjustments, _adjustments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(_orders),const DeepCollectionEquality().hash(_adjustments));

@override
String toString() {
  return 'FundUnreleasedProfit(total: $total, orders: $orders, adjustments: $adjustments)';
}


}

/// @nodoc
abstract mixin class _$FundUnreleasedProfitCopyWith<$Res> implements $FundUnreleasedProfitCopyWith<$Res> {
  factory _$FundUnreleasedProfitCopyWith(_FundUnreleasedProfit value, $Res Function(_FundUnreleasedProfit) _then) = __$FundUnreleasedProfitCopyWithImpl;
@override @useResult
$Res call({
 String total, List<PeriodOrder> orders, List<FundProfitAdjustment> adjustments
});




}
/// @nodoc
class __$FundUnreleasedProfitCopyWithImpl<$Res>
    implements _$FundUnreleasedProfitCopyWith<$Res> {
  __$FundUnreleasedProfitCopyWithImpl(this._self, this._then);

  final _FundUnreleasedProfit _self;
  final $Res Function(_FundUnreleasedProfit) _then;

/// Create a copy of FundUnreleasedProfit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? orders = null,Object? adjustments = null,}) {
  return _then(_FundUnreleasedProfit(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<PeriodOrder>,adjustments: null == adjustments ? _self._adjustments : adjustments // ignore: cast_nullable_to_non_nullable
as List<FundProfitAdjustment>,
  ));
}


}


/// @nodoc
mixin _$FundWalletProfit {

 String get total; List<PeriodInvestorShare> get investors;
/// Create a copy of FundWalletProfit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundWalletProfitCopyWith<FundWalletProfit> get copyWith => _$FundWalletProfitCopyWithImpl<FundWalletProfit>(this as FundWalletProfit, _$identity);

  /// Serializes this FundWalletProfit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundWalletProfit&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.investors, investors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(investors));

@override
String toString() {
  return 'FundWalletProfit(total: $total, investors: $investors)';
}


}

/// @nodoc
abstract mixin class $FundWalletProfitCopyWith<$Res>  {
  factory $FundWalletProfitCopyWith(FundWalletProfit value, $Res Function(FundWalletProfit) _then) = _$FundWalletProfitCopyWithImpl;
@useResult
$Res call({
 String total, List<PeriodInvestorShare> investors
});




}
/// @nodoc
class _$FundWalletProfitCopyWithImpl<$Res>
    implements $FundWalletProfitCopyWith<$Res> {
  _$FundWalletProfitCopyWithImpl(this._self, this._then);

  final FundWalletProfit _self;
  final $Res Function(FundWalletProfit) _then;

/// Create a copy of FundWalletProfit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? investors = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,investors: null == investors ? _self.investors : investors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,
  ));
}

}


/// Adds pattern-matching-related methods to [FundWalletProfit].
extension FundWalletProfitPatterns on FundWalletProfit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundWalletProfit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundWalletProfit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundWalletProfit value)  $default,){
final _that = this;
switch (_that) {
case _FundWalletProfit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundWalletProfit value)?  $default,){
final _that = this;
switch (_that) {
case _FundWalletProfit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String total,  List<PeriodInvestorShare> investors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundWalletProfit() when $default != null:
return $default(_that.total,_that.investors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String total,  List<PeriodInvestorShare> investors)  $default,) {final _that = this;
switch (_that) {
case _FundWalletProfit():
return $default(_that.total,_that.investors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String total,  List<PeriodInvestorShare> investors)?  $default,) {final _that = this;
switch (_that) {
case _FundWalletProfit() when $default != null:
return $default(_that.total,_that.investors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundWalletProfit implements FundWalletProfit {
  const _FundWalletProfit({this.total = '0.00', final  List<PeriodInvestorShare> investors = const <PeriodInvestorShare>[]}): _investors = investors;
  factory _FundWalletProfit.fromJson(Map<String, dynamic> json) => _$FundWalletProfitFromJson(json);

@override@JsonKey() final  String total;
 final  List<PeriodInvestorShare> _investors;
@override@JsonKey() List<PeriodInvestorShare> get investors {
  if (_investors is EqualUnmodifiableListView) return _investors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_investors);
}


/// Create a copy of FundWalletProfit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundWalletProfitCopyWith<_FundWalletProfit> get copyWith => __$FundWalletProfitCopyWithImpl<_FundWalletProfit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundWalletProfitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundWalletProfit&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._investors, _investors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(_investors));

@override
String toString() {
  return 'FundWalletProfit(total: $total, investors: $investors)';
}


}

/// @nodoc
abstract mixin class _$FundWalletProfitCopyWith<$Res> implements $FundWalletProfitCopyWith<$Res> {
  factory _$FundWalletProfitCopyWith(_FundWalletProfit value, $Res Function(_FundWalletProfit) _then) = __$FundWalletProfitCopyWithImpl;
@override @useResult
$Res call({
 String total, List<PeriodInvestorShare> investors
});




}
/// @nodoc
class __$FundWalletProfitCopyWithImpl<$Res>
    implements _$FundWalletProfitCopyWith<$Res> {
  __$FundWalletProfitCopyWithImpl(this._self, this._then);

  final _FundWalletProfit _self;
  final $Res Function(_FundWalletProfit) _then;

/// Create a copy of FundWalletProfit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? investors = null,}) {
  return _then(_FundWalletProfit(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,investors: null == investors ? _self._investors : investors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,
  ));
}


}


/// @nodoc
mixin _$FundProfitOwed {

 String get total; FundUnreleasedProfit get unreleased;@JsonKey(name: 'in_wallets') FundWalletProfit get inWallets;
/// Create a copy of FundProfitOwed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundProfitOwedCopyWith<FundProfitOwed> get copyWith => _$FundProfitOwedCopyWithImpl<FundProfitOwed>(this as FundProfitOwed, _$identity);

  /// Serializes this FundProfitOwed to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundProfitOwed&&(identical(other.total, total) || other.total == total)&&(identical(other.unreleased, unreleased) || other.unreleased == unreleased)&&(identical(other.inWallets, inWallets) || other.inWallets == inWallets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,unreleased,inWallets);

@override
String toString() {
  return 'FundProfitOwed(total: $total, unreleased: $unreleased, inWallets: $inWallets)';
}


}

/// @nodoc
abstract mixin class $FundProfitOwedCopyWith<$Res>  {
  factory $FundProfitOwedCopyWith(FundProfitOwed value, $Res Function(FundProfitOwed) _then) = _$FundProfitOwedCopyWithImpl;
@useResult
$Res call({
 String total, FundUnreleasedProfit unreleased,@JsonKey(name: 'in_wallets') FundWalletProfit inWallets
});


$FundUnreleasedProfitCopyWith<$Res> get unreleased;$FundWalletProfitCopyWith<$Res> get inWallets;

}
/// @nodoc
class _$FundProfitOwedCopyWithImpl<$Res>
    implements $FundProfitOwedCopyWith<$Res> {
  _$FundProfitOwedCopyWithImpl(this._self, this._then);

  final FundProfitOwed _self;
  final $Res Function(FundProfitOwed) _then;

/// Create a copy of FundProfitOwed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? unreleased = null,Object? inWallets = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,unreleased: null == unreleased ? _self.unreleased : unreleased // ignore: cast_nullable_to_non_nullable
as FundUnreleasedProfit,inWallets: null == inWallets ? _self.inWallets : inWallets // ignore: cast_nullable_to_non_nullable
as FundWalletProfit,
  ));
}
/// Create a copy of FundProfitOwed
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundUnreleasedProfitCopyWith<$Res> get unreleased {
  
  return $FundUnreleasedProfitCopyWith<$Res>(_self.unreleased, (value) {
    return _then(_self.copyWith(unreleased: value));
  });
}/// Create a copy of FundProfitOwed
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundWalletProfitCopyWith<$Res> get inWallets {
  
  return $FundWalletProfitCopyWith<$Res>(_self.inWallets, (value) {
    return _then(_self.copyWith(inWallets: value));
  });
}
}


/// Adds pattern-matching-related methods to [FundProfitOwed].
extension FundProfitOwedPatterns on FundProfitOwed {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundProfitOwed value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundProfitOwed() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundProfitOwed value)  $default,){
final _that = this;
switch (_that) {
case _FundProfitOwed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundProfitOwed value)?  $default,){
final _that = this;
switch (_that) {
case _FundProfitOwed() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String total,  FundUnreleasedProfit unreleased, @JsonKey(name: 'in_wallets')  FundWalletProfit inWallets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundProfitOwed() when $default != null:
return $default(_that.total,_that.unreleased,_that.inWallets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String total,  FundUnreleasedProfit unreleased, @JsonKey(name: 'in_wallets')  FundWalletProfit inWallets)  $default,) {final _that = this;
switch (_that) {
case _FundProfitOwed():
return $default(_that.total,_that.unreleased,_that.inWallets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String total,  FundUnreleasedProfit unreleased, @JsonKey(name: 'in_wallets')  FundWalletProfit inWallets)?  $default,) {final _that = this;
switch (_that) {
case _FundProfitOwed() when $default != null:
return $default(_that.total,_that.unreleased,_that.inWallets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundProfitOwed implements FundProfitOwed {
  const _FundProfitOwed({required this.total, this.unreleased = const FundUnreleasedProfit(), @JsonKey(name: 'in_wallets') this.inWallets = const FundWalletProfit()});
  factory _FundProfitOwed.fromJson(Map<String, dynamic> json) => _$FundProfitOwedFromJson(json);

@override final  String total;
@override@JsonKey() final  FundUnreleasedProfit unreleased;
@override@JsonKey(name: 'in_wallets') final  FundWalletProfit inWallets;

/// Create a copy of FundProfitOwed
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundProfitOwedCopyWith<_FundProfitOwed> get copyWith => __$FundProfitOwedCopyWithImpl<_FundProfitOwed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundProfitOwedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundProfitOwed&&(identical(other.total, total) || other.total == total)&&(identical(other.unreleased, unreleased) || other.unreleased == unreleased)&&(identical(other.inWallets, inWallets) || other.inWallets == inWallets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,unreleased,inWallets);

@override
String toString() {
  return 'FundProfitOwed(total: $total, unreleased: $unreleased, inWallets: $inWallets)';
}


}

/// @nodoc
abstract mixin class _$FundProfitOwedCopyWith<$Res> implements $FundProfitOwedCopyWith<$Res> {
  factory _$FundProfitOwedCopyWith(_FundProfitOwed value, $Res Function(_FundProfitOwed) _then) = __$FundProfitOwedCopyWithImpl;
@override @useResult
$Res call({
 String total, FundUnreleasedProfit unreleased,@JsonKey(name: 'in_wallets') FundWalletProfit inWallets
});


@override $FundUnreleasedProfitCopyWith<$Res> get unreleased;@override $FundWalletProfitCopyWith<$Res> get inWallets;

}
/// @nodoc
class __$FundProfitOwedCopyWithImpl<$Res>
    implements _$FundProfitOwedCopyWith<$Res> {
  __$FundProfitOwedCopyWithImpl(this._self, this._then);

  final _FundProfitOwed _self;
  final $Res Function(_FundProfitOwed) _then;

/// Create a copy of FundProfitOwed
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? unreleased = null,Object? inWallets = null,}) {
  return _then(_FundProfitOwed(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,unreleased: null == unreleased ? _self.unreleased : unreleased // ignore: cast_nullable_to_non_nullable
as FundUnreleasedProfit,inWallets: null == inWallets ? _self.inWallets : inWallets // ignore: cast_nullable_to_non_nullable
as FundWalletProfit,
  ));
}

/// Create a copy of FundProfitOwed
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundUnreleasedProfitCopyWith<$Res> get unreleased {
  
  return $FundUnreleasedProfitCopyWith<$Res>(_self.unreleased, (value) {
    return _then(_self.copyWith(unreleased: value));
  });
}/// Create a copy of FundProfitOwed
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundWalletProfitCopyWith<$Res> get inWallets {
  
  return $FundWalletProfitCopyWith<$Res>(_self.inWallets, (value) {
    return _then(_self.copyWith(inWallets: value));
  });
}
}

// dart format on
