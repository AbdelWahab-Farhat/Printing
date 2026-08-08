// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PurchaseOrder {

 int get id;@JsonKey(name: 'vendor_id') int get vendorId;/// Present on every screen that lists or opens one; absent from the reply to a status
/// change, which is why the detail screen re-reads rather than trusting what came back.
 ArrivalRef? get vendor;/// Nullable: a warehouse can be deleted once it is empty, and an order that named it keeps
/// its key pointing at nothing. Receiving refuses in that case rather than guessing.
@JsonKey(name: 'warehouse_id') int? get warehouseId; ArrivalRef? get warehouse;@JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown) PurchaseOrderStatus get status;/// The Arabic the server chose. Rendered as-is wherever *this* order is on screen, so a
/// status added on the server still reads correctly here.
@JsonKey(name: 'status_label') String get statusLabel;/// Plain `YYYY-MM-DD`, not a timestamp — the day the order was placed, not an instant.
@JsonKey(name: 'order_date') String get orderDate;@JsonKey(name: 'expected_date') String? get expectedDate; String? get notes;/// Present when one order was fetched, and on the list. Absent from a status change.
 List<PurchaseOrderItem> get items;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderCopyWith<PurchaseOrder> get copyWith => _$PurchaseOrderCopyWithImpl<PurchaseOrder>(this as PurchaseOrder, _$identity);

  /// Serializes this PurchaseOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.vendorId, vendorId) || other.vendorId == vendorId)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.warehouse, warehouse) || other.warehouse == warehouse)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.orderDate, orderDate) || other.orderDate == orderDate)&&(identical(other.expectedDate, expectedDate) || other.expectedDate == expectedDate)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vendorId,vendor,warehouseId,warehouse,status,statusLabel,orderDate,expectedDate,notes,const DeepCollectionEquality().hash(items),createdAt,updatedAt);

@override
String toString() {
  return 'PurchaseOrder(id: $id, vendorId: $vendorId, vendor: $vendor, warehouseId: $warehouseId, warehouse: $warehouse, status: $status, statusLabel: $statusLabel, orderDate: $orderDate, expectedDate: $expectedDate, notes: $notes, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderCopyWith<$Res>  {
  factory $PurchaseOrderCopyWith(PurchaseOrder value, $Res Function(PurchaseOrder) _then) = _$PurchaseOrderCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'vendor_id') int vendorId, ArrivalRef? vendor,@JsonKey(name: 'warehouse_id') int? warehouseId, ArrivalRef? warehouse,@JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown) PurchaseOrderStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'order_date') String orderDate,@JsonKey(name: 'expected_date') String? expectedDate, String? notes, List<PurchaseOrderItem> items,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


$ArrivalRefCopyWith<$Res>? get vendor;$ArrivalRefCopyWith<$Res>? get warehouse;

}
/// @nodoc
class _$PurchaseOrderCopyWithImpl<$Res>
    implements $PurchaseOrderCopyWith<$Res> {
  _$PurchaseOrderCopyWithImpl(this._self, this._then);

  final PurchaseOrder _self;
  final $Res Function(PurchaseOrder) _then;

/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vendorId = null,Object? vendor = freezed,Object? warehouseId = freezed,Object? warehouse = freezed,Object? status = null,Object? statusLabel = null,Object? orderDate = null,Object? expectedDate = freezed,Object? notes = freezed,Object? items = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vendorId: null == vendorId ? _self.vendorId : vendorId // ignore: cast_nullable_to_non_nullable
as int,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int?,warehouse: freezed == warehouse ? _self.warehouse : warehouse // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PurchaseOrderStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,orderDate: null == orderDate ? _self.orderDate : orderDate // ignore: cast_nullable_to_non_nullable
as String,expectedDate: freezed == expectedDate ? _self.expectedDate : expectedDate // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PurchaseOrderItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of PurchaseOrder
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
}/// Create a copy of PurchaseOrder
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
}
}


