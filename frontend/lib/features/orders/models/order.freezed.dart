// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Order {

 int get id;/// Plain digits — `'7'`. Said out loud on the phone, so it carries no letter prefix the
/// way a customer's `C7` or a product's `P7` does.
 String get code;@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus get status;/// The Arabic the server chose. Rendered as-is, so a status this build does not know still
/// reads correctly — see [OrderStatus.unknown].
@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'is_final') bool get isFinal;/// The moves this order may make, **already narrowed to what the signed-in user may do.**
/// The screen draws exactly these buttons and no others, which is what stops it offering an
/// action the server would refuse.
@JsonKey(name: 'available_transitions') List<OrderTransition> get availableTransitions;@JsonKey(name: 'customer_id') int get customerId;@JsonKey(name: 'city_name') String get cityName;@JsonKey(name: 'fulfilment_type_label') String get fulfilmentTypeLabel;@JsonKey(name: 'is_office_pickup') bool get isOfficePickup;@JsonKey(name: 'design_source_label') String get designSourceLabel;@JsonKey(name: 'items_total') String get itemsTotal;@JsonKey(name: 'design_fee') String get designFee;@JsonKey(name: 'delivery_price') String get deliveryPrice; String get discount;@JsonKey(name: 'grand_total') String get grandTotal; Customer? get customer;@JsonKey(name: 'region_name') String? get regionName;/// The branch, snapshotted like the city — a customer renaming one must not rewrite where
/// an old order said it was going.
@JsonKey(name: 'customer_shop_name') String? get customerShopName;@JsonKey(name: 'recipient_name') String? get recipientName;@JsonKey(name: 'recipient_phone') String? get recipientPhone;@JsonKey(name: 'address_details') String? get addressDetails; String? get notes;@JsonKey(name: 'shipping_company') String? get shippingCompany;@JsonKey(name: 'tracking_number') String? get trackingNumber;@JsonKey(name: 'courier_name') String? get courierName;@JsonKey(name: 'cancellation_reason') String? get cancellationReason;@JsonKey(name: 'items_are_editable') bool get itemsAreEditable;/// Present on the list endpoint.
@JsonKey(name: 'items_count') int? get itemsCount;/// Present when one order was fetched.
 List<OrderItem>? get items; List<OrderDesign>? get designs; List<OrderTransitionRecord>? get transitions;@JsonKey(name: 'placed_at') DateTime? get placedAt;@JsonKey(name: 'delivered_at') DateTime? get deliveredAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal)&&const DeepCollectionEquality().equals(other.availableTransitions, availableTransitions)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.fulfilmentTypeLabel, fulfilmentTypeLabel) || other.fulfilmentTypeLabel == fulfilmentTypeLabel)&&(identical(other.isOfficePickup, isOfficePickup) || other.isOfficePickup == isOfficePickup)&&(identical(other.designSourceLabel, designSourceLabel) || other.designSourceLabel == designSourceLabel)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.customerShopName, customerShopName) || other.customerShopName == customerShopName)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.shippingCompany, shippingCompany) || other.shippingCompany == shippingCompany)&&(identical(other.trackingNumber, trackingNumber) || other.trackingNumber == trackingNumber)&&(identical(other.courierName, courierName) || other.courierName == courierName)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.itemsAreEditable, itemsAreEditable) || other.itemsAreEditable == itemsAreEditable)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.designs, designs)&&const DeepCollectionEquality().equals(other.transitions, transitions)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,status,statusLabel,isFinal,const DeepCollectionEquality().hash(availableTransitions),customerId,cityName,fulfilmentTypeLabel,isOfficePickup,designSourceLabel,itemsTotal,designFee,deliveryPrice,discount,grandTotal,customer,regionName,customerShopName,recipientName,recipientPhone,addressDetails,notes,shippingCompany,trackingNumber,courierName,cancellationReason,itemsAreEditable,itemsCount,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(designs),const DeepCollectionEquality().hash(transitions),placedAt,deliveredAt,createdAt]);

@override
String toString() {
  return 'Order(id: $id, code: $code, status: $status, statusLabel: $statusLabel, isFinal: $isFinal, availableTransitions: $availableTransitions, customerId: $customerId, cityName: $cityName, fulfilmentTypeLabel: $fulfilmentTypeLabel, isOfficePickup: $isOfficePickup, designSourceLabel: $designSourceLabel, itemsTotal: $itemsTotal, designFee: $designFee, deliveryPrice: $deliveryPrice, discount: $discount, grandTotal: $grandTotal, customer: $customer, regionName: $regionName, customerShopName: $customerShopName, recipientName: $recipientName, recipientPhone: $recipientPhone, addressDetails: $addressDetails, notes: $notes, shippingCompany: $shippingCompany, trackingNumber: $trackingNumber, courierName: $courierName, cancellationReason: $cancellationReason, itemsAreEditable: $itemsAreEditable, itemsCount: $itemsCount, items: $items, designs: $designs, transitions: $transitions, placedAt: $placedAt, deliveredAt: $deliveredAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_final') bool isFinal,@JsonKey(name: 'available_transitions') List<OrderTransition> availableTransitions,@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'city_name') String cityName,@JsonKey(name: 'fulfilment_type_label') String fulfilmentTypeLabel,@JsonKey(name: 'is_office_pickup') bool isOfficePickup,@JsonKey(name: 'design_source_label') String designSourceLabel,@JsonKey(name: 'items_total') String itemsTotal,@JsonKey(name: 'design_fee') String designFee,@JsonKey(name: 'delivery_price') String deliveryPrice, String discount,@JsonKey(name: 'grand_total') String grandTotal, Customer? customer,@JsonKey(name: 'region_name') String? regionName,@JsonKey(name: 'customer_shop_name') String? customerShopName,@JsonKey(name: 'recipient_name') String? recipientName,@JsonKey(name: 'recipient_phone') String? recipientPhone,@JsonKey(name: 'address_details') String? addressDetails, String? notes,@JsonKey(name: 'shipping_company') String? shippingCompany,@JsonKey(name: 'tracking_number') String? trackingNumber,@JsonKey(name: 'courier_name') String? courierName,@JsonKey(name: 'cancellation_reason') String? cancellationReason,@JsonKey(name: 'items_are_editable') bool itemsAreEditable,@JsonKey(name: 'items_count') int? itemsCount, List<OrderItem>? items, List<OrderDesign>? designs, List<OrderTransitionRecord>? transitions,@JsonKey(name: 'placed_at') DateTime? placedAt,@JsonKey(name: 'delivered_at') DateTime? deliveredAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


