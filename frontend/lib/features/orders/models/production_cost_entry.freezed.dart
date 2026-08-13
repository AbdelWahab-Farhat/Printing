// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'production_cost_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductionCostEntry {

 int get id;@JsonKey(name: 'order_id') int get orderId;@JsonKey(name: 'order_item_id') int get orderItemId;/// `labor`, `machine_runtime`, `overhead` or `scrap_loss`.
///
/// A `String` rather than an enum, for the same reason an order step's `state` is one: it is
/// branched on nowhere and drawn nowhere — [costTypeLabel] is what a screen shows — and a
/// fifth kind added on the server should render as itself rather than fail to parse the
/// entry it belongs to.
@JsonKey(name: 'cost_type') String get costType;/// The server's own Arabic — «خسارة تلف». Rendered as-is, never mapped from [costType] here.
@JsonKey(name: 'cost_type_label') String get costTypeLabel;/// What the entry cost, in dinars. A `String`, like every other money field in this app.
 String get amount;/// How much was spoiled, in the line's own unit. Null on an entry that is an amount and
/// nothing else — an overhead posted per order rather than per bag.
 String? get quantity;/// **Always null on a scrap loss**, and that is the fact rather than a gap: scrap is priced
/// from the batches it came out of, not from a standard rate, so there is no per-unit figure
/// to show and a screen that drew one would be inventing it.
 String? get rate; String? get notes;/// Who posted it — **absent, not null, on the response to recording one**, because that
/// endpoint does not load the relation. «الخادم لم يُرسلها هنا» is a different fact from
/// «لم يسجّلها أحد», and a required field here would throw on a perfectly good response.
@JsonKey(name: 'recorded_by') ProductionCostRecorder? get recordedBy;/// When the cost was incurred, which on a scrap loss is when it was recorded.
@JsonKey(name: 'incurred_at') DateTime? get incurredAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of ProductionCostEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductionCostEntryCopyWith<ProductionCostEntry> get copyWith => _$ProductionCostEntryCopyWithImpl<ProductionCostEntry>(this as ProductionCostEntry, _$identity);

  /// Serializes this ProductionCostEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductionCostEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderItemId, orderItemId) || other.orderItemId == orderItemId)&&(identical(other.costType, costType) || other.costType == costType)&&(identical(other.costTypeLabel, costTypeLabel) || other.costTypeLabel == costTypeLabel)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.incurredAt, incurredAt) || other.incurredAt == incurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,orderItemId,costType,costTypeLabel,amount,quantity,rate,notes,recordedBy,incurredAt,createdAt);

@override
String toString() {
  return 'ProductionCostEntry(id: $id, orderId: $orderId, orderItemId: $orderItemId, costType: $costType, costTypeLabel: $costTypeLabel, amount: $amount, quantity: $quantity, rate: $rate, notes: $notes, recordedBy: $recordedBy, incurredAt: $incurredAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ProductionCostEntryCopyWith<$Res>  {
  factory $ProductionCostEntryCopyWith(ProductionCostEntry value, $Res Function(ProductionCostEntry) _then) = _$ProductionCostEntryCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'order_id') int orderId,@JsonKey(name: 'order_item_id') int orderItemId,@JsonKey(name: 'cost_type') String costType,@JsonKey(name: 'cost_type_label') String costTypeLabel, String amount, String? quantity, String? rate, String? notes,@JsonKey(name: 'recorded_by') ProductionCostRecorder? recordedBy,@JsonKey(name: 'incurred_at') DateTime? incurredAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