/// Adds pattern-matching-related methods to [PurchaseOrder].
extension PurchaseOrderPatterns on PurchaseOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseOrder value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseOrder value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'vendor_id')  int vendorId,  ArrivalRef? vendor, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ArrivalRef? warehouse, @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown)  PurchaseOrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'order_date')  String orderDate, @JsonKey(name: 'expected_date')  String? expectedDate,  String? notes,  List<PurchaseOrderItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
return $default(_that.id,_that.vendorId,_that.vendor,_that.warehouseId,_that.warehouse,_that.status,_that.statusLabel,_that.orderDate,_that.expectedDate,_that.notes,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'vendor_id')  int vendorId,  ArrivalRef? vendor, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ArrivalRef? warehouse, @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown)  PurchaseOrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'order_date')  String orderDate, @JsonKey(name: 'expected_date')  String? expectedDate,  String? notes,  List<PurchaseOrderItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrder():
return $default(_that.id,_that.vendorId,_that.vendor,_that.warehouseId,_that.warehouse,_that.status,_that.statusLabel,_that.orderDate,_that.expectedDate,_that.notes,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'vendor_id')  int vendorId,  ArrivalRef? vendor, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ArrivalRef? warehouse, @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown)  PurchaseOrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'order_date')  String orderDate, @JsonKey(name: 'expected_date')  String? expectedDate,  String? notes,  List<PurchaseOrderItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
return $default(_that.id,_that.vendorId,_that.vendor,_that.warehouseId,_that.warehouse,_that.status,_that.statusLabel,_that.orderDate,_that.expectedDate,_that.notes,_that.items,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseOrder extends PurchaseOrder {
  const _PurchaseOrder({required this.id, @JsonKey(name: 'vendor_id') required this.vendorId, this.vendor, @JsonKey(name: 'warehouse_id') this.warehouseId, this.warehouse, @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown) required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'order_date') required this.orderDate, @JsonKey(name: 'expected_date') this.expectedDate, this.notes, final  List<PurchaseOrderItem> items = const <PurchaseOrderItem>[], @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _items = items,super._();
  factory _PurchaseOrder.fromJson(Map<String, dynamic> json) => _$PurchaseOrderFromJson(json);

@override final  int id;
@override@JsonKey(name: 'vendor_id') final  int vendorId;
/// Present on every screen that lists or opens one; absent from the reply to a status
/// change, which is why the detail screen re-reads rather than trusting what came back.
@override final  ArrivalRef? vendor;
/// Nullable: a warehouse can be deleted once it is empty, and an order that named it keeps
/// its key pointing at nothing. Receiving refuses in that case rather than guessing.
@override@JsonKey(name: 'warehouse_id') final  int? warehouseId;
@override final  ArrivalRef? warehouse;
@override@JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown) final  PurchaseOrderStatus status;
/// The Arabic the server chose. Rendered as-is wherever *this* order is on screen, so a
/// status added on the server still reads correctly here.
@override@JsonKey(name: 'status_label') final  String statusLabel;
/// Plain `YYYY-MM-DD`, not a timestamp — the day the order was placed, not an instant.
@override@JsonKey(name: 'order_date') final  String orderDate;
@override@JsonKey(name: 'expected_date') final  String? expectedDate;
@override final  String? notes;
/// Present when one order was fetched, and on the list. Absent from a status change.
 final  List<PurchaseOrderItem> _items;
/// Present when one order was fetched, and on the list. Absent from a status change.
@override@JsonKey() List<PurchaseOrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseOrderCopyWith<_PurchaseOrder> get copyWith => __$PurchaseOrderCopyWithImpl<_PurchaseOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.vendorId, vendorId) || other.vendorId == vendorId)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.warehouse, warehouse) || other.warehouse == warehouse)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.orderDate, orderDate) || other.orderDate == orderDate)&&(identical(other.expectedDate, expectedDate) || other.expectedDate == expectedDate)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vendorId,vendor,warehouseId,warehouse,status,statusLabel,orderDate,expectedDate,notes,const DeepCollectionEquality().hash(_items),createdAt,updatedAt);

@override
String toString() {
  return 'PurchaseOrder(id: $id, vendorId: $vendorId, vendor: $vendor, warehouseId: $warehouseId, warehouse: $warehouse, status: $status, statusLabel: $statusLabel, orderDate: $orderDate, expectedDate: $expectedDate, notes: $notes, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PurchaseOrderCopyWith<$Res> implements $PurchaseOrderCopyWith<$Res> {
  factory _$PurchaseOrderCopyWith(_PurchaseOrder value, $Res Function(_PurchaseOrder) _then) = __$PurchaseOrderCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'vendor_id') int vendorId, ArrivalRef? vendor,@JsonKey(name: 'warehouse_id') int? warehouseId, ArrivalRef? warehouse,@JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown) PurchaseOrderStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'order_date') String orderDate,@JsonKey(name: 'expected_date') String? expectedDate, String? notes, List<PurchaseOrderItem> items,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


