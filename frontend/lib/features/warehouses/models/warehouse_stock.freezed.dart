// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'warehouse_stock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WarehouseStock {

 int get id;@JsonKey(name: 'warehouse_id') int get warehouseId;@JsonKey(name: 'stock_item_id') int get stockItemId; String get quantity;/// What this balance is counted in, snapshotted when the shelf was first stocked and never
/// re-derived — so a unit chosen for the item later cannot silently restate a number that
/// was counted the old way. Re-declaring the item's unit does not relabel this either: the
/// server empties every shelf through a recorded adjustment first, and the shelf comes back
/// at zero in the new unit.
 String get unit;/// The server's Arabic for [unit], kept as a label rather than a translation table here —
/// the same treatment `pricing_unit_label` gets everywhere else in this app.
@JsonKey(name: 'unit_label') String get unitLabel;/// The level at which this shelf starts asking to be refilled, or null for one nobody set.
@JsonKey(name: 'low_stock_threshold') String? get lowStockThreshold;/// The server's answer, not a comparison this app re-derives — `null` threshold means "no
/// alert", which is not the same as a threshold of zero.
@JsonKey(name: 'is_low_stock') bool get isLowStock;@JsonKey(name: 'stock_item') StockItemRef? get item;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of WarehouseStock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarehouseStockCopyWith<WarehouseStock> get copyWith => _$WarehouseStockCopyWithImpl<WarehouseStock>(this as WarehouseStock, _$identity);

  /// Serializes this WarehouseStock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarehouseStock&&(identical(other.id, id) || other.id == id)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.isLowStock, isLowStock) || other.isLowStock == isLowStock)&&(identical(other.item, item) || other.item == item)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,warehouseId,stockItemId,quantity,unit,unitLabel,lowStockThreshold,isLowStock,item,createdAt,updatedAt);

@override
String toString() {
  return 'WarehouseStock(id: $id, warehouseId: $warehouseId, stockItemId: $stockItemId, quantity: $quantity, unit: $unit, unitLabel: $unitLabel, lowStockThreshold: $lowStockThreshold, isLowStock: $isLowStock, item: $item, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WarehouseStockCopyWith<$Res>  {
  factory $WarehouseStockCopyWith(WarehouseStock value, $Res Function(WarehouseStock) _then) = _$WarehouseStockCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'warehouse_id') int warehouseId,@JsonKey(name: 'stock_item_id') int stockItemId, String quantity, String unit,@JsonKey(name: 'unit_label') String unitLabel,@JsonKey(name: 'low_stock_threshold') String? lowStockThreshold,@JsonKey(name: 'is_low_stock') bool isLowStock,@JsonKey(name: 'stock_item') StockItemRef? item,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


