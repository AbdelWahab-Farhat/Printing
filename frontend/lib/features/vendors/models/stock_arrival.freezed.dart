// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_arrival.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockArrival {

 int get id;@JsonKey(name: 'vendor_id') int get vendorId; ArrivalRef? get vendor;/// Which purchase order this shipment was fulfilling, null when it was unplanned — which
/// most arrivals are.
///
/// A plain id and not a nested object, because that is what the server publishes: the order
/// is read through `GET /purchase-orders/{id}`, the same way every other `*_id` in this API
/// works.
@JsonKey(name: 'purchase_order_id') int? get purchaseOrderId;/// Nullable, and not an oversight: a warehouse can be deleted once it is empty, and the
/// purchase history that passed through it has to survive that. The document keeps its
/// lines and its ledger rows; only the pointer goes.
@JsonKey(name: 'warehouse_id') int? get warehouseId; ArrivalRef? get warehouse;@JsonKey(name: 'invoice_number') String? get invoiceNumber; String? get notes;/// Stamped by the server from the authenticated user — never sent by this app.
@JsonKey(name: 'received_by') int get receivedBy;@JsonKey(name: 'received_by_user') ArrivalRef? get receivedByUser; List<StockArrivalItem> get items;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockArrivalCopyWith<StockArrival> get copyWith => _$StockArrivalCopyWithImpl<StockArrival>(this as StockArrival, _$identity);

  /// Serializes this StockArrival to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockArrival&&(identical(other.id, id) || other.id == id)&&(identical(other.vendorId, vendorId) || other.vendorId == vendorId)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.warehouse, warehouse) || other.warehouse == warehouse)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.receivedBy, receivedBy) || other.receivedBy == receivedBy)&&(identical(other.receivedByUser, receivedByUser) || other.receivedByUser == receivedByUser)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vendorId,vendor,purchaseOrderId,warehouseId,warehouse,invoiceNumber,notes,receivedBy,receivedByUser,const DeepCollectionEquality().hash(items),createdAt);

@override
String toString() {
  return 'StockArrival(id: $id, vendorId: $vendorId, vendor: $vendor, purchaseOrderId: $purchaseOrderId, warehouseId: $warehouseId, warehouse: $warehouse, invoiceNumber: $invoiceNumber, notes: $notes, receivedBy: $receivedBy, receivedByUser: $receivedByUser, items: $items, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StockArrivalCopyWith<$Res>  {
  factory $StockArrivalCopyWith(StockArrival value, $Res Function(StockArrival) _then) = _$StockArrivalCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'vendor_id') int vendorId, ArrivalRef? vendor,@JsonKey(name: 'purchase_order_id') int? purchaseOrderId,@JsonKey(name: 'warehouse_id') int? warehouseId, ArrivalRef? warehouse,@JsonKey(name: 'invoice_number') String? invoiceNumber, String? notes,@JsonKey(name: 'received_by') int receivedBy,@JsonKey(name: 'received_by_user') ArrivalRef? receivedByUser, List<StockArrivalItem> items,@JsonKey(name: 'created_at') DateTime? createdAt
});