$CustomerCopyWith<$Res>? get customer;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? isFinal = null,Object? availableTransitions = null,Object? customerId = null,Object? cityName = null,Object? fulfilmentTypeLabel = null,Object? isOfficePickup = null,Object? designSourceLabel = null,Object? itemsTotal = null,Object? designFee = null,Object? deliveryPrice = null,Object? discount = null,Object? grandTotal = null,Object? customer = freezed,Object? regionName = freezed,Object? customerShopName = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? notes = freezed,Object? shippingCompany = freezed,Object? trackingNumber = freezed,Object? courierName = freezed,Object? cancellationReason = freezed,Object? itemsAreEditable = null,Object? itemsCount = freezed,Object? items = freezed,Object? designs = freezed,Object? transitions = freezed,Object? placedAt = freezed,Object? deliveredAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,availableTransitions: null == availableTransitions ? _self.availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<OrderTransition>,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,cityName: null == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String,fulfilmentTypeLabel: null == fulfilmentTypeLabel ? _self.fulfilmentTypeLabel : fulfilmentTypeLabel // ignore: cast_nullable_to_non_nullable
as String,isOfficePickup: null == isOfficePickup ? _self.isOfficePickup : isOfficePickup // ignore: cast_nullable_to_non_nullable
as bool,designSourceLabel: null == designSourceLabel ? _self.designSourceLabel : designSourceLabel // ignore: cast_nullable_to_non_nullable
as String,itemsTotal: null == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as String,designFee: null == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String,deliveryPrice: null == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer?,regionName: freezed == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String?,customerShopName: freezed == customerShopName ? _self.customerShopName : customerShopName // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,shippingCompany: freezed == shippingCompany ? _self.shippingCompany : shippingCompany // ignore: cast_nullable_to_non_nullable
as String?,trackingNumber: freezed == trackingNumber ? _self.trackingNumber : trackingNumber // ignore: cast_nullable_to_non_nullable
as String?,courierName: freezed == courierName ? _self.courierName : courierName // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,itemsAreEditable: null == itemsAreEditable ? _self.itemsAreEditable : itemsAreEditable // ignore: cast_nullable_to_non_nullable
as bool,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,items: freezed == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>?,designs: freezed == designs ? _self.designs : designs // ignore: cast_nullable_to_non_nullable
as List<OrderDesign>?,transitions: freezed == transitions ? _self.transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<OrderTransitionRecord>?,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $CustomerCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_final')  bool isFinal, @JsonKey(name: 'available_transitions')  List<OrderTransition> availableTransitions, @JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_name')  String cityName, @JsonKey(name: 'fulfilment_type_label')  String fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup')  bool isOfficePickup, @JsonKey(name: 'design_source_label')  String designSourceLabel, @JsonKey(name: 'items_total')  String itemsTotal, @JsonKey(name: 'design_fee')  String designFee, @JsonKey(name: 'delivery_price')  String deliveryPrice,  String discount, @JsonKey(name: 'grand_total')  String grandTotal,  Customer? customer, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'customer_shop_name')  String? customerShopName, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'address_details')  String? addressDetails,  String? notes, @JsonKey(name: 'shipping_company')  String? shippingCompany, @JsonKey(name: 'tracking_number')  String? trackingNumber, @JsonKey(name: 'courier_name')  String? courierName, @JsonKey(name: 'cancellation_reason')  String? cancellationReason, @JsonKey(name: 'items_are_editable')  bool itemsAreEditable, @JsonKey(name: 'items_count')  int? itemsCount,  List<OrderItem>? items,  List<OrderDesign>? designs,  List<OrderTransitionRecord>? transitions, @JsonKey(name: 'placed_at')  DateTime? placedAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.isFinal,_that.availableTransitions,_that.customerId,_that.cityName,_that.fulfilmentTypeLabel,_that.isOfficePickup,_that.designSourceLabel,_that.itemsTotal,_that.designFee,_that.deliveryPrice,_that.discount,_that.grandTotal,_that.customer,_that.regionName,_that.customerShopName,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes,_that.shippingCompany,_that.trackingNumber,_that.courierName,_that.cancellationReason,_that.itemsAreEditable,_that.itemsCount,_that.items,_that.designs,_that.transitions,_that.placedAt,_that.deliveredAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_final')  bool isFinal, @JsonKey(name: 'available_transitions')  List<OrderTransition> availableTransitions, @JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_name')  String cityName, @JsonKey(name: 'fulfilment_type_label')  String fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup')  bool isOfficePickup, @JsonKey(name: 'design_source_label')  String designSourceLabel, @JsonKey(name: 'items_total')  String itemsTotal, @JsonKey(name: 'design_fee')  String designFee, @JsonKey(name: 'delivery_price')  String deliveryPrice,  String discount, @JsonKey(name: 'grand_total')  String grandTotal,  Customer? customer, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'customer_shop_name')  String? customerShopName, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'address_details')  String? addressDetails,  String? notes, @JsonKey(name: 'shipping_company')  String? shippingCompany, @JsonKey(name: 'tracking_number')  String? trackingNumber, @JsonKey(name: 'courier_name')  String? courierName, @JsonKey(name: 'cancellation_reason')  String? cancellationReason, @JsonKey(name: 'items_are_editable')  bool itemsAreEditable, @JsonKey(name: 'items_count')  int? itemsCount,  List<OrderItem>? items,  List<OrderDesign>? designs,  List<OrderTransitionRecord>? transitions, @JsonKey(name: 'placed_at')  DateTime? placedAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.isFinal,_that.availableTransitions,_that.customerId,_that.cityName,_that.fulfilmentTypeLabel,_that.isOfficePickup,_that.designSourceLabel,_that.itemsTotal,_that.designFee,_that.deliveryPrice,_that.discount,_that.grandTotal,_that.customer,_that.regionName,_that.customerShopName,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes,_that.shippingCompany,_that.trackingNumber,_that.courierName,_that.cancellationReason,_that.itemsAreEditable,_that.itemsCount,_that.items,_that.designs,_that.transitions,_that.placedAt,_that.deliveredAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_final')  bool isFinal, @JsonKey(name: 'available_transitions')  List<OrderTransition> availableTransitions, @JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_name')  String cityName, @JsonKey(name: 'fulfilment_type_label')  String fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup')  bool isOfficePickup, @JsonKey(name: 'design_source_label')  String designSourceLabel, @JsonKey(name: 'items_total')  String itemsTotal, @JsonKey(name: 'design_fee')  String designFee, @JsonKey(name: 'delivery_price')  String deliveryPrice,  String discount, @JsonKey(name: 'grand_total')  String grandTotal,  Customer? customer, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'customer_shop_name')  String? customerShopName, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'address_details')  String? addressDetails,  String? notes, @JsonKey(name: 'shipping_company')  String? shippingCompany, @JsonKey(name: 'tracking_number')  String? trackingNumber, @JsonKey(name: 'courier_name')  String? courierName, @JsonKey(name: 'cancellation_reason')  String? cancellationReason, @JsonKey(name: 'items_are_editable')  bool itemsAreEditable, @JsonKey(name: 'items_count')  int? itemsCount,  List<OrderItem>? items,  List<OrderDesign>? designs,  List<OrderTransitionRecord>? transitions, @JsonKey(name: 'placed_at')  DateTime? placedAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.isFinal,_that.availableTransitions,_that.customerId,_that.cityName,_that.fulfilmentTypeLabel,_that.isOfficePickup,_that.designSourceLabel,_that.itemsTotal,_that.designFee,_that.deliveryPrice,_that.discount,_that.grandTotal,_that.customer,_that.regionName,_that.customerShopName,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes,_that.shippingCompany,_that.trackingNumber,_that.courierName,_that.cancellationReason,_that.itemsAreEditable,_that.itemsCount,_that.items,_that.designs,_that.transitions,_that.placedAt,_that.deliveredAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Order extends Order {
  const _Order({required this.id, required this.code, @JsonKey(unknownEnumValue: OrderStatus.unknown) required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'is_final') required this.isFinal, @JsonKey(name: 'available_transitions') final  List<OrderTransition> availableTransitions = const <OrderTransition>[], @JsonKey(name: 'customer_id') required this.customerId, @JsonKey(name: 'city_name') required this.cityName, @JsonKey(name: 'fulfilment_type_label') required this.fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup') required this.isOfficePickup, @JsonKey(name: 'design_source_label') required this.designSourceLabel, @JsonKey(name: 'items_total') required this.itemsTotal, @JsonKey(name: 'design_fee') required this.designFee, @JsonKey(name: 'delivery_price') required this.deliveryPrice, required this.discount, @JsonKey(name: 'grand_total') required this.grandTotal, this.customer, @JsonKey(name: 'region_name') this.regionName, @JsonKey(name: 'customer_shop_name') this.customerShopName, @JsonKey(name: 'recipient_name') this.recipientName, @JsonKey(name: 'recipient_phone') this.recipientPhone, @JsonKey(name: 'address_details') this.addressDetails, this.notes, @JsonKey(name: 'shipping_company') this.shippingCompany, @JsonKey(name: 'tracking_number') this.trackingNumber, @JsonKey(name: 'courier_name') this.courierName, @JsonKey(name: 'cancellation_reason') this.cancellationReason, @JsonKey(name: 'items_are_editable') this.itemsAreEditable = false, @JsonKey(name: 'items_count') this.itemsCount, final  List<OrderItem>? items, final  List<OrderDesign>? designs, final  List<OrderTransitionRecord>? transitions, @JsonKey(name: 'placed_at') this.placedAt, @JsonKey(name: 'delivered_at') this.deliveredAt, @JsonKey(name: 'created_at') this.createdAt}): _availableTransitions = availableTransitions,_items = items,_designs = designs,_transitions = transitions,super._();
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

@override final  int id;
/// Plain digits — `'7'`. Said out loud on the phone, so it carries no letter prefix the
/// way a customer's `C7` or a product's `P7` does.
@override final  String code;
@override@JsonKey(unknownEnumValue: OrderStatus.unknown) final  OrderStatus status;
/// The Arabic the server chose. Rendered as-is, so a status this build does not know still
/// reads correctly — see [OrderStatus.unknown].
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'is_final') final  bool isFinal;
/// The moves this order may make, **already narrowed to what the signed-in user may do.**
/// The screen draws exactly these buttons and no others, which is what stops it offering an
/// action the server would refuse.
 final  List<OrderTransition> _availableTransitions;