@override $ArrivalRefCopyWith<$Res>? get vendor;@override $ArrivalRefCopyWith<$Res>? get warehouse;

}
/// @nodoc
class __$PurchaseOrderCopyWithImpl<$Res>
    implements _$PurchaseOrderCopyWith<$Res> {
  __$PurchaseOrderCopyWithImpl(this._self, this._then);

  final _PurchaseOrder _self;
  final $Res Function(_PurchaseOrder) _then;

/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vendorId = null,Object? vendor = freezed,Object? warehouseId = freezed,Object? warehouse = freezed,Object? status = null,Object? statusLabel = null,Object? orderDate = null,Object? expectedDate = freezed,Object? notes = freezed,Object? items = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PurchaseOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vendorId: null == vendorId ? _self.vendorId : vendorId // ignore: cast_nullable_to_non_nullable
as int,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int?,warehouse: freezed == warehouse ? _self.warehouse : warehouse // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PurchaseOrderStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,orderDate: null == orderDate ? _self.orderDate : orderDate // ignore: cast_nullable_to_non_nullable
as String,expectedDate: freezed == expectedDate ? _self.expectedDate : expectedDate // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PurchaseOrderItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of PurchaseOrder
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
}/// Create a copy of PurchaseOrder
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
}
}


/// @nodoc
mixin _$PurchaseOrderItem {

 int get id;@JsonKey(name: 'product_variant_id') int get productVariantId;@JsonKey(name: 'product_variant') StockVariant? get variant;/// Strings, like every quantity in this app: `'10.000'` as the server stored it. Parsing
/// one to show it is how a decimal quietly becomes `10.0`.
@JsonKey(name: 'quantity_ordered') String get quantityOrdered;@JsonKey(name: 'quantity_received') String get quantityReceived;/// Computed by the server, never here — a client that subtracted would be a second opinion
/// about arithmetic that decides whether a shipment is refused.
@JsonKey(name: 'quantity_remaining') String get quantityRemaining;
/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderItemCopyWith<PurchaseOrderItem> get copyWith => _$PurchaseOrderItemCopyWithImpl<PurchaseOrderItem>(this as PurchaseOrderItem, _$identity);

  /// Serializes this PurchaseOrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.quantityOrdered, quantityOrdered) || other.quantityOrdered == quantityOrdered)&&(identical(other.quantityReceived, quantityReceived) || other.quantityReceived == quantityReceived)&&(identical(other.quantityRemaining, quantityRemaining) || other.quantityRemaining == quantityRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productVariantId,variant,quantityOrdered,quantityReceived,quantityRemaining);

@override
String toString() {
  return 'PurchaseOrderItem(id: $id, productVariantId: $productVariantId, variant: $variant, quantityOrdered: $quantityOrdered, quantityReceived: $quantityReceived, quantityRemaining: $quantityRemaining)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderItemCopyWith<$Res>  {
  factory $PurchaseOrderItemCopyWith(PurchaseOrderItem value, $Res Function(PurchaseOrderItem) _then) = _$PurchaseOrderItemCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'product_variant') StockVariant? variant,@JsonKey(name: 'quantity_ordered') String quantityOrdered,@JsonKey(name: 'quantity_received') String quantityReceived,@JsonKey(name: 'quantity_remaining') String quantityRemaining
});