$ArrivalRefCopyWith<$Res>? get vendor;$ArrivalRefCopyWith<$Res>? get warehouse;$ArrivalRefCopyWith<$Res>? get receivedByUser;

}
/// @nodoc
class _$StockArrivalCopyWithImpl<$Res>
    implements $StockArrivalCopyWith<$Res> {
  _$StockArrivalCopyWithImpl(this._self, this._then);

  final StockArrival _self;
  final $Res Function(StockArrival) _then;

/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vendorId = null,Object? vendor = freezed,Object? purchaseOrderId = freezed,Object? warehouseId = freezed,Object? warehouse = freezed,Object? invoiceNumber = freezed,Object? notes = freezed,Object? receivedBy = null,Object? receivedByUser = freezed,Object? items = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vendorId: null == vendorId ? _self.vendorId : vendorId // ignore: cast_nullable_to_non_nullable
as int,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,purchaseOrderId: freezed == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as int?,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int?,warehouse: freezed == warehouse ? _self.warehouse : warehouse // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,invoiceNumber: freezed == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,receivedBy: null == receivedBy ? _self.receivedBy : receivedBy // ignore: cast_nullable_to_non_nullable
as int,receivedByUser: freezed == receivedByUser ? _self.receivedByUser : receivedByUser // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<StockArrivalItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArrivalRefCopyWith<$Res>? get vendor {
    if (_self.vendor == null) {
    return null;
  }

  return $ArrivalRefCopyWith<$Res>(_self.vendor!, (value) {
    return _then(_self.copyWith(vendor: value));
  });
}/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArrivalRefCopyWith<$Res>? get warehouse {
    if (_self.warehouse == null) {
    return null;
  }

  return $ArrivalRefCopyWith<$Res>(_self.warehouse!, (value) {
    return _then(_self.copyWith(warehouse: value));
  });
}/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArrivalRefCopyWith<$Res>? get receivedByUser {
    if (_self.receivedByUser == null) {
    return null;
  }

  return $ArrivalRefCopyWith<$Res>(_self.receivedByUser!, (value) {
    return _then(_self.copyWith(receivedByUser: value));
  });
}
}


/// Adds pattern-matching-related methods to [StockArrival].
extension StockArrivalPatterns on StockArrival {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockArrival value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockArrival() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockArrival value)  $default,){
final _that = this;
switch (_that) {
case _StockArrival():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockArrival value)?  $default,){
final _that = this;
switch (_that) {
case _StockArrival() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'vendor_id')  int vendorId,  ArrivalRef? vendor, @JsonKey(name: 'purchase_order_id')  int? purchaseOrderId, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ArrivalRef? warehouse, @JsonKey(name: 'invoice_number')  String? invoiceNumber,  String? notes, @JsonKey(name: 'received_by')  int receivedBy, @JsonKey(name: 'received_by_user')  ArrivalRef? receivedByUser,  List<StockArrivalItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockArrival() when $default != null:
return $default(_that.id,_that.vendorId,_that.vendor,_that.purchaseOrderId,_that.warehouseId,_that.warehouse,_that.invoiceNumber,_that.notes,_that.receivedBy,_that.receivedByUser,_that.items,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'vendor_id')  int vendorId,  ArrivalRef? vendor, @JsonKey(name: 'purchase_order_id')  int? purchaseOrderId, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ArrivalRef? warehouse, @JsonKey(name: 'invoice_number')  String? invoiceNumber,  String? notes, @JsonKey(name: 'received_by')  int receivedBy, @JsonKey(name: 'received_by_user')  ArrivalRef? receivedByUser,  List<StockArrivalItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _StockArrival():
return $default(_that.id,_that.vendorId,_that.vendor,_that.purchaseOrderId,_that.warehouseId,_that.warehouse,_that.invoiceNumber,_that.notes,_that.receivedBy,_that.receivedByUser,_that.items,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'vendor_id')  int vendorId,  ArrivalRef? vendor, @JsonKey(name: 'purchase_order_id')  int? purchaseOrderId, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ArrivalRef? warehouse, @JsonKey(name: 'invoice_number')  String? invoiceNumber,  String? notes, @JsonKey(name: 'received_by')  int receivedBy, @JsonKey(name: 'received_by_user')  ArrivalRef? receivedByUser,  List<StockArrivalItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _StockArrival() when $default != null:
return $default(_that.id,_that.vendorId,_that.vendor,_that.purchaseOrderId,_that.warehouseId,_that.warehouse,_that.invoiceNumber,_that.notes,_that.receivedBy,_that.receivedByUser,_that.items,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockArrival extends StockArrival {
  const _StockArrival({required this.id, @JsonKey(name: 'vendor_id') required this.vendorId, this.vendor, @JsonKey(name: 'purchase_order_id') this.purchaseOrderId, @JsonKey(name: 'warehouse_id') this.warehouseId, this.warehouse, @JsonKey(name: 'invoice_number') this.invoiceNumber, this.notes, @JsonKey(name: 'received_by') required this.receivedBy, @JsonKey(name: 'received_by_user') this.receivedByUser, final  List<StockArrivalItem> items = const <StockArrivalItem>[], @JsonKey(name: 'created_at') this.createdAt}): _items = items,super._();
  factory _StockArrival.fromJson(Map<String, dynamic> json) => _$StockArrivalFromJson(json);

@override final  int id;
@override@JsonKey(name: 'vendor_id') final  int vendorId;
@override final  ArrivalRef? vendor;
/// Which purchase order this shipment was fulfilling, null when it was unplanned — which
/// most arrivals are.
///
/// A plain id and not a nested object, because that is what the server publishes: the order
/// is read through `GET /purchase-orders/{id}`, the same way every other `*_id` in this API
/// works.
@override@JsonKey(name: 'purchase_order_id') final  int? purchaseOrderId;
/// Nullable, and not an oversight: a warehouse can be deleted once it is empty, and the
/// purchase history that passed through it has to survive that. The document keeps its
/// lines and its ledger rows; only the pointer goes.
@override@JsonKey(name: 'warehouse_id') final  int? warehouseId;
@override final  ArrivalRef? warehouse;
@override@JsonKey(name: 'invoice_number') final  String? invoiceNumber;
@override final  String? notes;
/// Stamped by the server from the authenticated user — never sent by this app.
@override@JsonKey(name: 'received_by') final  int receivedBy;
@override@JsonKey(name: 'received_by_user') final  ArrivalRef? receivedByUser;
 final  List<StockArrivalItem> _items;
@override@JsonKey() List<StockArrivalItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockArrivalCopyWith<_StockArrival> get copyWith => __$StockArrivalCopyWithImpl<_StockArrival>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockArrivalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockArrival&&(identical(other.id, id) || other.id == id)&&(identical(other.vendorId, vendorId) || other.vendorId == vendorId)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.warehouse, warehouse) || other.warehouse == warehouse)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.receivedBy, receivedBy) || other.receivedBy == receivedBy)&&(identical(other.receivedByUser, receivedByUser) || other.receivedByUser == receivedByUser)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vendorId,vendor,purchaseOrderId,warehouseId,warehouse,invoiceNumber,notes,receivedBy,receivedByUser,const DeepCollectionEquality().hash(_items),createdAt);