/// The moves this order may make, **already narrowed to what the signed-in user may do.**
/// The screen draws exactly these buttons and no others, which is what stops it offering an
/// action the server would refuse.
@override@JsonKey(name: 'available_transitions') List<OrderTransition> get availableTransitions {
  if (_availableTransitions is EqualUnmodifiableListView) return _availableTransitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableTransitions);
}

@override@JsonKey(name: 'customer_id') final  int customerId;
@override@JsonKey(name: 'city_name') final  String cityName;
@override@JsonKey(name: 'fulfilment_type_label') final  String fulfilmentTypeLabel;
@override@JsonKey(name: 'is_office_pickup') final  bool isOfficePickup;
@override@JsonKey(name: 'design_source_label') final  String designSourceLabel;
@override@JsonKey(name: 'items_total') final  String itemsTotal;
@override@JsonKey(name: 'design_fee') final  String designFee;
@override@JsonKey(name: 'delivery_price') final  String deliveryPrice;
@override final  String discount;
@override@JsonKey(name: 'grand_total') final  String grandTotal;
@override final  Customer? customer;
@override@JsonKey(name: 'region_name') final  String? regionName;
/// The branch, snapshotted like the city — a customer renaming one must not rewrite where
/// an old order said it was going.
@override@JsonKey(name: 'customer_shop_name') final  String? customerShopName;
@override@JsonKey(name: 'recipient_name') final  String? recipientName;
@override@JsonKey(name: 'recipient_phone') final  String? recipientPhone;
@override@JsonKey(name: 'address_details') final  String? addressDetails;
@override final  String? notes;
@override@JsonKey(name: 'shipping_company') final  String? shippingCompany;
@override@JsonKey(name: 'tracking_number') final  String? trackingNumber;
@override@JsonKey(name: 'courier_name') final  String? courierName;
@override@JsonKey(name: 'cancellation_reason') final  String? cancellationReason;
@override@JsonKey(name: 'items_are_editable') final  bool itemsAreEditable;
/// Present on the list endpoint.
@override@JsonKey(name: 'items_count') final  int? itemsCount;
/// Present when one order was fetched.
 final  List<OrderItem>? _items;
