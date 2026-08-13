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

 int get id;@JsonKey(name: 'warehouse_id') int get warehouseId;@JsonKey(name: 'product_variant_id') int get productVariantId; String get quantity;/// What this balance is counted in, snapshotted when the shelf was first stocked and never
/// re-derived — so a product whose pricing unit changes later cannot silently restate a
/// balance that was counted the old way.
 String get unit;/// The server's Arabic for [unit], kept as a label rather than a translation table here —
/// the same treatment `pricing_unit_label` gets everywhere else in this app.
@JsonKey(name: 'unit_label') String get unitLabel;/// The level at which this shelf starts asking to be refilled, or null for one nobody set.
@JsonKey(name: 'low_stock_threshold') String? get lowStockThreshold;/// The server's answer, not a comparison this app re-derives — `null` threshold means "no
/// alert", which is not the same as a threshold of zero.
@JsonKey(name: 'is_low_stock') bool get isLowStock;@JsonKey(name: 'product_variant') StockVariant? get variant;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of WarehouseStock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarehouseStockCopyWith<WarehouseStock> get copyWith => _$WarehouseStockCopyWithImpl<WarehouseStock>(this as WarehouseStock, _$identity);

  /// Serializes this WarehouseStock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarehouseStock&&(identical(other.id, id) || other.id == id)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.isLowStock, isLowStock) || other.isLowStock == isLowStock)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,warehouseId,productVariantId,quantity,unit,unitLabel,lowStockThreshold,isLowStock,variant,createdAt,updatedAt);

@override
String toString() {
  return 'WarehouseStock(id: $id, warehouseId: $warehouseId, productVariantId: $productVariantId, quantity: $quantity, unit: $unit, unitLabel: $unitLabel, lowStockThreshold: $lowStockThreshold, isLowStock: $isLowStock, variant: $variant, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WarehouseStockCopyWith<$Res>  {
  factory $WarehouseStockCopyWith(WarehouseStock value, $Res Function(WarehouseStock) _then) = _$WarehouseStockCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'warehouse_id') int warehouseId,@JsonKey(name: 'product_variant_id') int productVariantId, String quantity, String unit,@JsonKey(name: 'unit_label') String unitLabel,@JsonKey(name: 'low_stock_threshold') String? lowStockThreshold,@JsonKey(name: 'is_low_stock') bool isLowStock,@JsonKey(name: 'product_variant') StockVariant? variant,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