$StockItemRefCopyWith<$Res>? get item;

}
/// @nodoc
class _$WarehouseStockCopyWithImpl<$Res>
    implements $WarehouseStockCopyWith<$Res> {
  _$WarehouseStockCopyWithImpl(this._self, this._then);

  final WarehouseStock _self;
  final $Res Function(WarehouseStock) _then;

/// Create a copy of WarehouseStock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? warehouseId = null,Object? stockItemId = null,Object? quantity = null,Object? unit = null,Object? unitLabel = null,Object? lowStockThreshold = freezed,Object? isLowStock = null,Object? item = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,warehouseId: null == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,lowStockThreshold: freezed == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as String?,isLowStock: null == isLowStock ? _self.isLowStock : isLowStock // ignore: cast_nullable_to_non_nullable
as bool,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as StockItemRef?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of WarehouseStock
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


/// Adds pattern-matching-related methods to [WarehouseStock].
extension WarehouseStockPatterns on WarehouseStock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarehouseStock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarehouseStock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarehouseStock value)  $default,){
final _that = this;
switch (_that) {
case _WarehouseStock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarehouseStock value)?  $default,){
final _that = this;
switch (_that) {
case _WarehouseStock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'warehouse_id')  int warehouseId, @JsonKey(name: 'stock_item_id')  int stockItemId,  String quantity,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'low_stock_threshold')  String? lowStockThreshold, @JsonKey(name: 'is_low_stock')  bool isLowStock, @JsonKey(name: 'stock_item')  StockItemRef? item, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarehouseStock() when $default != null:
return $default(_that.id,_that.warehouseId,_that.stockItemId,_that.quantity,_that.unit,_that.unitLabel,_that.lowStockThreshold,_that.isLowStock,_that.item,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'warehouse_id')  int warehouseId, @JsonKey(name: 'stock_item_id')  int stockItemId,  String quantity,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'low_stock_threshold')  String? lowStockThreshold, @JsonKey(name: 'is_low_stock')  bool isLowStock, @JsonKey(name: 'stock_item')  StockItemRef? item, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WarehouseStock():
return $default(_that.id,_that.warehouseId,_that.stockItemId,_that.quantity,_that.unit,_that.unitLabel,_that.lowStockThreshold,_that.isLowStock,_that.item,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'warehouse_id')  int warehouseId, @JsonKey(name: 'stock_item_id')  int stockItemId,  String quantity,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'low_stock_threshold')  String? lowStockThreshold, @JsonKey(name: 'is_low_stock')  bool isLowStock, @JsonKey(name: 'stock_item')  StockItemRef? item, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WarehouseStock() when $default != null:
return $default(_that.id,_that.warehouseId,_that.stockItemId,_that.quantity,_that.unit,_that.unitLabel,_that.lowStockThreshold,_that.isLowStock,_that.item,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WarehouseStock extends WarehouseStock {
  const _WarehouseStock({required this.id, @JsonKey(name: 'warehouse_id') required this.warehouseId, @JsonKey(name: 'stock_item_id') required this.stockItemId, required this.quantity, required this.unit, @JsonKey(name: 'unit_label') required this.unitLabel, @JsonKey(name: 'low_stock_threshold') this.lowStockThreshold, @JsonKey(name: 'is_low_stock') this.isLowStock = false, @JsonKey(name: 'stock_item') this.item, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): super._();
  factory _WarehouseStock.fromJson(Map<String, dynamic> json) => _$WarehouseStockFromJson(json);

@override final  int id;
@override@JsonKey(name: 'warehouse_id') final  int warehouseId;
@override@JsonKey(name: 'stock_item_id') final  int stockItemId;
@override final  String quantity;
/// What this balance is counted in, snapshotted when the shelf was first stocked and never
/// re-derived — so a unit chosen for the item later cannot silently restate a number that
/// was counted the old way. Re-declaring the item's unit does not relabel this either: the
/// server empties every shelf through a recorded adjustment first, and the shelf comes back
/// at zero in the new unit.
@override final  String unit;
/// The server's Arabic for [unit], kept as a label rather than a translation table here —
/// the same treatment `pricing_unit_label` gets everywhere else in this app.
@override@JsonKey(name: 'unit_label') final  String unitLabel;
/// The level at which this shelf starts asking to be refilled, or null for one nobody set.
@override@JsonKey(name: 'low_stock_threshold') final  String? lowStockThreshold;
/// The server's answer, not a comparison this app re-derives — `null` threshold means "no
/// alert", which is not the same as a threshold of zero.
@override@JsonKey(name: 'is_low_stock') final  bool isLowStock;
@override@JsonKey(name: 'stock_item') final  StockItemRef? item;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of WarehouseStock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarehouseStockCopyWith<_WarehouseStock> get copyWith => __$WarehouseStockCopyWithImpl<_WarehouseStock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WarehouseStockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarehouseStock&&(identical(other.id, id) || other.id == id)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.isLowStock, isLowStock) || other.isLowStock == isLowStock)&&(identical(other.item, item) || other.item == item)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,warehouseId,stockItemId,quantity,unit,unitLabel,lowStockThreshold,isLowStock,item,createdAt,updatedAt);

@override
String toString() {
  return 'WarehouseStock(id: $id, warehouseId: $warehouseId, stockItemId: $stockItemId, quantity: $quantity, unit: $unit, unitLabel: $unitLabel, lowStockThreshold: $lowStockThreshold, isLowStock: $isLowStock, item: $item, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WarehouseStockCopyWith<$Res> implements $WarehouseStockCopyWith<$Res> {
  factory _$WarehouseStockCopyWith(_WarehouseStock value, $Res Function(_WarehouseStock) _then) = __$WarehouseStockCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'warehouse_id') int warehouseId,@JsonKey(name: 'stock_item_id') int stockItemId, String quantity, String unit,@JsonKey(name: 'unit_label') String unitLabel,@JsonKey(name: 'low_stock_threshold') String? lowStockThreshold,@JsonKey(name: 'is_low_stock') bool isLowStock,@JsonKey(name: 'stock_item') StockItemRef? item,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