/// Present when one order was fetched.
@override List<OrderItem>? get items {
  final value = _items;
  if (value == null) return null;
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<OrderDesign>? _designs;
@override List<OrderDesign>? get designs {
  final value = _designs;
  if (value == null) return null;
  if (_designs is EqualUnmodifiableListView) return _designs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<OrderTransitionRecord>? _transitions;
@override List<OrderTransitionRecord>? get transitions {
  final value = _transitions;
  if (value == null) return null;
  if (_transitions is EqualUnmodifiableListView) return _transitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'placed_at') final  DateTime? placedAt;
@override@JsonKey(name: 'delivered_at') final  DateTime? deliveredAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal)&&const DeepCollectionEquality().equals(other._availableTransitions, _availableTransitions)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.fulfilmentTypeLabel, fulfilmentTypeLabel) || other.fulfilmentTypeLabel == fulfilmentTypeLabel)&&(identical(other.isOfficePickup, isOfficePickup) || other.isOfficePickup == isOfficePickup)&&(identical(other.designSourceLabel, designSourceLabel) || other.designSourceLabel == designSourceLabel)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.customerShopName, customerShopName) || other.customerShopName == customerShopName)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.shippingCompany, shippingCompany) || other.shippingCompany == shippingCompany)&&(identical(other.trackingNumber, trackingNumber) || other.trackingNumber == trackingNumber)&&(identical(other.courierName, courierName) || other.courierName == courierName)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.itemsAreEditable, itemsAreEditable) || other.itemsAreEditable == itemsAreEditable)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._designs, _designs)&&const DeepCollectionEquality().equals(other._transitions, _transitions)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,status,statusLabel,isFinal,const DeepCollectionEquality().hash(_availableTransitions),customerId,cityName,fulfilmentTypeLabel,isOfficePickup,designSourceLabel,itemsTotal,designFee,deliveryPrice,discount,grandTotal,customer,regionName,customerShopName,recipientName,recipientPhone,addressDetails,notes,shippingCompany,trackingNumber,courierName,cancellationReason,itemsAreEditable,itemsCount,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_designs),const DeepCollectionEquality().hash(_transitions),placedAt,deliveredAt,createdAt]);