$StockVariantCopyWith<$Res>? get variant;

}
/// @nodoc
class _$WarehouseStockCopyWithImpl<$Res>
    implements $WarehouseStockCopyWith<$Res> {
  _$WarehouseStockCopyWithImpl(this._self, this._then);

  final WarehouseStock _self;
  final $Res Function(WarehouseStock) _then;

/// Create a copy of WarehouseStock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? warehouseId = null,Object? productVariantId = null,Object? quantity = null,Object? unit = null,Object? unitLabel = null,Object? lowStockThreshold = freezed,Object? isLowStock = null,Object? variant = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,warehouseId: null == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,lowStockThreshold: freezed == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as String?,isLowStock: null == isLowStock ? _self.isLowStock : isLowStock // ignore: cast_nullable_to_non_nullable
as bool,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as StockVariant?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of WarehouseStock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockVariantCopyWith<$Res>? get variant {
    if (_self.variant == null) {
    return null;
  }

  return $StockVariantCopyWith<$Res>(_self.variant!, (value) {
    return _then(_self.copyWith(variant: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'warehouse_id')  int warehouseId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'low_stock_threshold')  String? lowStockThreshold, @JsonKey(name: 'is_low_stock')  bool isLowStock, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarehouseStock() when $default != null:
return $default(_that.id,_that.warehouseId,_that.productVariantId,_that.quantity,_that.unit,_that.unitLabel,_that.lowStockThreshold,_that.isLowStock,_that.variant,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'warehouse_id')  int warehouseId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'low_stock_threshold')  String? lowStockThreshold, @JsonKey(name: 'is_low_stock')  bool isLowStock, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WarehouseStock():
return $default(_that.id,_that.warehouseId,_that.productVariantId,_that.quantity,_that.unit,_that.unitLabel,_that.lowStockThreshold,_that.isLowStock,_that.variant,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'warehouse_id')  int warehouseId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'low_stock_threshold')  String? lowStockThreshold, @JsonKey(name: 'is_low_stock')  bool isLowStock, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WarehouseStock() when $default != null:
return $default(_that.id,_that.warehouseId,_that.productVariantId,_that.quantity,_that.unit,_that.unitLabel,_that.lowStockThreshold,_that.isLowStock,_that.variant,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WarehouseStock extends WarehouseStock {
  const _WarehouseStock({required this.id, @JsonKey(name: 'warehouse_id') required this.warehouseId, @JsonKey(name: 'product_variant_id') required this.productVariantId, required this.quantity, required this.unit, @JsonKey(name: 'unit_label') required this.unitLabel, @JsonKey(name: 'low_stock_threshold') this.lowStockThreshold, @JsonKey(name: 'is_low_stock') this.isLowStock = false, @JsonKey(name: 'product_variant') this.variant, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): super._();
  factory _WarehouseStock.fromJson(Map<String, dynamic> json) => _$WarehouseStockFromJson(json);

@override final  int id;
@override@JsonKey(name: 'warehouse_id') final  int warehouseId;
@override@JsonKey(name: 'product_variant_id') final  int productVariantId;
@override final  String quantity;
/// What this balance is counted in, snapshotted when the shelf was first stocked and never
/// re-derived — so a product whose pricing unit changes later cannot silently restate a
/// balance that was counted the old way.
@override final  String unit;
/// The server's Arabic for [unit], kept as a label rather than a translation table here —
/// the same treatment `pricing_unit_label` gets everywhere else in this app.
@override@JsonKey(name: 'unit_label') final  String unitLabel;
/// The level at which this shelf starts asking to be refilled, or null for one nobody set.
@override@JsonKey(name: 'low_stock_threshold') final  String? lowStockThreshold;
/// The server's answer, not a comparison this app re-derives — `null` threshold means "no
/// alert", which is not the same as a threshold of zero.
@override@JsonKey(name: 'is_low_stock') final  bool isLowStock;
@override@JsonKey(name: 'product_variant') final  StockVariant? variant;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarehouseStock&&(identical(other.id, id) || other.id == id)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.isLowStock, isLowStock) || other.isLowStock == isLowStock)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,warehouseId,productVariantId,quantity,unit,unitLabel,lowStockThreshold,isLowStock,variant,createdAt,updatedAt);

@override
String toString() {
  return 'WarehouseStock(id: $id, warehouseId: $warehouseId, productVariantId: $productVariantId, quantity: $quantity, unit: $unit, unitLabel: $unitLabel, lowStockThreshold: $lowStockThreshold, isLowStock: $isLowStock, variant: $variant, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WarehouseStockCopyWith<$Res> implements $WarehouseStockCopyWith<$Res> {
  factory _$WarehouseStockCopyWith(_WarehouseStock value, $Res Function(_WarehouseStock) _then) = __$WarehouseStockCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'warehouse_id') int warehouseId,@JsonKey(name: 'product_variant_id') int productVariantId, String quantity, String unit,@JsonKey(name: 'unit_label') String unitLabel,@JsonKey(name: 'low_stock_threshold') String? lowStockThreshold,@JsonKey(name: 'is_low_stock') bool isLowStock,@JsonKey(name: 'product_variant') StockVariant? variant,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


@override $StockVariantCopyWith<$Res>? get variant;

}
/// @nodoc
class __$WarehouseStockCopyWithImpl<$Res>
    implements _$WarehouseStockCopyWith<$Res> {
  __$WarehouseStockCopyWithImpl(this._self, this._then);

  final _WarehouseStock _self;
  final $Res Function(_WarehouseStock) _then;

/// Create a copy of WarehouseStock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? warehouseId = null,Object? productVariantId = null,Object? quantity = null,Object? unit = null,Object? unitLabel = null,Object? lowStockThreshold = freezed,Object? isLowStock = null,Object? variant = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_WarehouseStock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,warehouseId: null == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,lowStockThreshold: freezed == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as String?,isLowStock: null == isLowStock ? _self.isLowStock : isLowStock // ignore: cast_nullable_to_non_nullable
as bool,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as StockVariant?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of WarehouseStock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockVariantCopyWith<$Res>? get variant {
    if (_self.variant == null) {
    return null;
  }

  return $StockVariantCopyWith<$Res>(_self.variant!, (value) {
    return _then(_self.copyWith(variant: value));
  });
}
}


/// @nodoc
mixin _$StockVariant {

 int get id; String get label;@JsonKey(name: 'product_id') int get productId;/// `P7` — what staff say out loud, and the one thing on a shelf row safe to read down a
/// phone line. Nullable for a payload minted before the server started sending it.
@JsonKey(name: 'product_code') String? get productCode;@JsonKey(name: 'product_name') String get productName;/// The product's own photograph — there are none at size level, so every size of «أكياس
/// الشحن» shares one. Null for a product nobody has photographed, and for a payload minted
/// before the server started sending it.
@JsonKey(name: 'image_url') String? get imageUrl;
/// Create a copy of StockVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockVariantCopyWith<StockVariant> get copyWith => _$StockVariantCopyWithImpl<StockVariant>(this as StockVariant, _$identity);

  /// Serializes this StockVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productCode, productCode) || other.productCode == productCode)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,productId,productCode,productName,imageUrl);

@override
String toString() {
  return 'StockVariant(id: $id, label: $label, productId: $productId, productCode: $productCode, productName: $productName, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $StockVariantCopyWith<$Res>  {
  factory $StockVariantCopyWith(StockVariant value, $Res Function(StockVariant) _then) = _$StockVariantCopyWithImpl;
@useResult
$Res call({
 int id, String label,@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_code') String? productCode,@JsonKey(name: 'product_name') String productName,@JsonKey(name: 'image_url') String? imageUrl
});




}
/// @nodoc
class _$StockVariantCopyWithImpl<$Res>
    implements $StockVariantCopyWith<$Res> {
  _$StockVariantCopyWithImpl(this._self, this._then);

  final StockVariant _self;
  final $Res Function(StockVariant) _then;

/// Create a copy of StockVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? productId = null,Object? productCode = freezed,Object? productName = null,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productCode: freezed == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String?,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StockVariant].
extension StockVariantPatterns on StockVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockVariant value)  $default,){
final _that = this;
switch (_that) {
case _StockVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockVariant value)?  $default,){
final _that = this;
switch (_that) {
case _StockVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_code')  String? productCode, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'image_url')  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockVariant() when $default != null:
return $default(_that.id,_that.label,_that.productId,_that.productCode,_that.productName,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_code')  String? productCode, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'image_url')  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _StockVariant():
return $default(_that.id,_that.label,_that.productId,_that.productCode,_that.productName,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label, @JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_code')  String? productCode, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'image_url')  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _StockVariant() when $default != null:
return $default(_that.id,_that.label,_that.productId,_that.productCode,_that.productName,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockVariant implements StockVariant {
  const _StockVariant({required this.id, required this.label, @JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'product_code') this.productCode, @JsonKey(name: 'product_name') required this.productName, @JsonKey(name: 'image_url') this.imageUrl});
  factory _StockVariant.fromJson(Map<String, dynamic> json) => _$StockVariantFromJson(json);

@override final  int id;
@override final  String label;
@override@JsonKey(name: 'product_id') final  int productId;
/// `P7` — what staff say out loud, and the one thing on a shelf row safe to read down a
/// phone line. Nullable for a payload minted before the server started sending it.
@override@JsonKey(name: 'product_code') final  String? productCode;
@override@JsonKey(name: 'product_name') final  String productName;
/// The product's own photograph — there are none at size level, so every size of «أكياس
/// الشحن» shares one. Null for a product nobody has photographed, and for a payload minted
/// before the server started sending it.
@override@JsonKey(name: 'image_url') final  String? imageUrl;

/// Create a copy of StockVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockVariantCopyWith<_StockVariant> get copyWith => __$StockVariantCopyWithImpl<_StockVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productCode, productCode) || other.productCode == productCode)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,productId,productCode,productName,imageUrl);

@override
String toString() {
  return 'StockVariant(id: $id, label: $label, productId: $productId, productCode: $productCode, productName: $productName, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$StockVariantCopyWith<$Res> implements $StockVariantCopyWith<$Res> {
  factory _$StockVariantCopyWith(_StockVariant value, $Res Function(_StockVariant) _then) = __$StockVariantCopyWithImpl;
@override @useResult
$Res call({
 int id, String label,@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_code') String? productCode,@JsonKey(name: 'product_name') String productName,@JsonKey(name: 'image_url') String? imageUrl
});




}
/// @nodoc
class __$StockVariantCopyWithImpl<$Res>
    implements _$StockVariantCopyWith<$Res> {
  __$StockVariantCopyWithImpl(this._self, this._then);

  final _StockVariant _self;
  final $Res Function(_StockVariant) _then;

/// Create a copy of StockVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? productId = null,Object? productCode = freezed,Object? productName = null,Object? imageUrl = freezed,}) {
  return _then(_StockVariant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productCode: freezed == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String?,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