@override
String toString() {
  return 'StockArrival(id: $id, vendorId: $vendorId, vendor: $vendor, purchaseOrderId: $purchaseOrderId, warehouseId: $warehouseId, warehouse: $warehouse, invoiceNumber: $invoiceNumber, notes: $notes, receivedBy: $receivedBy, receivedByUser: $receivedByUser, items: $items, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StockArrivalCopyWith<$Res> implements $StockArrivalCopyWith<$Res> {
  factory _$StockArrivalCopyWith(_StockArrival value, $Res Function(_StockArrival) _then) = __$StockArrivalCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'vendor_id') int vendorId, ArrivalRef? vendor,@JsonKey(name: 'purchase_order_id') int? purchaseOrderId,@JsonKey(name: 'warehouse_id') int? warehouseId, ArrivalRef? warehouse,@JsonKey(name: 'invoice_number') String? invoiceNumber, String? notes,@JsonKey(name: 'received_by') int receivedBy,@JsonKey(name: 'received_by_user') ArrivalRef? receivedByUser, List<StockArrivalItem> items,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $ArrivalRefCopyWith<$Res>? get vendor;@override $ArrivalRefCopyWith<$Res>? get warehouse;@override $ArrivalRefCopyWith<$Res>? get receivedByUser;

}
/// @nodoc
class __$StockArrivalCopyWithImpl<$Res>
    implements _$StockArrivalCopyWith<$Res> {
  __$StockArrivalCopyWithImpl(this._self, this._then);

  final _StockArrival _self;
  final $Res Function(_StockArrival) _then;

/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vendorId = null,Object? vendor = freezed,Object? purchaseOrderId = freezed,Object? warehouseId = freezed,Object? warehouse = freezed,Object? invoiceNumber = freezed,Object? notes = freezed,Object? receivedBy = null,Object? receivedByUser = freezed,Object? items = null,Object? createdAt = freezed,}) {
  return _then(_StockArrival(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vendorId: null == vendorId ? _self.vendorId : vendorId // ignore: cast_nullable_to_non_nullable
as int,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,purchaseOrderId: freezed == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as int?,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int?,warehouse: freezed == warehouse ? _self.warehouse : warehouse // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,invoiceNumber: freezed == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,receivedBy: null == receivedBy ? _self.receivedBy : receivedBy // ignore: cast_nullable_to_non_nullable
as int,receivedByUser: freezed == receivedByUser ? _self.receivedByUser : receivedByUser // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<StockArrivalItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArrivalRefCopyWith<$Res>? get vendor {
    if (_self.vendor == null) {
    return null;
  }

  return $ArrivalRefCopyWith<$Res>(_self.vendor!, (value) {
    return _then(_self.copyWith(vendor: value));
  });
}/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArrivalRefCopyWith<$Res>? get warehouse {
    if (_self.warehouse == null) {
    return null;
  }

  return $ArrivalRefCopyWith<$Res>(_self.warehouse!, (value) {
    return _then(_self.copyWith(warehouse: value));
  });
}/// Create a copy of StockArrival
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArrivalRefCopyWith<$Res>? get receivedByUser {
    if (_self.receivedByUser == null) {
    return null;
  }

  return $ArrivalRefCopyWith<$Res>(_self.receivedByUser!, (value) {
    return _then(_self.copyWith(receivedByUser: value));
  });
}
}


/// @nodoc
mixin _$StockArrivalItem {

 int get id;/// A decimal the server sent — `'200.000'`. Kept as a `String` for the same reason
/// [WarehouseStock.quantity] is: parsing it into a `double` is the first step towards
/// arithmetic this app has no business doing.
 String get quantity;@JsonKey(name: 'product_variant_id') int get productVariantId;/// Reuses the shelf model's own summary — the server flattens a variant to the same five
/// fields wherever it appears, and a second class holding them would be a second thing to
/// keep in step.
@JsonKey(name: 'product_variant') StockVariant? get variant;/// What this line cost, carried down from the purchase order it fulfilled.
///
/// **Null for a plain arrival**, which is the ordinary case: goods that turned up without
/// paperwork have no agreed price to inherit, and inventing one here would put a number on
/// a shipment nobody priced.
@JsonKey(name: 'unit_cost') String? get unitCost;@JsonKey(name: 'total_cost') String? get totalCost;/// The ledger row this line produced. What makes «هذا السطر، أي حركة كتب؟» answerable
/// without re-deriving it from dates and quantities.
@JsonKey(name: 'stock_movement_id') int get stockMovementId;
/// Create a copy of StockArrivalItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockArrivalItemCopyWith<StockArrivalItem> get copyWith => _$StockArrivalItemCopyWithImpl<StockArrivalItem>(this as StockArrivalItem, _$identity);

  /// Serializes this StockArrivalItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockArrivalItem&&(identical(other.id, id) || other.id == id)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.unitCost, unitCost) || other.unitCost == unitCost)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.stockMovementId, stockMovementId) || other.stockMovementId == stockMovementId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,quantity,productVariantId,variant,unitCost,totalCost,stockMovementId);

@override
String toString() {
  return 'StockArrivalItem(id: $id, quantity: $quantity, productVariantId: $productVariantId, variant: $variant, unitCost: $unitCost, totalCost: $totalCost, stockMovementId: $stockMovementId)';
}


}

/// @nodoc
abstract mixin class $StockArrivalItemCopyWith<$Res>  {
  factory $StockArrivalItemCopyWith(StockArrivalItem value, $Res Function(StockArrivalItem) _then) = _$StockArrivalItemCopyWithImpl;
@useResult
$Res call({
 int id, String quantity,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'product_variant') StockVariant? variant,@JsonKey(name: 'unit_cost') String? unitCost,@JsonKey(name: 'total_cost') String? totalCost,@JsonKey(name: 'stock_movement_id') int stockMovementId
});


$StockVariantCopyWith<$Res>? get variant;

}
/// @nodoc
class _$StockArrivalItemCopyWithImpl<$Res>
    implements $StockArrivalItemCopyWith<$Res> {
  _$StockArrivalItemCopyWithImpl(this._self, this._then);

  final StockArrivalItem _self;
  final $Res Function(StockArrivalItem) _then;

/// Create a copy of StockArrivalItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? quantity = null,Object? productVariantId = null,Object? variant = freezed,Object? unitCost = freezed,Object? totalCost = freezed,Object? stockMovementId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as StockVariant?,unitCost: freezed == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as String?,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as String?,stockMovementId: null == stockMovementId ? _self.stockMovementId : stockMovementId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of StockArrivalItem
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


/// Adds pattern-matching-related methods to [StockArrivalItem].
extension StockArrivalItemPatterns on StockArrivalItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockArrivalItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockArrivalItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockArrivalItem value)  $default,){
final _that = this;
switch (_that) {
case _StockArrivalItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockArrivalItem value)?  $default,){
final _that = this;
switch (_that) {
case _StockArrivalItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String quantity, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'unit_cost')  String? unitCost, @JsonKey(name: 'total_cost')  String? totalCost, @JsonKey(name: 'stock_movement_id')  int stockMovementId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockArrivalItem() when $default != null:
return $default(_that.id,_that.quantity,_that.productVariantId,_that.variant,_that.unitCost,_that.totalCost,_that.stockMovementId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String quantity, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'unit_cost')  String? unitCost, @JsonKey(name: 'total_cost')  String? totalCost, @JsonKey(name: 'stock_movement_id')  int stockMovementId)  $default,) {final _that = this;
switch (_that) {
case _StockArrivalItem():
return $default(_that.id,_that.quantity,_that.productVariantId,_that.variant,_that.unitCost,_that.totalCost,_that.stockMovementId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String quantity, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'unit_cost')  String? unitCost, @JsonKey(name: 'total_cost')  String? totalCost, @JsonKey(name: 'stock_movement_id')  int stockMovementId)?  $default,) {final _that = this;
switch (_that) {
case _StockArrivalItem() when $default != null:
return $default(_that.id,_that.quantity,_that.productVariantId,_that.variant,_that.unitCost,_that.totalCost,_that.stockMovementId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockArrivalItem extends StockArrivalItem {
  const _StockArrivalItem({required this.id, required this.quantity, @JsonKey(name: 'product_variant_id') required this.productVariantId, @JsonKey(name: 'product_variant') this.variant, @JsonKey(name: 'unit_cost') this.unitCost, @JsonKey(name: 'total_cost') this.totalCost, @JsonKey(name: 'stock_movement_id') required this.stockMovementId}): super._();
  factory _StockArrivalItem.fromJson(Map<String, dynamic> json) => _$StockArrivalItemFromJson(json);

@override final  int id;
/// A decimal the server sent — `'200.000'`. Kept as a `String` for the same reason
/// [WarehouseStock.quantity] is: parsing it into a `double` is the first step towards
/// arithmetic this app has no business doing.
@override final  String quantity;
@override@JsonKey(name: 'product_variant_id') final  int productVariantId;
/// Reuses the shelf model's own summary — the server flattens a variant to the same five
/// fields wherever it appears, and a second class holding them would be a second thing to
/// keep in step.
@override@JsonKey(name: 'product_variant') final  StockVariant? variant;
/// What this line cost, carried down from the purchase order it fulfilled.
///
/// **Null for a plain arrival**, which is the ordinary case: goods that turned up without
/// paperwork have no agreed price to inherit, and inventing one here would put a number on
/// a shipment nobody priced.
@override@JsonKey(name: 'unit_cost') final  String? unitCost;
@override@JsonKey(name: 'total_cost') final  String? totalCost;
/// The ledger row this line produced. What makes «هذا السطر، أي حركة كتب؟» answerable
/// without re-deriving it from dates and quantities.
@override@JsonKey(name: 'stock_movement_id') final  int stockMovementId;

/// Create a copy of StockArrivalItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockArrivalItemCopyWith<_StockArrivalItem> get copyWith => __$StockArrivalItemCopyWithImpl<_StockArrivalItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockArrivalItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockArrivalItem&&(identical(other.id, id) || other.id == id)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.unitCost, unitCost) || other.unitCost == unitCost)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.stockMovementId, stockMovementId) || other.stockMovementId == stockMovementId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,quantity,productVariantId,variant,unitCost,totalCost,stockMovementId);

@override
String toString() {
  return 'StockArrivalItem(id: $id, quantity: $quantity, productVariantId: $productVariantId, variant: $variant, unitCost: $unitCost, totalCost: $totalCost, stockMovementId: $stockMovementId)';
}


}

/// @nodoc
abstract mixin class _$StockArrivalItemCopyWith<$Res> implements $StockArrivalItemCopyWith<$Res> {
  factory _$StockArrivalItemCopyWith(_StockArrivalItem value, $Res Function(_StockArrivalItem) _then) = __$StockArrivalItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String quantity,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'product_variant') StockVariant? variant,@JsonKey(name: 'unit_cost') String? unitCost,@JsonKey(name: 'total_cost') String? totalCost,@JsonKey(name: 'stock_movement_id') int stockMovementId
});


@override $StockVariantCopyWith<$Res>? get variant;

}
/// @nodoc
class __$StockArrivalItemCopyWithImpl<$Res>
    implements _$StockArrivalItemCopyWith<$Res> {
  __$StockArrivalItemCopyWithImpl(this._self, this._then);

  final _StockArrivalItem _self;
  final $Res Function(_StockArrivalItem) _then;

/// Create a copy of StockArrivalItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? quantity = null,Object? productVariantId = null,Object? variant = freezed,Object? unitCost = freezed,Object? totalCost = freezed,Object? stockMovementId = null,}) {
  return _then(_StockArrivalItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as StockVariant?,unitCost: freezed == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as String?,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as String?,stockMovementId: null == stockMovementId ? _self.stockMovementId : stockMovementId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of StockArrivalItem
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
mixin _$ArrivalRef {

 int get id; String get name;
/// Create a copy of ArrivalRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArrivalRefCopyWith<ArrivalRef> get copyWith => _$ArrivalRefCopyWithImpl<ArrivalRef>(this as ArrivalRef, _$identity);

  /// Serializes this ArrivalRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArrivalRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ArrivalRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ArrivalRefCopyWith<$Res>  {
  factory $ArrivalRefCopyWith(ArrivalRef value, $Res Function(ArrivalRef) _then) = _$ArrivalRefCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$ArrivalRefCopyWithImpl<$Res>
    implements $ArrivalRefCopyWith<$Res> {
  _$ArrivalRefCopyWithImpl(this._self, this._then);

  final ArrivalRef _self;
  final $Res Function(ArrivalRef) _then;

/// Create a copy of ArrivalRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ArrivalRef].
extension ArrivalRefPatterns on ArrivalRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArrivalRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArrivalRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArrivalRef value)  $default,){
final _that = this;
switch (_that) {
case _ArrivalRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArrivalRef value)?  $default,){
final _that = this;
switch (_that) {
case _ArrivalRef() when $default != null:
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
case _ArrivalRef() when $default != null:
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
case _ArrivalRef():
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
case _ArrivalRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArrivalRef implements ArrivalRef {
  const _ArrivalRef({required this.id, required this.name});
  factory _ArrivalRef.fromJson(Map<String, dynamic> json) => _$ArrivalRefFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of ArrivalRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArrivalRefCopyWith<_ArrivalRef> get copyWith => __$ArrivalRefCopyWithImpl<_ArrivalRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArrivalRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArrivalRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ArrivalRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ArrivalRefCopyWith<$Res> implements $ArrivalRefCopyWith<$Res> {
  factory _$ArrivalRefCopyWith(_ArrivalRef value, $Res Function(_ArrivalRef) _then) = __$ArrivalRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$ArrivalRefCopyWithImpl<$Res>
    implements _$ArrivalRefCopyWith<$Res> {
  __$ArrivalRefCopyWithImpl(this._self, this._then);

  final _ArrivalRef _self;
  final $Res Function(_ArrivalRef) _then;

/// Create a copy of ArrivalRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_ArrivalRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