@override $StockItemRefCopyWith<$Res>? get item;

}
/// @nodoc
class __$WarehouseStockCopyWithImpl<$Res>
    implements _$WarehouseStockCopyWith<$Res> {
  __$WarehouseStockCopyWithImpl(this._self, this._then);

  final _WarehouseStock _self;
  final $Res Function(_WarehouseStock) _then;

/// Create a copy of WarehouseStock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? warehouseId = null,Object? stockItemId = null,Object? quantity = null,Object? unit = null,Object? unitLabel = null,Object? lowStockThreshold = freezed,Object? isLowStock = null,Object? item = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_WarehouseStock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,warehouseId: null == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,lowStockThreshold: freezed == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as String?,isLowStock: null == isLowStock ? _self.isLowStock : isLowStock // ignore: cast_nullable_to_non_nullable
as bool,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as StockItemRef?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of WarehouseStock
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
mixin _$StockItemRef {

 int get id;/// `S7` — server-allocated, never settable.
 String get code;/// The material's name, without the size. [displayName] is what gets drawn.
 String get name;/// Null for something counted without dimensions — a roll, an ink. The two travel together:
/// the server refuses a width with no height.
@JsonKey(name: 'width_cm') int? get widthCm;@JsonKey(name: 'height_cm') int? get heightCm;/// «كيس شحن 25*35», composed server-side. Rendered as sent, never rebuilt.
@JsonKey(name: 'display_name') String get displayName;
/// Create a copy of StockItemRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockItemRefCopyWith<StockItemRef> get copyWith => _$StockItemRefCopyWithImpl<StockItemRef>(this as StockItemRef, _$identity);

  /// Serializes this StockItemRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,widthCm,heightCm,displayName);

@override
String toString() {
  return 'StockItemRef(id: $id, code: $code, name: $name, widthCm: $widthCm, heightCm: $heightCm, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $StockItemRefCopyWith<$Res>  {
  factory $StockItemRefCopyWith(StockItemRef value, $Res Function(StockItemRef) _then) = _$StockItemRefCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'display_name') String displayName
});




}
/// @nodoc
class _$StockItemRefCopyWithImpl<$Res>
    implements $StockItemRefCopyWith<$Res> {
  _$StockItemRefCopyWithImpl(this._self, this._then);

  final StockItemRef _self;
  final $Res Function(StockItemRef) _then;

/// Create a copy of StockItemRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? displayName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StockItemRef].
extension StockItemRefPatterns on StockItemRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockItemRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockItemRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockItemRef value)  $default,){
final _that = this;
switch (_that) {
case _StockItemRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockItemRef value)?  $default,){
final _that = this;
switch (_that) {
case _StockItemRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'display_name')  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockItemRef() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.widthCm,_that.heightCm,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'display_name')  String displayName)  $default,) {final _that = this;
switch (_that) {
case _StockItemRef():
return $default(_that.id,_that.code,_that.name,_that.widthCm,_that.heightCm,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'display_name')  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _StockItemRef() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.widthCm,_that.heightCm,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockItemRef extends StockItemRef {
  const _StockItemRef({required this.id, required this.code, required this.name, @JsonKey(name: 'width_cm') this.widthCm, @JsonKey(name: 'height_cm') this.heightCm, @JsonKey(name: 'display_name') required this.displayName}): super._();
  factory _StockItemRef.fromJson(Map<String, dynamic> json) => _$StockItemRefFromJson(json);

@override final  int id;
/// `S7` — server-allocated, never settable.
@override final  String code;
/// The material's name, without the size. [displayName] is what gets drawn.
@override final  String name;
/// Null for something counted without dimensions — a roll, an ink. The two travel together:
/// the server refuses a width with no height.
@override@JsonKey(name: 'width_cm') final  int? widthCm;
@override@JsonKey(name: 'height_cm') final  int? heightCm;
/// «كيس شحن 25*35», composed server-side. Rendered as sent, never rebuilt.
@override@JsonKey(name: 'display_name') final  String displayName;

/// Create a copy of StockItemRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockItemRefCopyWith<_StockItemRef> get copyWith => __$StockItemRefCopyWithImpl<_StockItemRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockItemRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockItemRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,widthCm,heightCm,displayName);

@override
String toString() {
  return 'StockItemRef(id: $id, code: $code, name: $name, widthCm: $widthCm, heightCm: $heightCm, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$StockItemRefCopyWith<$Res> implements $StockItemRefCopyWith<$Res> {
  factory _$StockItemRefCopyWith(_StockItemRef value, $Res Function(_StockItemRef) _then) = __$StockItemRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'display_name') String displayName
});




}
/// @nodoc
class __$StockItemRefCopyWithImpl<$Res>
    implements _$StockItemRefCopyWith<$Res> {
  __$StockItemRefCopyWithImpl(this._self, this._then);

  final _StockItemRef _self;
  final $Res Function(_StockItemRef) _then;

/// Create a copy of StockItemRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? displayName = null,}) {
  return _then(_StockItemRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