@override
String toString() {
  return 'Order(id: $id, code: $code, status: $status, statusLabel: $statusLabel, isFinal: $isFinal, availableTransitions: $availableTransitions, customerId: $customerId, cityName: $cityName, fulfilmentTypeLabel: $fulfilmentTypeLabel, isOfficePickup: $isOfficePickup, designSourceLabel: $designSourceLabel, itemsTotal: $itemsTotal, designFee: $designFee, deliveryPrice: $deliveryPrice, discount: $discount, grandTotal: $grandTotal, customer: $customer, regionName: $regionName, customerShopName: $customerShopName, recipientName: $recipientName, recipientPhone: $recipientPhone, addressDetails: $addressDetails, notes: $notes, shippingCompany: $shippingCompany, trackingNumber: $trackingNumber, courierName: $courierName, cancellationReason: $cancellationReason, itemsAreEditable: $itemsAreEditable, itemsCount: $itemsCount, items: $items, designs: $designs, transitions: $transitions, placedAt: $placedAt, deliveredAt: $deliveredAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_final') bool isFinal,@JsonKey(name: 'available_transitions') List<OrderTransition> availableTransitions,@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'city_name') String cityName,@JsonKey(name: 'fulfilment_type_label') String fulfilmentTypeLabel,@JsonKey(name: 'is_office_pickup') bool isOfficePickup,@JsonKey(name: 'design_source_label') String designSourceLabel,@JsonKey(name: 'items_total') String itemsTotal,@JsonKey(name: 'design_fee') String designFee,@JsonKey(name: 'delivery_price') String deliveryPrice, String discount,@JsonKey(name: 'grand_total') String grandTotal, Customer? customer,@JsonKey(name: 'region_name') String? regionName,@JsonKey(name: 'customer_shop_name') String? customerShopName,@JsonKey(name: 'recipient_name') String? recipientName,@JsonKey(name: 'recipient_phone') String? recipientPhone,@JsonKey(name: 'address_details') String? addressDetails, String? notes,@JsonKey(name: 'shipping_company') String? shippingCompany,@JsonKey(name: 'tracking_number') String? trackingNumber,@JsonKey(name: 'courier_name') String? courierName,@JsonKey(name: 'cancellation_reason') String? cancellationReason,@JsonKey(name: 'items_are_editable') bool itemsAreEditable,@JsonKey(name: 'items_count') int? itemsCount, List<OrderItem>? items, List<OrderDesign>? designs, List<OrderTransitionRecord>? transitions,@JsonKey(name: 'placed_at') DateTime? placedAt,@JsonKey(name: 'delivered_at') DateTime? deliveredAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $CustomerCopyWith<$Res>? get customer;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? isFinal = null,Object? availableTransitions = null,Object? customerId = null,Object? cityName = null,Object? fulfilmentTypeLabel = null,Object? isOfficePickup = null,Object? designSourceLabel = null,Object? itemsTotal = null,Object? designFee = null,Object? deliveryPrice = null,Object? discount = null,Object? grandTotal = null,Object? customer = freezed,Object? regionName = freezed,Object? customerShopName = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? notes = freezed,Object? shippingCompany = freezed,Object? trackingNumber = freezed,Object? courierName = freezed,Object? cancellationReason = freezed,Object? itemsAreEditable = null,Object? itemsCount = freezed,Object? items = freezed,Object? designs = freezed,Object? transitions = freezed,Object? placedAt = freezed,Object? deliveredAt = freezed,Object? createdAt = freezed,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,availableTransitions: null == availableTransitions ? _self._availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<OrderTransition>,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,cityName: null == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String,fulfilmentTypeLabel: null == fulfilmentTypeLabel ? _self.fulfilmentTypeLabel : fulfilmentTypeLabel // ignore: cast_nullable_to_non_nullable
as String,isOfficePickup: null == isOfficePickup ? _self.isOfficePickup : isOfficePickup // ignore: cast_nullable_to_non_nullable
as bool,designSourceLabel: null == designSourceLabel ? _self.designSourceLabel : designSourceLabel // ignore: cast_nullable_to_non_nullable
as String,itemsTotal: null == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as String,designFee: null == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String,deliveryPrice: null == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer?,regionName: freezed == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String?,customerShopName: freezed == customerShopName ? _self.customerShopName : customerShopName // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,shippingCompany: freezed == shippingCompany ? _self.shippingCompany : shippingCompany // ignore: cast_nullable_to_non_nullable
as String?,trackingNumber: freezed == trackingNumber ? _self.trackingNumber : trackingNumber // ignore: cast_nullable_to_non_nullable
as String?,courierName: freezed == courierName ? _self.courierName : courierName // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,itemsAreEditable: null == itemsAreEditable ? _self.itemsAreEditable : itemsAreEditable // ignore: cast_nullable_to_non_nullable
as bool,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,items: freezed == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>?,designs: freezed == designs ? _self._designs : designs // ignore: cast_nullable_to_non_nullable
as List<OrderDesign>?,transitions: freezed == transitions ? _self._transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<OrderTransitionRecord>?,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $CustomerCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}
}


/// @nodoc
mixin _$OrderTransition {

@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus get status; String get label;/// Cancelling is the only one today. The screen asks for the sentence *before* sending, so
/// the server's 422 for a missing reason is a case the user never reaches.
@JsonKey(name: 'requires_reason') bool get requiresReason;
/// Create a copy of OrderTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTransitionCopyWith<OrderTransition> get copyWith => _$OrderTransitionCopyWithImpl<OrderTransition>(this as OrderTransition, _$identity);

  /// Serializes this OrderTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTransition&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.requiresReason, requiresReason) || other.requiresReason == requiresReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,label,requiresReason);

@override
String toString() {
  return 'OrderTransition(status: $status, label: $label, requiresReason: $requiresReason)';
}


}

