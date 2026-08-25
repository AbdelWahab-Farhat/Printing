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
@JsonKey(name: 'order_date') String get orderDate;@JsonKey(name: 'expected_date') String? get expectedDate; String? get notes;/// What the whole order costs, summed by the server from its lines.
///
/// Null on an order raised before cost tracking existed — which is «غير مسجّل», not «صفر»,
/// and the screens say so rather than drawing a free purchase.
///
/// **Already inclusive of [totalAdditionalCost].** Each line's `final_total_cost` carries its
/// allocated share, and this is the sum of those — so the two are never added together on
/// screen, only shown as a total and the part of it that was not goods.
@JsonKey(name: 'total_amount') String? get totalAmount;/// Delivery, unloading, customs — what the order cost beyond the goods themselves, summed
/// by the server from [additionalCosts].
@JsonKey(name: 'total_additional_cost') String? get totalAdditionalCost;/// The order-level costs one by one, as they were typed.
///
/// **Sent with the list as well as with a single order**, so the edit form always opens on
/// the full current set — which matters, because saving replaces the set wholesale and a
/// form that opened on half of it would delete the rest.
@JsonKey(name: 'additional_costs') List<PurchaseOrderAdditionalCost> get additionalCosts;/// Present when one order was fetched, and on the list. Absent from a status change.
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.vendorId, vendorId) || other.vendorId == vendorId)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.warehouse, warehouse) || other.warehouse == warehouse)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.orderDate, orderDate) || other.orderDate == orderDate)&&(identical(other.expectedDate, expectedDate) || other.expectedDate == expectedDate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.totalAdditionalCost, totalAdditionalCost) || other.totalAdditionalCost == totalAdditionalCost)&&const DeepCollectionEquality().equals(other.additionalCosts, additionalCosts)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vendorId,vendor,warehouseId,warehouse,status,statusLabel,orderDate,expectedDate,notes,totalAmount,totalAdditionalCost,const DeepCollectionEquality().hash(additionalCosts),const DeepCollectionEquality().hash(items),createdAt,updatedAt);