$ProductionCostRecorderCopyWith<$Res>? get recordedBy;

}
/// @nodoc
class _$ProductionCostEntryCopyWithImpl<$Res>
    implements $ProductionCostEntryCopyWith<$Res> {
  _$ProductionCostEntryCopyWithImpl(this._self, this._then);

  final ProductionCostEntry _self;
  final $Res Function(ProductionCostEntry) _then;

/// Create a copy of ProductionCostEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? orderItemId = null,Object? costType = null,Object? costTypeLabel = null,Object? amount = null,Object? quantity = freezed,Object? rate = freezed,Object? notes = freezed,Object? recordedBy = freezed,Object? incurredAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,orderItemId: null == orderItemId ? _self.orderItemId : orderItemId // ignore: cast_nullable_to_non_nullable
as int,costType: null == costType ? _self.costType : costType // ignore: cast_nullable_to_non_nullable
as String,costTypeLabel: null == costTypeLabel ? _self.costTypeLabel : costTypeLabel // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as ProductionCostRecorder?,incurredAt: freezed == incurredAt ? _self.incurredAt : incurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of ProductionCostEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductionCostRecorderCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $ProductionCostRecorderCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductionCostEntry].
extension ProductionCostEntryPatterns on ProductionCostEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductionCostEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductionCostEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductionCostEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProductionCostEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductionCostEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProductionCostEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'order_id')  int orderId, @JsonKey(name: 'order_item_id')  int orderItemId, @JsonKey(name: 'cost_type')  String costType, @JsonKey(name: 'cost_type_label')  String costTypeLabel,  String amount,  String? quantity,  String? rate,  String? notes, @JsonKey(name: 'recorded_by')  ProductionCostRecorder? recordedBy, @JsonKey(name: 'incurred_at')  DateTime? incurredAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductionCostEntry() when $default != null:
return $default(_that.id,_that.orderId,_that.orderItemId,_that.costType,_that.costTypeLabel,_that.amount,_that.quantity,_that.rate,_that.notes,_that.recordedBy,_that.incurredAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'order_id')  int orderId, @JsonKey(name: 'order_item_id')  int orderItemId, @JsonKey(name: 'cost_type')  String costType, @JsonKey(name: 'cost_type_label')  String costTypeLabel,  String amount,  String? quantity,  String? rate,  String? notes, @JsonKey(name: 'recorded_by')  ProductionCostRecorder? recordedBy, @JsonKey(name: 'incurred_at')  DateTime? incurredAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ProductionCostEntry():
return $default(_that.id,_that.orderId,_that.orderItemId,_that.costType,_that.costTypeLabel,_that.amount,_that.quantity,_that.rate,_that.notes,_that.recordedBy,_that.incurredAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'order_id')  int orderId, @JsonKey(name: 'order_item_id')  int orderItemId, @JsonKey(name: 'cost_type')  String costType, @JsonKey(name: 'cost_type_label')  String costTypeLabel,  String amount,  String? quantity,  String? rate,  String? notes, @JsonKey(name: 'recorded_by')  ProductionCostRecorder? recordedBy, @JsonKey(name: 'incurred_at')  DateTime? incurredAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ProductionCostEntry() when $default != null:
return $default(_that.id,_that.orderId,_that.orderItemId,_that.costType,_that.costTypeLabel,_that.amount,_that.quantity,_that.rate,_that.notes,_that.recordedBy,_that.incurredAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductionCostEntry extends ProductionCostEntry {
  const _ProductionCostEntry({required this.id, @JsonKey(name: 'order_id') required this.orderId, @JsonKey(name: 'order_item_id') required this.orderItemId, @JsonKey(name: 'cost_type') required this.costType, @JsonKey(name: 'cost_type_label') required this.costTypeLabel, required this.amount, this.quantity, this.rate, this.notes, @JsonKey(name: 'recorded_by') this.recordedBy, @JsonKey(name: 'incurred_at') this.incurredAt, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _ProductionCostEntry.fromJson(Map<String, dynamic> json) => _$ProductionCostEntryFromJson(json);

@override final  int id;
@override@JsonKey(name: 'order_id') final  int orderId;
@override@JsonKey(name: 'order_item_id') final  int orderItemId;
/// `labor`, `machine_runtime`, `overhead` or `scrap_loss`.
///
/// A `String` rather than an enum, for the same reason an order step's `state` is one: it is
/// branched on nowhere and drawn nowhere — [costTypeLabel] is what a screen shows — and a
/// fifth kind added on the server should render as itself rather than fail to parse the
/// entry it belongs to.
@override@JsonKey(name: 'cost_type') final  String costType;
/// The server's own Arabic — «خسارة تلف». Rendered as-is, never mapped from [costType] here.
@override@JsonKey(name: 'cost_type_label') final  String costTypeLabel;
/// What the entry cost, in dinars. A `String`, like every other money field in this app.
@override final  String amount;
/// How much was spoiled, in the line's own unit. Null on an entry that is an amount and
/// nothing else — an overhead posted per order rather than per bag.
@override final  String? quantity;
/// **Always null on a scrap loss**, and that is the fact rather than a gap: scrap is priced
/// from the batches it came out of, not from a standard rate, so there is no per-unit figure
/// to show and a screen that drew one would be inventing it.
@override final  String? rate;
@override final  String? notes;
/// Who posted it — **absent, not null, on the response to recording one**, because that
/// endpoint does not load the relation. «الخادم لم يُرسلها هنا» is a different fact from
/// «لم يسجّلها أحد», and a required field here would throw on a perfectly good response.
@override@JsonKey(name: 'recorded_by') final  ProductionCostRecorder? recordedBy;
/// When the cost was incurred, which on a scrap loss is when it was recorded.
@override@JsonKey(name: 'incurred_at') final  DateTime? incurredAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of ProductionCostEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductionCostEntryCopyWith<_ProductionCostEntry> get copyWith => __$ProductionCostEntryCopyWithImpl<_ProductionCostEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductionCostEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductionCostEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderItemId, orderItemId) || other.orderItemId == orderItemId)&&(identical(other.costType, costType) || other.costType == costType)&&(identical(other.costTypeLabel, costTypeLabel) || other.costTypeLabel == costTypeLabel)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.incurredAt, incurredAt) || other.incurredAt == incurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,orderItemId,costType,costTypeLabel,amount,quantity,rate,notes,recordedBy,incurredAt,createdAt);