/// @nodoc
abstract mixin class $OrderTransitionCopyWith<$Res>  {
  factory $OrderTransitionCopyWith(OrderTransition value, $Res Function(OrderTransition) _then) = _$OrderTransitionCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus status, String label,@JsonKey(name: 'requires_reason') bool requiresReason
});




}
/// @nodoc
class _$OrderTransitionCopyWithImpl<$Res>
    implements $OrderTransitionCopyWith<$Res> {
  _$OrderTransitionCopyWithImpl(this._self, this._then);

  final OrderTransition _self;
  final $Res Function(OrderTransition) _then;

/// Create a copy of OrderTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? label = null,Object? requiresReason = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,requiresReason: null == requiresReason ? _self.requiresReason : requiresReason // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderTransition].
extension OrderTransitionPatterns on OrderTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderTransition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderTransition value)  $default,){
final _that = this;
switch (_that) {
case _OrderTransition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderTransition value)?  $default,){
final _that = this;
switch (_that) {
case _OrderTransition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status,  String label, @JsonKey(name: 'requires_reason')  bool requiresReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderTransition() when $default != null:
return $default(_that.status,_that.label,_that.requiresReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status,  String label, @JsonKey(name: 'requires_reason')  bool requiresReason)  $default,) {final _that = this;
switch (_that) {
case _OrderTransition():
return $default(_that.status,_that.label,_that.requiresReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status,  String label, @JsonKey(name: 'requires_reason')  bool requiresReason)?  $default,) {final _that = this;
switch (_that) {
case _OrderTransition() when $default != null:
return $default(_that.status,_that.label,_that.requiresReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderTransition extends OrderTransition {
  const _OrderTransition({@JsonKey(unknownEnumValue: OrderStatus.unknown) required this.status, required this.label, @JsonKey(name: 'requires_reason') this.requiresReason = false}): super._();
  factory _OrderTransition.fromJson(Map<String, dynamic> json) => _$OrderTransitionFromJson(json);

@override@JsonKey(unknownEnumValue: OrderStatus.unknown) final  OrderStatus status;
@override final  String label;
/// Cancelling is the only one today. The screen asks for the sentence *before* sending, so
/// the server's 422 for a missing reason is a case the user never reaches.
@override@JsonKey(name: 'requires_reason') final  bool requiresReason;

/// Create a copy of OrderTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderTransitionCopyWith<_OrderTransition> get copyWith => __$OrderTransitionCopyWithImpl<_OrderTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderTransition&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.requiresReason, requiresReason) || other.requiresReason == requiresReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,label,requiresReason);

@override
String toString() {
  return 'OrderTransition(status: $status, label: $label, requiresReason: $requiresReason)';
}


}

/// @nodoc
abstract mixin class _$OrderTransitionCopyWith<$Res> implements $OrderTransitionCopyWith<$Res> {
  factory _$OrderTransitionCopyWith(_OrderTransition value, $Res Function(_OrderTransition) _then) = __$OrderTransitionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus status, String label,@JsonKey(name: 'requires_reason') bool requiresReason
});




}
/// @nodoc
class __$OrderTransitionCopyWithImpl<$Res>
    implements _$OrderTransitionCopyWith<$Res> {
  __$OrderTransitionCopyWithImpl(this._self, this._then);

  final _OrderTransition _self;
  final $Res Function(_OrderTransition) _then;

/// Create a copy of OrderTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? label = null,Object? requiresReason = null,}) {
  return _then(_OrderTransition(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,requiresReason: null == requiresReason ? _self.requiresReason : requiresReason // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OrderItem {

 int get id;/// The snapshot, not the catalogue. A product renamed since must not rewrite this invoice.
@JsonKey(name: 'product_name') String get productName;@JsonKey(name: 'variant_label') String get variantLabel;@JsonKey(name: 'pricing_unit_label') String get pricingUnitLabel; String get quantity;@JsonKey(name: 'unit_price') String get unitPrice;@JsonKey(name: 'line_total') String get lineTotal; String? get notes;
/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderItemCopyWith<OrderItem> get copyWith => _$OrderItemCopyWithImpl<OrderItem>(this as OrderItem, _$identity);

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.variantLabel, variantLabel) || other.variantLabel == variantLabel)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productName,variantLabel,pricingUnitLabel,quantity,unitPrice,lineTotal,notes);

@override
String toString() {
  return 'OrderItem(id: $id, productName: $productName, variantLabel: $variantLabel, pricingUnitLabel: $pricingUnitLabel, quantity: $quantity, unitPrice: $unitPrice, lineTotal: $lineTotal, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $OrderItemCopyWith<$Res>  {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) _then) = _$OrderItemCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'product_name') String productName,@JsonKey(name: 'variant_label') String variantLabel,@JsonKey(name: 'pricing_unit_label') String pricingUnitLabel, String quantity,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'line_total') String lineTotal, String? notes
});




}
/// @nodoc
class _$OrderItemCopyWithImpl<$Res>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._self, this._then);

  final OrderItem _self;
  final $Res Function(OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productName = null,Object? variantLabel = null,Object? pricingUnitLabel = null,Object? quantity = null,Object? unitPrice = null,Object? lineTotal = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,variantLabel: null == variantLabel ? _self.variantLabel : variantLabel // ignore: cast_nullable_to_non_nullable
as String,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderItem].
extension OrderItemPatterns on OrderItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderItem value)  $default,){
final _that = this;
switch (_that) {
case _OrderItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'variant_label')  String variantLabel, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel,  String quantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'line_total')  String lineTotal,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.id,_that.productName,_that.variantLabel,_that.pricingUnitLabel,_that.quantity,_that.unitPrice,_that.lineTotal,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'variant_label')  String variantLabel, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel,  String quantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'line_total')  String lineTotal,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _OrderItem():
return $default(_that.id,_that.productName,_that.variantLabel,_that.pricingUnitLabel,_that.quantity,_that.unitPrice,_that.lineTotal,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'variant_label')  String variantLabel, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel,  String quantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'line_total')  String lineTotal,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.id,_that.productName,_that.variantLabel,_that.pricingUnitLabel,_that.quantity,_that.unitPrice,_that.lineTotal,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderItem extends OrderItem {
  const _OrderItem({required this.id, @JsonKey(name: 'product_name') required this.productName, @JsonKey(name: 'variant_label') required this.variantLabel, @JsonKey(name: 'pricing_unit_label') required this.pricingUnitLabel, required this.quantity, @JsonKey(name: 'unit_price') required this.unitPrice, @JsonKey(name: 'line_total') required this.lineTotal, this.notes}): super._();
  factory _OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

@override final  int id;
/// The snapshot, not the catalogue. A product renamed since must not rewrite this invoice.
@override@JsonKey(name: 'product_name') final  String productName;
@override@JsonKey(name: 'variant_label') final  String variantLabel;
@override@JsonKey(name: 'pricing_unit_label') final  String pricingUnitLabel;
@override final  String quantity;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
@override@JsonKey(name: 'line_total') final  String lineTotal;
@override final  String? notes;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderItemCopyWith<_OrderItem> get copyWith => __$OrderItemCopyWithImpl<_OrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.variantLabel, variantLabel) || other.variantLabel == variantLabel)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productName,variantLabel,pricingUnitLabel,quantity,unitPrice,lineTotal,notes);