@override
String toString() {
  return 'PurchaseOrder(id: $id, vendorId: $vendorId, vendor: $vendor, warehouseId: $warehouseId, warehouse: $warehouse, status: $status, statusLabel: $statusLabel, orderDate: $orderDate, expectedDate: $expectedDate, notes: $notes, totalAmount: $totalAmount, totalAdditionalCost: $totalAdditionalCost, additionalCosts: $additionalCosts, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderCopyWith<$Res>  {
  factory $PurchaseOrderCopyWith(PurchaseOrder value, $Res Function(PurchaseOrder) _then) = _$PurchaseOrderCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'vendor_id') int vendorId, ArrivalRef? vendor,@JsonKey(name: 'warehouse_id') int? warehouseId, ArrivalRef? warehouse,@JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown) PurchaseOrderStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'order_date') String orderDate,@JsonKey(name: 'expected_date') String? expectedDate, String? notes,@JsonKey(name: 'total_amount') String? totalAmount,@JsonKey(name: 'total_additional_cost') String? totalAdditionalCost,@JsonKey(name: 'additional_costs') List<PurchaseOrderAdditionalCost> additionalCosts, List<PurchaseOrderItem> items,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vendorId = null,Object? vendor = freezed,Object? warehouseId = freezed,Object? warehouse = freezed,Object? status = null,Object? statusLabel = null,Object? orderDate = null,Object? expectedDate = freezed,Object? notes = freezed,Object? totalAmount = freezed,Object? totalAdditionalCost = freezed,Object? additionalCosts = null,Object? items = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
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
as String?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String?,totalAdditionalCost: freezed == totalAdditionalCost ? _self.totalAdditionalCost : totalAdditionalCost // ignore: cast_nullable_to_non_nullable
as String?,additionalCosts: null == additionalCosts ? _self.additionalCosts : additionalCosts // ignore: cast_nullable_to_non_nullable
as List<PurchaseOrderAdditionalCost>,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'vendor_id')  int vendorId,  ArrivalRef? vendor, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ArrivalRef? warehouse, @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown)  PurchaseOrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'order_date')  String orderDate, @JsonKey(name: 'expected_date')  String? expectedDate,  String? notes, @JsonKey(name: 'total_amount')  String? totalAmount, @JsonKey(name: 'total_additional_cost')  String? totalAdditionalCost, @JsonKey(name: 'additional_costs')  List<PurchaseOrderAdditionalCost> additionalCosts,  List<PurchaseOrderItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
return $default(_that.id,_that.vendorId,_that.vendor,_that.warehouseId,_that.warehouse,_that.status,_that.statusLabel,_that.orderDate,_that.expectedDate,_that.notes,_that.totalAmount,_that.totalAdditionalCost,_that.additionalCosts,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'vendor_id')  int vendorId,  ArrivalRef? vendor, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ArrivalRef? warehouse, @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown)  PurchaseOrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'order_date')  String orderDate, @JsonKey(name: 'expected_date')  String? expectedDate,  String? notes, @JsonKey(name: 'total_amount')  String? totalAmount, @JsonKey(name: 'total_additional_cost')  String? totalAdditionalCost, @JsonKey(name: 'additional_costs')  List<PurchaseOrderAdditionalCost> additionalCosts,  List<PurchaseOrderItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrder():
return $default(_that.id,_that.vendorId,_that.vendor,_that.warehouseId,_that.warehouse,_that.status,_that.statusLabel,_that.orderDate,_that.expectedDate,_that.notes,_that.totalAmount,_that.totalAdditionalCost,_that.additionalCosts,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'vendor_id')  int vendorId,  ArrivalRef? vendor, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ArrivalRef? warehouse, @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown)  PurchaseOrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'order_date')  String orderDate, @JsonKey(name: 'expected_date')  String? expectedDate,  String? notes, @JsonKey(name: 'total_amount')  String? totalAmount, @JsonKey(name: 'total_additional_cost')  String? totalAdditionalCost, @JsonKey(name: 'additional_costs')  List<PurchaseOrderAdditionalCost> additionalCosts,  List<PurchaseOrderItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
return $default(_that.id,_that.vendorId,_that.vendor,_that.warehouseId,_that.warehouse,_that.status,_that.statusLabel,_that.orderDate,_that.expectedDate,_that.notes,_that.totalAmount,_that.totalAdditionalCost,_that.additionalCosts,_that.items,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseOrder extends PurchaseOrder {
  const _PurchaseOrder({required this.id, @JsonKey(name: 'vendor_id') required this.vendorId, this.vendor, @JsonKey(name: 'warehouse_id') this.warehouseId, this.warehouse, @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown) required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'order_date') required this.orderDate, @JsonKey(name: 'expected_date') this.expectedDate, this.notes, @JsonKey(name: 'total_amount') this.totalAmount, @JsonKey(name: 'total_additional_cost') this.totalAdditionalCost, @JsonKey(name: 'additional_costs') final  List<PurchaseOrderAdditionalCost> additionalCosts = const <PurchaseOrderAdditionalCost>[], final  List<PurchaseOrderItem> items = const <PurchaseOrderItem>[], @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _additionalCosts = additionalCosts,_items = items,super._();
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
/// What the whole order costs, summed by the server from its lines.
///
/// Null on an order raised before cost tracking existed — which is «غير مسجّل», not «صفر»,
/// and the screens say so rather than drawing a free purchase.
///
/// **Already inclusive of [totalAdditionalCost].** Each line's `final_total_cost` carries its
/// allocated share, and this is the sum of those — so the two are never added together on
/// screen, only shown as a total and the part of it that was not goods.
@override@JsonKey(name: 'total_amount') final  String? totalAmount;
/// Delivery, unloading, customs — what the order cost beyond the goods themselves, summed
/// by the server from [additionalCosts].
@override@JsonKey(name: 'total_additional_cost') final  String? totalAdditionalCost;
/// The order-level costs one by one, as they were typed.
///
/// **Sent with the list as well as with a single order**, so the edit form always opens on
/// the full current set — which matters, because saving replaces the set wholesale and a
/// form that opened on half of it would delete the rest.
 final  List<PurchaseOrderAdditionalCost> _additionalCosts;
/// The order-level costs one by one, as they were typed.
///
/// **Sent with the list as well as with a single order**, so the edit form always opens on
/// the full current set — which matters, because saving replaces the set wholesale and a
/// form that opened on half of it would delete the rest.
@override@JsonKey(name: 'additional_costs') List<PurchaseOrderAdditionalCost> get additionalCosts {
  if (_additionalCosts is EqualUnmodifiableListView) return _additionalCosts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_additionalCosts);
}

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.vendorId, vendorId) || other.vendorId == vendorId)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.warehouse, warehouse) || other.warehouse == warehouse)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.orderDate, orderDate) || other.orderDate == orderDate)&&(identical(other.expectedDate, expectedDate) || other.expectedDate == expectedDate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.totalAdditionalCost, totalAdditionalCost) || other.totalAdditionalCost == totalAdditionalCost)&&const DeepCollectionEquality().equals(other._additionalCosts, _additionalCosts)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vendorId,vendor,warehouseId,warehouse,status,statusLabel,orderDate,expectedDate,notes,totalAmount,totalAdditionalCost,const DeepCollectionEquality().hash(_additionalCosts),const DeepCollectionEquality().hash(_items),createdAt,updatedAt);