@override
String toString() {
  return 'ProductionCostEntry(id: $id, orderId: $orderId, orderItemId: $orderItemId, costType: $costType, costTypeLabel: $costTypeLabel, amount: $amount, quantity: $quantity, rate: $rate, notes: $notes, recordedBy: $recordedBy, incurredAt: $incurredAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ProductionCostEntryCopyWith<$Res> implements $ProductionCostEntryCopyWith<$Res> {
  factory _$ProductionCostEntryCopyWith(_ProductionCostEntry value, $Res Function(_ProductionCostEntry) _then) = __$ProductionCostEntryCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'order_id') int orderId,@JsonKey(name: 'order_item_id') int orderItemId,@JsonKey(name: 'cost_type') String costType,@JsonKey(name: 'cost_type_label') String costTypeLabel, String amount, String? quantity, String? rate, String? notes,@JsonKey(name: 'recorded_by') ProductionCostRecorder? recordedBy,@JsonKey(name: 'incurred_at') DateTime? incurredAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $ProductionCostRecorderCopyWith<$Res>? get recordedBy;

}
/// @nodoc
class __$ProductionCostEntryCopyWithImpl<$Res>
    implements _$ProductionCostEntryCopyWith<$Res> {
  __$ProductionCostEntryCopyWithImpl(this._self, this._then);

  final _ProductionCostEntry _self;
  final $Res Function(_ProductionCostEntry) _then;

/// Create a copy of ProductionCostEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? orderItemId = null,Object? costType = null,Object? costTypeLabel = null,Object? amount = null,Object? quantity = freezed,Object? rate = freezed,Object? notes = freezed,Object? recordedBy = freezed,Object? incurredAt = freezed,Object? createdAt = freezed,}) {
  return _then(_ProductionCostEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,orderItemId: null == orderItemId ? _self.orderItemId : orderItemId // ignore: cast_nullable_to_non_nullable
as int,costType: null == costType ? _self.costType : costType // ignore: cast_nullable_to_non_nullable
as String,costTypeLabel: null == costTypeLabel ? _self.costTypeLabel : costTypeLabel // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as ProductionCostRecorder?,incurredAt: freezed == incurredAt ? _self.incurredAt : incurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of ProductionCostEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductionCostRecorderCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $ProductionCostRecorderCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}
}


/// @nodoc
mixin _$ProductionCostRecorder {

 int get id; String get name;
/// Create a copy of ProductionCostRecorder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductionCostRecorderCopyWith<ProductionCostRecorder> get copyWith => _$ProductionCostRecorderCopyWithImpl<ProductionCostRecorder>(this as ProductionCostRecorder, _$identity);

  /// Serializes this ProductionCostRecorder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductionCostRecorder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ProductionCostRecorder(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ProductionCostRecorderCopyWith<$Res>  {
  factory $ProductionCostRecorderCopyWith(ProductionCostRecorder value, $Res Function(ProductionCostRecorder) _then) = _$ProductionCostRecorderCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$ProductionCostRecorderCopyWithImpl<$Res>
    implements $ProductionCostRecorderCopyWith<$Res> {
  _$ProductionCostRecorderCopyWithImpl(this._self, this._then);

  final ProductionCostRecorder _self;
  final $Res Function(ProductionCostRecorder) _then;

/// Create a copy of ProductionCostRecorder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductionCostRecorder].
extension ProductionCostRecorderPatterns on ProductionCostRecorder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductionCostRecorder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductionCostRecorder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductionCostRecorder value)  $default,){
final _that = this;
switch (_that) {
case _ProductionCostRecorder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductionCostRecorder value)?  $default,){
final _that = this;
switch (_that) {
case _ProductionCostRecorder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductionCostRecorder() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name)  $default,) {final _that = this;
switch (_that) {
case _ProductionCostRecorder():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _ProductionCostRecorder() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductionCostRecorder implements ProductionCostRecorder {
  const _ProductionCostRecorder({required this.id, required this.name});
  factory _ProductionCostRecorder.fromJson(Map<String, dynamic> json) => _$ProductionCostRecorderFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of ProductionCostRecorder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductionCostRecorderCopyWith<_ProductionCostRecorder> get copyWith => __$ProductionCostRecorderCopyWithImpl<_ProductionCostRecorder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductionCostRecorderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductionCostRecorder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ProductionCostRecorder(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ProductionCostRecorderCopyWith<$Res> implements $ProductionCostRecorderCopyWith<$Res> {
  factory _$ProductionCostRecorderCopyWith(_ProductionCostRecorder value, $Res Function(_ProductionCostRecorder) _then) = __$ProductionCostRecorderCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$ProductionCostRecorderCopyWithImpl<$Res>
    implements _$ProductionCostRecorderCopyWith<$Res> {
  __$ProductionCostRecorderCopyWithImpl(this._self, this._then);

  final _ProductionCostRecorder _self;
  final $Res Function(_ProductionCostRecorder) _then;

/// Create a copy of ProductionCostRecorder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_ProductionCostRecorder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