@override
String toString() {
  return 'OrderItem(id: $id, productName: $productName, variantLabel: $variantLabel, pricingUnitLabel: $pricingUnitLabel, quantity: $quantity, unitPrice: $unitPrice, lineTotal: $lineTotal, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$OrderItemCopyWith<$Res> implements $OrderItemCopyWith<$Res> {
  factory _$OrderItemCopyWith(_OrderItem value, $Res Function(_OrderItem) _then) = __$OrderItemCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'product_name') String productName,@JsonKey(name: 'variant_label') String variantLabel,@JsonKey(name: 'pricing_unit_label') String pricingUnitLabel, String quantity,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'line_total') String lineTotal, String? notes
});




}
/// @nodoc
class __$OrderItemCopyWithImpl<$Res>
    implements _$OrderItemCopyWith<$Res> {
  __$OrderItemCopyWithImpl(this._self, this._then);

  final _OrderItem _self;
  final $Res Function(_OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productName = null,Object? variantLabel = null,Object? pricingUnitLabel = null,Object? quantity = null,Object? unitPrice = null,Object? lineTotal = null,Object? notes = freezed,}) {
  return _then(_OrderItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,variantLabel: null == variantLabel ? _self.variantLabel : variantLabel // ignore: cast_nullable_to_non_nullable
as String,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OrderDesign {

 int get id; int get version; String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'is_reviewed') bool get isReviewed;@JsonKey(name: 'rejection_reason') String? get rejectionReason; String? get notes;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderDesignCopyWith<OrderDesign> get copyWith => _$OrderDesignCopyWithImpl<OrderDesign>(this as OrderDesign, _$identity);

  /// Serializes this OrderDesign to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDesign&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isReviewed, isReviewed) || other.isReviewed == isReviewed)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,version,status,statusLabel,isReviewed,rejectionReason,notes,createdAt);

@override
String toString() {
  return 'OrderDesign(id: $id, version: $version, status: $status, statusLabel: $statusLabel, isReviewed: $isReviewed, rejectionReason: $rejectionReason, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderDesignCopyWith<$Res>  {
  factory $OrderDesignCopyWith(OrderDesign value, $Res Function(OrderDesign) _then) = _$OrderDesignCopyWithImpl;
@useResult
$Res call({
 int id, int version, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_reviewed') bool isReviewed,@JsonKey(name: 'rejection_reason') String? rejectionReason, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$OrderDesignCopyWithImpl<$Res>
    implements $OrderDesignCopyWith<$Res> {
  _$OrderDesignCopyWithImpl(this._self, this._then);

  final OrderDesign _self;
  final $Res Function(OrderDesign) _then;

/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? version = null,Object? status = null,Object? statusLabel = null,Object? isReviewed = null,Object? rejectionReason = freezed,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isReviewed: null == isReviewed ? _self.isReviewed : isReviewed // ignore: cast_nullable_to_non_nullable
as bool,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderDesign].
extension OrderDesignPatterns on OrderDesign {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderDesign value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderDesign() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderDesign value)  $default,){
final _that = this;
switch (_that) {
case _OrderDesign():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderDesign value)?  $default,){
final _that = this;
switch (_that) {
case _OrderDesign() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int version,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_reviewed')  bool isReviewed, @JsonKey(name: 'rejection_reason')  String? rejectionReason,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderDesign() when $default != null:
return $default(_that.id,_that.version,_that.status,_that.statusLabel,_that.isReviewed,_that.rejectionReason,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int version,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_reviewed')  bool isReviewed, @JsonKey(name: 'rejection_reason')  String? rejectionReason,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _OrderDesign():
return $default(_that.id,_that.version,_that.status,_that.statusLabel,_that.isReviewed,_that.rejectionReason,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int version,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_reviewed')  bool isReviewed, @JsonKey(name: 'rejection_reason')  String? rejectionReason,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderDesign() when $default != null:
return $default(_that.id,_that.version,_that.status,_that.statusLabel,_that.isReviewed,_that.rejectionReason,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderDesign extends OrderDesign {
  const _OrderDesign({required this.id, required this.version, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'is_reviewed') this.isReviewed = false, @JsonKey(name: 'rejection_reason') this.rejectionReason, this.notes, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _OrderDesign.fromJson(Map<String, dynamic> json) => _$OrderDesignFromJson(json);

@override final  int id;
@override final  int version;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'is_reviewed') final  bool isReviewed;
@override@JsonKey(name: 'rejection_reason') final  String? rejectionReason;
@override final  String? notes;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderDesignCopyWith<_OrderDesign> get copyWith => __$OrderDesignCopyWithImpl<_OrderDesign>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderDesignToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderDesign&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isReviewed, isReviewed) || other.isReviewed == isReviewed)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,version,status,statusLabel,isReviewed,rejectionReason,notes,createdAt);

@override
String toString() {
  return 'OrderDesign(id: $id, version: $version, status: $status, statusLabel: $statusLabel, isReviewed: $isReviewed, rejectionReason: $rejectionReason, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderDesignCopyWith<$Res> implements $OrderDesignCopyWith<$Res> {
  factory _$OrderDesignCopyWith(_OrderDesign value, $Res Function(_OrderDesign) _then) = __$OrderDesignCopyWithImpl;
@override @useResult
$Res call({
 int id, int version, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_reviewed') bool isReviewed,@JsonKey(name: 'rejection_reason') String? rejectionReason, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$OrderDesignCopyWithImpl<$Res>
    implements _$OrderDesignCopyWith<$Res> {
  __$OrderDesignCopyWithImpl(this._self, this._then);

  final _OrderDesign _self;
  final $Res Function(_OrderDesign) _then;

/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? version = null,Object? status = null,Object? statusLabel = null,Object? isReviewed = null,Object? rejectionReason = freezed,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_OrderDesign(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isReviewed: null == isReviewed ? _self.isReviewed : isReviewed // ignore: cast_nullable_to_non_nullable
as bool,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$OrderTransitionRecord {

 int get id;/// Null exactly once per order: the row that records it being taken.
@JsonKey(name: 'from_status_label') String? get fromStatusLabel;@JsonKey(name: 'to_status_label') String get toStatusLabel; String? get reason;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTransitionRecordCopyWith<OrderTransitionRecord> get copyWith => _$OrderTransitionRecordCopyWithImpl<OrderTransitionRecord>(this as OrderTransitionRecord, _$identity);

  /// Serializes this OrderTransitionRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTransitionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.fromStatusLabel, fromStatusLabel) || other.fromStatusLabel == fromStatusLabel)&&(identical(other.toStatusLabel, toStatusLabel) || other.toStatusLabel == toStatusLabel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromStatusLabel,toStatusLabel,reason,createdAt);

@override
String toString() {
  return 'OrderTransitionRecord(id: $id, fromStatusLabel: $fromStatusLabel, toStatusLabel: $toStatusLabel, reason: $reason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderTransitionRecordCopyWith<$Res>  {
  factory $OrderTransitionRecordCopyWith(OrderTransitionRecord value, $Res Function(OrderTransitionRecord) _then) = _$OrderTransitionRecordCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'from_status_label') String? fromStatusLabel,@JsonKey(name: 'to_status_label') String toStatusLabel, String? reason,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$OrderTransitionRecordCopyWithImpl<$Res>
    implements $OrderTransitionRecordCopyWith<$Res> {
  _$OrderTransitionRecordCopyWithImpl(this._self, this._then);

  final OrderTransitionRecord _self;
  final $Res Function(OrderTransitionRecord) _then;

/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromStatusLabel = freezed,Object? toStatusLabel = null,Object? reason = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fromStatusLabel: freezed == fromStatusLabel ? _self.fromStatusLabel : fromStatusLabel // ignore: cast_nullable_to_non_nullable
as String?,toStatusLabel: null == toStatusLabel ? _self.toStatusLabel : toStatusLabel // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderTransitionRecord].
extension OrderTransitionRecordPatterns on OrderTransitionRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderTransitionRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderTransitionRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderTransitionRecord value)  $default,){
final _that = this;
switch (_that) {
case _OrderTransitionRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderTransitionRecord value)?  $default,){
final _that = this;
switch (_that) {
case _OrderTransitionRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'from_status_label')  String? fromStatusLabel, @JsonKey(name: 'to_status_label')  String toStatusLabel,  String? reason, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderTransitionRecord() when $default != null:
return $default(_that.id,_that.fromStatusLabel,_that.toStatusLabel,_that.reason,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'from_status_label')  String? fromStatusLabel, @JsonKey(name: 'to_status_label')  String toStatusLabel,  String? reason, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _OrderTransitionRecord():
return $default(_that.id,_that.fromStatusLabel,_that.toStatusLabel,_that.reason,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'from_status_label')  String? fromStatusLabel, @JsonKey(name: 'to_status_label')  String toStatusLabel,  String? reason, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderTransitionRecord() when $default != null:
return $default(_that.id,_that.fromStatusLabel,_that.toStatusLabel,_that.reason,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderTransitionRecord extends OrderTransitionRecord {
  const _OrderTransitionRecord({required this.id, @JsonKey(name: 'from_status_label') this.fromStatusLabel, @JsonKey(name: 'to_status_label') required this.toStatusLabel, this.reason, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _OrderTransitionRecord.fromJson(Map<String, dynamic> json) => _$OrderTransitionRecordFromJson(json);

@override final  int id;
/// Null exactly once per order: the row that records it being taken.
@override@JsonKey(name: 'from_status_label') final  String? fromStatusLabel;
@override@JsonKey(name: 'to_status_label') final  String toStatusLabel;
@override final  String? reason;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderTransitionRecordCopyWith<_OrderTransitionRecord> get copyWith => __$OrderTransitionRecordCopyWithImpl<_OrderTransitionRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderTransitionRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderTransitionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.fromStatusLabel, fromStatusLabel) || other.fromStatusLabel == fromStatusLabel)&&(identical(other.toStatusLabel, toStatusLabel) || other.toStatusLabel == toStatusLabel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromStatusLabel,toStatusLabel,reason,createdAt);

@override
String toString() {
  return 'OrderTransitionRecord(id: $id, fromStatusLabel: $fromStatusLabel, toStatusLabel: $toStatusLabel, reason: $reason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderTransitionRecordCopyWith<$Res> implements $OrderTransitionRecordCopyWith<$Res> {
  factory _$OrderTransitionRecordCopyWith(_OrderTransitionRecord value, $Res Function(_OrderTransitionRecord) _then) = __$OrderTransitionRecordCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'from_status_label') String? fromStatusLabel,@JsonKey(name: 'to_status_label') String toStatusLabel, String? reason,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$OrderTransitionRecordCopyWithImpl<$Res>
    implements _$OrderTransitionRecordCopyWith<$Res> {
  __$OrderTransitionRecordCopyWithImpl(this._self, this._then);

  final _OrderTransitionRecord _self;
  final $Res Function(_OrderTransitionRecord) _then;

/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromStatusLabel = freezed,Object? toStatusLabel = null,Object? reason = freezed,Object? createdAt = freezed,}) {
  return _then(_OrderTransitionRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fromStatusLabel: freezed == fromStatusLabel ? _self.fromStatusLabel : fromStatusLabel // ignore: cast_nullable_to_non_nullable
as String?,toStatusLabel: null == toStatusLabel ? _self.toStatusLabel : toStatusLabel // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