@override
String toString() {
  return 'PurchaseOrder(id: $id, vendorId: $vendorId, vendor: $vendor, warehouseId: $warehouseId, warehouse: $warehouse, status: $status, statusLabel: $statusLabel, orderDate: $orderDate, expectedDate: $expectedDate, notes: $notes, totalAmount: $totalAmount, totalAdditionalCost: $totalAdditionalCost, additionalCosts: $additionalCosts, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PurchaseOrderCopyWith<$Res> implements $PurchaseOrderCopyWith<$Res> {
  factory _$PurchaseOrderCopyWith(_PurchaseOrder value, $Res Function(_PurchaseOrder) _then) = __$PurchaseOrderCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'vendor_id') int vendorId, ArrivalRef? vendor,@JsonKey(name: 'warehouse_id') int? warehouseId, ArrivalRef? warehouse,@JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown) PurchaseOrderStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'order_date') String orderDate,@JsonKey(name: 'expected_date') String? expectedDate, String? notes,@JsonKey(name: 'total_amount') String? totalAmount,@JsonKey(name: 'total_additional_cost') String? totalAdditionalCost,@JsonKey(name: 'additional_costs') List<PurchaseOrderAdditionalCost> additionalCosts, List<PurchaseOrderItem> items,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vendorId = null,Object? vendor = freezed,Object? warehouseId = freezed,Object? warehouse = freezed,Object? status = null,Object? statusLabel = null,Object? orderDate = null,Object? expectedDate = freezed,Object? notes = freezed,Object? totalAmount = freezed,Object? totalAdditionalCost = freezed,Object? additionalCosts = null,Object? items = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
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
as String?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String?,totalAdditionalCost: freezed == totalAdditionalCost ? _self.totalAdditionalCost : totalAdditionalCost // ignore: cast_nullable_to_non_nullable
as String?,additionalCosts: null == additionalCosts ? _self._additionalCosts : additionalCosts // ignore: cast_nullable_to_non_nullable
as List<PurchaseOrderAdditionalCost>,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
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
mixin _$PurchaseOrderAdditionalCost {

 int get id; String get name;/// A string like every other money field here: `'10.00'` as the server stored it.
 String get amount;
/// Create a copy of PurchaseOrderAdditionalCost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderAdditionalCostCopyWith<PurchaseOrderAdditionalCost> get copyWith => _$PurchaseOrderAdditionalCostCopyWithImpl<PurchaseOrderAdditionalCost>(this as PurchaseOrderAdditionalCost, _$identity);

  /// Serializes this PurchaseOrderAdditionalCost to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrderAdditionalCost&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,amount);

@override
String toString() {
  return 'PurchaseOrderAdditionalCost(id: $id, name: $name, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderAdditionalCostCopyWith<$Res>  {
  factory $PurchaseOrderAdditionalCostCopyWith(PurchaseOrderAdditionalCost value, $Res Function(PurchaseOrderAdditionalCost) _then) = _$PurchaseOrderAdditionalCostCopyWithImpl;
@useResult
$Res call({
 int id, String name, String amount
});




}
/// @nodoc
class _$PurchaseOrderAdditionalCostCopyWithImpl<$Res>
    implements $PurchaseOrderAdditionalCostCopyWith<$Res> {
  _$PurchaseOrderAdditionalCostCopyWithImpl(this._self, this._then);

  final PurchaseOrderAdditionalCost _self;
  final $Res Function(PurchaseOrderAdditionalCost) _then;

/// Create a copy of PurchaseOrderAdditionalCost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? amount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchaseOrderAdditionalCost].
extension PurchaseOrderAdditionalCostPatterns on PurchaseOrderAdditionalCost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseOrderAdditionalCost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseOrderAdditionalCost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseOrderAdditionalCost value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrderAdditionalCost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseOrderAdditionalCost value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrderAdditionalCost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseOrderAdditionalCost() when $default != null:
return $default(_that.id,_that.name,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String amount)  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrderAdditionalCost():
return $default(_that.id,_that.name,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String amount)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrderAdditionalCost() when $default != null:
return $default(_that.id,_that.name,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseOrderAdditionalCost extends PurchaseOrderAdditionalCost {
  const _PurchaseOrderAdditionalCost({required this.id, required this.name, required this.amount}): super._();
  factory _PurchaseOrderAdditionalCost.fromJson(Map<String, dynamic> json) => _$PurchaseOrderAdditionalCostFromJson(json);

@override final  int id;
@override final  String name;
/// A string like every other money field here: `'10.00'` as the server stored it.
@override final  String amount;

/// Create a copy of PurchaseOrderAdditionalCost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseOrderAdditionalCostCopyWith<_PurchaseOrderAdditionalCost> get copyWith => __$PurchaseOrderAdditionalCostCopyWithImpl<_PurchaseOrderAdditionalCost>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseOrderAdditionalCostToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseOrderAdditionalCost&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,amount);

@override
String toString() {
  return 'PurchaseOrderAdditionalCost(id: $id, name: $name, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$PurchaseOrderAdditionalCostCopyWith<$Res> implements $PurchaseOrderAdditionalCostCopyWith<$Res> {
  factory _$PurchaseOrderAdditionalCostCopyWith(_PurchaseOrderAdditionalCost value, $Res Function(_PurchaseOrderAdditionalCost) _then) = __$PurchaseOrderAdditionalCostCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String amount
});




}
/// @nodoc
class __$PurchaseOrderAdditionalCostCopyWithImpl<$Res>
    implements _$PurchaseOrderAdditionalCostCopyWith<$Res> {
  __$PurchaseOrderAdditionalCostCopyWithImpl(this._self, this._then);

  final _PurchaseOrderAdditionalCost _self;
  final $Res Function(_PurchaseOrderAdditionalCost) _then;

/// Create a copy of PurchaseOrderAdditionalCost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? amount = null,}) {
  return _then(_PurchaseOrderAdditionalCost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PurchaseOrderItem {

 int get id;@JsonKey(name: 'stock_item_id') int get stockItemId;/// The shelf itself, in the six fields the server flattens it into — **borrowed from the
/// warehouse model rather than copied**, because a purchase-order line, an arrival line and a
/// balance row all meet the identical shape, and three classes holding it would be three
/// things to keep in step. It carries no `product_name` and no `image_url`, deliberately:
/// two products draw on one pile.
///
/// Nullable because it is `whenLoaded`, though every purchase order the API publishes carries
/// it — `PurchaseOrderListQuery` and the show endpoint both eager-load `items.stockItem`. A
/// missing key draws a fallback rather than failing the page.
@JsonKey(name: 'stock_item') StockItemRef? get stockItem;/// Strings, like every quantity in this app: `'10.000'` as the server stored it. Parsing
/// one to show it is how a decimal quietly becomes `10.0`.
@JsonKey(name: 'quantity_ordered') String get quantityOrdered;@JsonKey(name: 'quantity_received') String get quantityReceived;/// Computed by the server, never here — a client that subtracted would be a second opinion
/// about arithmetic that decides whether a shipment is refused.
@JsonKey(name: 'quantity_remaining') String get quantityRemaining;/// What the vendor charged for this line, and that divided by the quantity.
///
/// **[baseTotalCost] is the one that was typed**; the server derives [baseUnitCost] from it,
/// never the other way around. Null only on a line written before cost tracking existed.
/// **Zero is a real answer** — a free replacement from the vendor costs nothing and is not
/// the same as nobody having said.
@JsonKey(name: 'base_total_cost') String? get baseTotalCost;@JsonKey(name: 'base_unit_cost') String? get baseUnitCost;/// This line's share of the order's delivery, unloading and customs, worked out by the
/// server in proportion to what the line is worth.
@JsonKey(name: 'allocated_additional_cost') String? get allocatedAdditionalCost;/// The landed cost — [baseTotalCost] plus [allocatedAdditionalCost].
///
/// **This is what the goods actually cost us**, and what every screen leads with. Null on a
/// line the allocator never ran over, where the base figures are all there is.
@JsonKey(name: 'final_unit_cost') String? get finalUnitCost;@JsonKey(name: 'final_total_cost') String? get finalTotalCost;/// What this line is counted in, snapshotted from the **stock item** when the line was
/// written — `CreatePurchaseOrder` force-fills it from `stockItem->unit` and never trusts a
/// unit sent by a client, so a request cannot post one the shelf disagrees with.
///
/// Null on a line older than the column, and everything built from it then says nothing
/// rather than guessing — see [PurchaseLineUnit].
 String? get unit;@JsonKey(name: 'unit_label') String? get unitLabel;
/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderItemCopyWith<PurchaseOrderItem> get copyWith => _$PurchaseOrderItemCopyWithImpl<PurchaseOrderItem>(this as PurchaseOrderItem, _$identity);

  /// Serializes this PurchaseOrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.stockItem, stockItem) || other.stockItem == stockItem)&&(identical(other.quantityOrdered, quantityOrdered) || other.quantityOrdered == quantityOrdered)&&(identical(other.quantityReceived, quantityReceived) || other.quantityReceived == quantityReceived)&&(identical(other.quantityRemaining, quantityRemaining) || other.quantityRemaining == quantityRemaining)&&(identical(other.baseTotalCost, baseTotalCost) || other.baseTotalCost == baseTotalCost)&&(identical(other.baseUnitCost, baseUnitCost) || other.baseUnitCost == baseUnitCost)&&(identical(other.allocatedAdditionalCost, allocatedAdditionalCost) || other.allocatedAdditionalCost == allocatedAdditionalCost)&&(identical(other.finalUnitCost, finalUnitCost) || other.finalUnitCost == finalUnitCost)&&(identical(other.finalTotalCost, finalTotalCost) || other.finalTotalCost == finalTotalCost)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stockItemId,stockItem,quantityOrdered,quantityReceived,quantityRemaining,baseTotalCost,baseUnitCost,allocatedAdditionalCost,finalUnitCost,finalTotalCost,unit,unitLabel);

@override
String toString() {
  return 'PurchaseOrderItem(id: $id, stockItemId: $stockItemId, stockItem: $stockItem, quantityOrdered: $quantityOrdered, quantityReceived: $quantityReceived, quantityRemaining: $quantityRemaining, baseTotalCost: $baseTotalCost, baseUnitCost: $baseUnitCost, allocatedAdditionalCost: $allocatedAdditionalCost, finalUnitCost: $finalUnitCost, finalTotalCost: $finalTotalCost, unit: $unit, unitLabel: $unitLabel)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderItemCopyWith<$Res>  {
  factory $PurchaseOrderItemCopyWith(PurchaseOrderItem value, $Res Function(PurchaseOrderItem) _then) = _$PurchaseOrderItemCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'stock_item_id') int stockItemId,@JsonKey(name: 'stock_item') StockItemRef? stockItem,@JsonKey(name: 'quantity_ordered') String quantityOrdered,@JsonKey(name: 'quantity_received') String quantityReceived,@JsonKey(name: 'quantity_remaining') String quantityRemaining,@JsonKey(name: 'base_total_cost') String? baseTotalCost,@JsonKey(name: 'base_unit_cost') String? baseUnitCost,@JsonKey(name: 'allocated_additional_cost') String? allocatedAdditionalCost,@JsonKey(name: 'final_unit_cost') String? finalUnitCost,@JsonKey(name: 'final_total_cost') String? finalTotalCost, String? unit,@JsonKey(name: 'unit_label') String? unitLabel
});


$StockItemRefCopyWith<$Res>? get stockItem;

}
/// @nodoc
class _$PurchaseOrderItemCopyWithImpl<$Res>
    implements $PurchaseOrderItemCopyWith<$Res> {
  _$PurchaseOrderItemCopyWithImpl(this._self, this._then);

  final PurchaseOrderItem _self;
  final $Res Function(PurchaseOrderItem) _then;

/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stockItemId = null,Object? stockItem = freezed,Object? quantityOrdered = null,Object? quantityReceived = null,Object? quantityRemaining = null,Object? baseTotalCost = freezed,Object? baseUnitCost = freezed,Object? allocatedAdditionalCost = freezed,Object? finalUnitCost = freezed,Object? finalTotalCost = freezed,Object? unit = freezed,Object? unitLabel = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,stockItem: freezed == stockItem ? _self.stockItem : stockItem // ignore: cast_nullable_to_non_nullable
as StockItemRef?,quantityOrdered: null == quantityOrdered ? _self.quantityOrdered : quantityOrdered // ignore: cast_nullable_to_non_nullable
as String,quantityReceived: null == quantityReceived ? _self.quantityReceived : quantityReceived // ignore: cast_nullable_to_non_nullable
as String,quantityRemaining: null == quantityRemaining ? _self.quantityRemaining : quantityRemaining // ignore: cast_nullable_to_non_nullable
as String,baseTotalCost: freezed == baseTotalCost ? _self.baseTotalCost : baseTotalCost // ignore: cast_nullable_to_non_nullable
as String?,baseUnitCost: freezed == baseUnitCost ? _self.baseUnitCost : baseUnitCost // ignore: cast_nullable_to_non_nullable
as String?,allocatedAdditionalCost: freezed == allocatedAdditionalCost ? _self.allocatedAdditionalCost : allocatedAdditionalCost // ignore: cast_nullable_to_non_nullable
as String?,finalUnitCost: freezed == finalUnitCost ? _self.finalUnitCost : finalUnitCost // ignore: cast_nullable_to_non_nullable
as String?,finalTotalCost: freezed == finalTotalCost ? _self.finalTotalCost : finalTotalCost // ignore: cast_nullable_to_non_nullable
as String?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemRefCopyWith<$Res>? get stockItem {
    if (_self.stockItem == null) {
    return null;
  }

  return $StockItemRefCopyWith<$Res>(_self.stockItem!, (value) {
    return _then(_self.copyWith(stockItem: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item')  StockItemRef? stockItem, @JsonKey(name: 'quantity_ordered')  String quantityOrdered, @JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining, @JsonKey(name: 'base_total_cost')  String? baseTotalCost, @JsonKey(name: 'base_unit_cost')  String? baseUnitCost, @JsonKey(name: 'allocated_additional_cost')  String? allocatedAdditionalCost, @JsonKey(name: 'final_unit_cost')  String? finalUnitCost, @JsonKey(name: 'final_total_cost')  String? finalTotalCost,  String? unit, @JsonKey(name: 'unit_label')  String? unitLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
return $default(_that.id,_that.stockItemId,_that.stockItem,_that.quantityOrdered,_that.quantityReceived,_that.quantityRemaining,_that.baseTotalCost,_that.baseUnitCost,_that.allocatedAdditionalCost,_that.finalUnitCost,_that.finalTotalCost,_that.unit,_that.unitLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item')  StockItemRef? stockItem, @JsonKey(name: 'quantity_ordered')  String quantityOrdered, @JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining, @JsonKey(name: 'base_total_cost')  String? baseTotalCost, @JsonKey(name: 'base_unit_cost')  String? baseUnitCost, @JsonKey(name: 'allocated_additional_cost')  String? allocatedAdditionalCost, @JsonKey(name: 'final_unit_cost')  String? finalUnitCost, @JsonKey(name: 'final_total_cost')  String? finalTotalCost,  String? unit, @JsonKey(name: 'unit_label')  String? unitLabel)  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrderItem():
return $default(_that.id,_that.stockItemId,_that.stockItem,_that.quantityOrdered,_that.quantityReceived,_that.quantityRemaining,_that.baseTotalCost,_that.baseUnitCost,_that.allocatedAdditionalCost,_that.finalUnitCost,_that.finalTotalCost,_that.unit,_that.unitLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item')  StockItemRef? stockItem, @JsonKey(name: 'quantity_ordered')  String quantityOrdered, @JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining, @JsonKey(name: 'base_total_cost')  String? baseTotalCost, @JsonKey(name: 'base_unit_cost')  String? baseUnitCost, @JsonKey(name: 'allocated_additional_cost')  String? allocatedAdditionalCost, @JsonKey(name: 'final_unit_cost')  String? finalUnitCost, @JsonKey(name: 'final_total_cost')  String? finalTotalCost,  String? unit, @JsonKey(name: 'unit_label')  String? unitLabel)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
return $default(_that.id,_that.stockItemId,_that.stockItem,_that.quantityOrdered,_that.quantityReceived,_that.quantityRemaining,_that.baseTotalCost,_that.baseUnitCost,_that.allocatedAdditionalCost,_that.finalUnitCost,_that.finalTotalCost,_that.unit,_that.unitLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseOrderItem extends PurchaseOrderItem {
  const _PurchaseOrderItem({required this.id, @JsonKey(name: 'stock_item_id') required this.stockItemId, @JsonKey(name: 'stock_item') this.stockItem, @JsonKey(name: 'quantity_ordered') required this.quantityOrdered, @JsonKey(name: 'quantity_received') required this.quantityReceived, @JsonKey(name: 'quantity_remaining') required this.quantityRemaining, @JsonKey(name: 'base_total_cost') this.baseTotalCost, @JsonKey(name: 'base_unit_cost') this.baseUnitCost, @JsonKey(name: 'allocated_additional_cost') this.allocatedAdditionalCost, @JsonKey(name: 'final_unit_cost') this.finalUnitCost, @JsonKey(name: 'final_total_cost') this.finalTotalCost, this.unit, @JsonKey(name: 'unit_label') this.unitLabel}): super._();
  factory _PurchaseOrderItem.fromJson(Map<String, dynamic> json) => _$PurchaseOrderItemFromJson(json);

@override final  int id;
@override@JsonKey(name: 'stock_item_id') final  int stockItemId;
/// The shelf itself, in the six fields the server flattens it into — **borrowed from the
/// warehouse model rather than copied**, because a purchase-order line, an arrival line and a
/// balance row all meet the identical shape, and three classes holding it would be three
/// things to keep in step. It carries no `product_name` and no `image_url`, deliberately:
/// two products draw on one pile.
///
/// Nullable because it is `whenLoaded`, though every purchase order the API publishes carries
/// it — `PurchaseOrderListQuery` and the show endpoint both eager-load `items.stockItem`. A
/// missing key draws a fallback rather than failing the page.
@override@JsonKey(name: 'stock_item') final  StockItemRef? stockItem;
/// Strings, like every quantity in this app: `'10.000'` as the server stored it. Parsing
/// one to show it is how a decimal quietly becomes `10.0`.
@override@JsonKey(name: 'quantity_ordered') final  String quantityOrdered;
@override@JsonKey(name: 'quantity_received') final  String quantityReceived;
/// Computed by the server, never here — a client that subtracted would be a second opinion
/// about arithmetic that decides whether a shipment is refused.
@override@JsonKey(name: 'quantity_remaining') final  String quantityRemaining;
/// What the vendor charged for this line, and that divided by the quantity.
///
/// **[baseTotalCost] is the one that was typed**; the server derives [baseUnitCost] from it,
/// never the other way around. Null only on a line written before cost tracking existed.
/// **Zero is a real answer** — a free replacement from the vendor costs nothing and is not
/// the same as nobody having said.
@override@JsonKey(name: 'base_total_cost') final  String? baseTotalCost;
@override@JsonKey(name: 'base_unit_cost') final  String? baseUnitCost;
/// This line's share of the order's delivery, unloading and customs, worked out by the
/// server in proportion to what the line is worth.
@override@JsonKey(name: 'allocated_additional_cost') final  String? allocatedAdditionalCost;
/// The landed cost — [baseTotalCost] plus [allocatedAdditionalCost].
///
/// **This is what the goods actually cost us**, and what every screen leads with. Null on a
/// line the allocator never ran over, where the base figures are all there is.
@override@JsonKey(name: 'final_unit_cost') final  String? finalUnitCost;
@override@JsonKey(name: 'final_total_cost') final  String? finalTotalCost;
/// What this line is counted in, snapshotted from the **stock item** when the line was
/// written — `CreatePurchaseOrder` force-fills it from `stockItem->unit` and never trusts a
/// unit sent by a client, so a request cannot post one the shelf disagrees with.
///
/// Null on a line older than the column, and everything built from it then says nothing
/// rather than guessing — see [PurchaseLineUnit].
@override final  String? unit;
@override@JsonKey(name: 'unit_label') final  String? unitLabel;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseOrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.stockItem, stockItem) || other.stockItem == stockItem)&&(identical(other.quantityOrdered, quantityOrdered) || other.quantityOrdered == quantityOrdered)&&(identical(other.quantityReceived, quantityReceived) || other.quantityReceived == quantityReceived)&&(identical(other.quantityRemaining, quantityRemaining) || other.quantityRemaining == quantityRemaining)&&(identical(other.baseTotalCost, baseTotalCost) || other.baseTotalCost == baseTotalCost)&&(identical(other.baseUnitCost, baseUnitCost) || other.baseUnitCost == baseUnitCost)&&(identical(other.allocatedAdditionalCost, allocatedAdditionalCost) || other.allocatedAdditionalCost == allocatedAdditionalCost)&&(identical(other.finalUnitCost, finalUnitCost) || other.finalUnitCost == finalUnitCost)&&(identical(other.finalTotalCost, finalTotalCost) || other.finalTotalCost == finalTotalCost)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stockItemId,stockItem,quantityOrdered,quantityReceived,quantityRemaining,baseTotalCost,baseUnitCost,allocatedAdditionalCost,finalUnitCost,finalTotalCost,unit,unitLabel);

@override
String toString() {
  return 'PurchaseOrderItem(id: $id, stockItemId: $stockItemId, stockItem: $stockItem, quantityOrdered: $quantityOrdered, quantityReceived: $quantityReceived, quantityRemaining: $quantityRemaining, baseTotalCost: $baseTotalCost, baseUnitCost: $baseUnitCost, allocatedAdditionalCost: $allocatedAdditionalCost, finalUnitCost: $finalUnitCost, finalTotalCost: $finalTotalCost, unit: $unit, unitLabel: $unitLabel)';
}


}

/// @nodoc
abstract mixin class _$PurchaseOrderItemCopyWith<$Res> implements $PurchaseOrderItemCopyWith<$Res> {
  factory _$PurchaseOrderItemCopyWith(_PurchaseOrderItem value, $Res Function(_PurchaseOrderItem) _then) = __$PurchaseOrderItemCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'stock_item_id') int stockItemId,@JsonKey(name: 'stock_item') StockItemRef? stockItem,@JsonKey(name: 'quantity_ordered') String quantityOrdered,@JsonKey(name: 'quantity_received') String quantityReceived,@JsonKey(name: 'quantity_remaining') String quantityRemaining,@JsonKey(name: 'base_total_cost') String? baseTotalCost,@JsonKey(name: 'base_unit_cost') String? baseUnitCost,@JsonKey(name: 'allocated_additional_cost') String? allocatedAdditionalCost,@JsonKey(name: 'final_unit_cost') String? finalUnitCost,@JsonKey(name: 'final_total_cost') String? finalTotalCost, String? unit,@JsonKey(name: 'unit_label') String? unitLabel
});


@override $StockItemRefCopyWith<$Res>? get stockItem;

}
/// @nodoc
class __$PurchaseOrderItemCopyWithImpl<$Res>
    implements _$PurchaseOrderItemCopyWith<$Res> {
  __$PurchaseOrderItemCopyWithImpl(this._self, this._then);

  final _PurchaseOrderItem _self;
  final $Res Function(_PurchaseOrderItem) _then;

/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stockItemId = null,Object? stockItem = freezed,Object? quantityOrdered = null,Object? quantityReceived = null,Object? quantityRemaining = null,Object? baseTotalCost = freezed,Object? baseUnitCost = freezed,Object? allocatedAdditionalCost = freezed,Object? finalUnitCost = freezed,Object? finalTotalCost = freezed,Object? unit = freezed,Object? unitLabel = freezed,}) {
  return _then(_PurchaseOrderItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,stockItem: freezed == stockItem ? _self.stockItem : stockItem // ignore: cast_nullable_to_non_nullable
as StockItemRef?,quantityOrdered: null == quantityOrdered ? _self.quantityOrdered : quantityOrdered // ignore: cast_nullable_to_non_nullable
as String,quantityReceived: null == quantityReceived ? _self.quantityReceived : quantityReceived // ignore: cast_nullable_to_non_nullable
as String,quantityRemaining: null == quantityRemaining ? _self.quantityRemaining : quantityRemaining // ignore: cast_nullable_to_non_nullable
as String,baseTotalCost: freezed == baseTotalCost ? _self.baseTotalCost : baseTotalCost // ignore: cast_nullable_to_non_nullable
as String?,baseUnitCost: freezed == baseUnitCost ? _self.baseUnitCost : baseUnitCost // ignore: cast_nullable_to_non_nullable
as String?,allocatedAdditionalCost: freezed == allocatedAdditionalCost ? _self.allocatedAdditionalCost : allocatedAdditionalCost // ignore: cast_nullable_to_non_nullable
as String?,finalUnitCost: freezed == finalUnitCost ? _self.finalUnitCost : finalUnitCost // ignore: cast_nullable_to_non_nullable
as String?,finalTotalCost: freezed == finalTotalCost ? _self.finalTotalCost : finalTotalCost // ignore: cast_nullable_to_non_nullable
as String?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemRefCopyWith<$Res>? get stockItem {
    if (_self.stockItem == null) {
    return null;
  }

  return $StockItemRefCopyWith<$Res>(_self.stockItem!, (value) {
    return _then(_self.copyWith(stockItem: value));
  });
}
}

// dart format on