$StockVariantCopyWith<$Res>? get variant;

}
/// @nodoc
class _$PurchaseOrderItemCopyWithImpl<$Res>
    implements $PurchaseOrderItemCopyWith<$Res> {
  _$PurchaseOrderItemCopyWithImpl(this._self, this._then);

  final PurchaseOrderItem _self;
  final $Res Function(PurchaseOrderItem) _then;

/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productVariantId = null,Object? variant = freezed,Object? quantityOrdered = null,Object? quantityReceived = null,Object? quantityRemaining = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as StockVariant?,quantityOrdered: null == quantityOrdered ? _self.quantityOrdered : quantityOrdered // ignore: cast_nullable_to_non_nullable
as String,quantityReceived: null == quantityReceived ? _self.quantityReceived : quantityReceived // ignore: cast_nullable_to_non_nullable
as String,quantityRemaining: null == quantityRemaining ? _self.quantityRemaining : quantityRemaining // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of PurchaseOrderItem
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


/// Adds pattern-matching-related methods to [PurchaseOrderItem].
extension PurchaseOrderItemPatterns on PurchaseOrderItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseOrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseOrderItem value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrderItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseOrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'quantity_ordered')  String quantityOrdered, @JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
return $default(_that.id,_that.productVariantId,_that.variant,_that.quantityOrdered,_that.quantityReceived,_that.quantityRemaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'quantity_ordered')  String quantityOrdered, @JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining)  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrderItem():
return $default(_that.id,_that.productVariantId,_that.variant,_that.quantityOrdered,_that.quantityReceived,_that.quantityRemaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'quantity_ordered')  String quantityOrdered, @JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
return $default(_that.id,_that.productVariantId,_that.variant,_that.quantityOrdered,_that.quantityReceived,_that.quantityRemaining);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseOrderItem extends PurchaseOrderItem {
  const _PurchaseOrderItem({required this.id, @JsonKey(name: 'product_variant_id') required this.productVariantId, @JsonKey(name: 'product_variant') this.variant, @JsonKey(name: 'quantity_ordered') required this.quantityOrdered, @JsonKey(name: 'quantity_received') required this.quantityReceived, @JsonKey(name: 'quantity_remaining') required this.quantityRemaining}): super._();
  factory _PurchaseOrderItem.fromJson(Map<String, dynamic> json) => _$PurchaseOrderItemFromJson(json);

@override final  int id;
@override@JsonKey(name: 'product_variant_id') final  int productVariantId;
@override@JsonKey(name: 'product_variant') final  StockVariant? variant;
/// Strings, like every quantity in this app: `'10.000'` as the server stored it. Parsing
/// one to show it is how a decimal quietly becomes `10.0`.
@override@JsonKey(name: 'quantity_ordered') final  String quantityOrdered;
@override@JsonKey(name: 'quantity_received') final  String quantityReceived;
/// Computed by the server, never here — a client that subtracted would be a second opinion
/// about arithmetic that decides whether a shipment is refused.
@override@JsonKey(name: 'quantity_remaining') final  String quantityRemaining;

/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseOrderItemCopyWith<_PurchaseOrderItem> get copyWith => __$PurchaseOrderItemCopyWithImpl<_PurchaseOrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseOrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseOrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.quantityOrdered, quantityOrdered) || other.quantityOrdered == quantityOrdered)&&(identical(other.quantityReceived, quantityReceived) || other.quantityReceived == quantityReceived)&&(identical(other.quantityRemaining, quantityRemaining) || other.quantityRemaining == quantityRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productVariantId,variant,quantityOrdered,quantityReceived,quantityRemaining);

@override
String toString() {
  return 'PurchaseOrderItem(id: $id, productVariantId: $productVariantId, variant: $variant, quantityOrdered: $quantityOrdered, quantityReceived: $quantityReceived, quantityRemaining: $quantityRemaining)';
}


}

/// @nodoc
abstract mixin class _$PurchaseOrderItemCopyWith<$Res> implements $PurchaseOrderItemCopyWith<$Res> {
  factory _$PurchaseOrderItemCopyWith(_PurchaseOrderItem value, $Res Function(_PurchaseOrderItem) _then) = __$PurchaseOrderItemCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'product_variant') StockVariant? variant,@JsonKey(name: 'quantity_ordered') String quantityOrdered,@JsonKey(name: 'quantity_received') String quantityReceived,@JsonKey(name: 'quantity_remaining') String quantityRemaining
});


@override $StockVariantCopyWith<$Res>? get variant;

}
/// @nodoc
class __$PurchaseOrderItemCopyWithImpl<$Res>
    implements _$PurchaseOrderItemCopyWith<$Res> {
  __$PurchaseOrderItemCopyWithImpl(this._self, this._then);

  final _PurchaseOrderItem _self;
  final $Res Function(_PurchaseOrderItem) _then;

/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productVariantId = null,Object? variant = freezed,Object? quantityOrdered = null,Object? quantityReceived = null,Object? quantityRemaining = null,}) {
  return _then(_PurchaseOrderItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as StockVariant?,quantityOrdered: null == quantityOrdered ? _self.quantityOrdered : quantityOrdered // ignore: cast_nullable_to_non_nullable
as String,quantityReceived: null == quantityReceived ? _self.quantityReceived : quantityReceived // ignore: cast_nullable_to_non_nullable
as String,quantityRemaining: null == quantityRemaining ? _self.quantityRemaining : quantityRemaining // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of PurchaseOrderItem
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

// dart format on
