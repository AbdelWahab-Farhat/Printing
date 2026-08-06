// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NewOrder {

@JsonKey(name: 'customer_id') int get customerId;@JsonKey(name: 'city_id') int get cityId;/// `none` · `customer` · `in_house`. Whose work the artwork was, which is the one thing
/// about a design that may move money.
@JsonKey(name: 'design_source') String get designSource;/// At least one, or the server refuses the order — `OrderNeedsAtLeastOneItem`.
 List<NewOrderItem> get items;/// Which of the customer's shops this is for. Omitted from the body when absent, because
/// «this customer has no branch in it» is different from «null».
@JsonKey(name: 'customer_shop_id', includeIfNull: false) int? get customerShopId;/// Required by the *city*, not by this model: a city marked as needing one refuses an order
/// without it, and the server's sentence says so.
@JsonKey(name: 'region_id', includeIfNull: false) int? get regionId;/// Only counted when [designSource] is `in_house`. Sent as a decimal string, never a number.
@JsonKey(name: 'design_fee', includeIfNull: false) String? get designFee;/// Guarded by `orders.discount` on the server. The field is hidden in the app for staff
/// without the grant; that is the suggestion, and the refusal is the rule.
@JsonKey(includeIfNull: false) String? get discount;@JsonKey(name: 'recipient_name', includeIfNull: false) String? get recipientName;@JsonKey(name: 'recipient_phone', includeIfNull: false) String? get recipientPhone;@JsonKey(name: 'address_details', includeIfNull: false) String? get addressDetails;@JsonKey(includeIfNull: false) String? get notes;
/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewOrderCopyWith<NewOrder> get copyWith => _$NewOrderCopyWithImpl<NewOrder>(this as NewOrder, _$identity);

  /// Serializes this NewOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewOrder&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.designSource, designSource) || other.designSource == designSource)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.customerShopId, customerShopId) || other.customerShopId == customerShopId)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,cityId,designSource,const DeepCollectionEquality().hash(items),customerShopId,regionId,designFee,discount,recipientName,recipientPhone,addressDetails,notes);

@override
String toString() {
  return 'NewOrder(customerId: $customerId, cityId: $cityId, designSource: $designSource, items: $items, customerShopId: $customerShopId, regionId: $regionId, designFee: $designFee, discount: $discount, recipientName: $recipientName, recipientPhone: $recipientPhone, addressDetails: $addressDetails, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $NewOrderCopyWith<$Res>  {
  factory $NewOrderCopyWith(NewOrder value, $Res Function(NewOrder) _then) = _$NewOrderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'city_id') int cityId,@JsonKey(name: 'design_source') String designSource, List<NewOrderItem> items,@JsonKey(name: 'customer_shop_id', includeIfNull: false) int? customerShopId,@JsonKey(name: 'region_id', includeIfNull: false) int? regionId,@JsonKey(name: 'design_fee', includeIfNull: false) String? designFee,@JsonKey(includeIfNull: false) String? discount,@JsonKey(name: 'recipient_name', includeIfNull: false) String? recipientName,@JsonKey(name: 'recipient_phone', includeIfNull: false) String? recipientPhone,@JsonKey(name: 'address_details', includeIfNull: false) String? addressDetails,@JsonKey(includeIfNull: false) String? notes
});




}
/// @nodoc
class _$NewOrderCopyWithImpl<$Res>
    implements $NewOrderCopyWith<$Res> {
  _$NewOrderCopyWithImpl(this._self, this._then);

  final NewOrder _self;
  final $Res Function(NewOrder) _then;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? customerId = null,Object? cityId = null,Object? designSource = null,Object? items = null,Object? customerShopId = freezed,Object? regionId = freezed,Object? designFee = freezed,Object? discount = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,designSource: null == designSource ? _self.designSource : designSource // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NewOrderItem>,customerShopId: freezed == customerShopId ? _self.customerShopId : customerShopId // ignore: cast_nullable_to_non_nullable
as int?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,designFee: freezed == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String?,discount: freezed == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewOrder].
extension NewOrderPatterns on NewOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewOrder value)  $default,){
final _that = this;
switch (_that) {
case _NewOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewOrder value)?  $default,){
final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'design_source')  String designSource,  List<NewOrderItem> items, @JsonKey(name: 'customer_shop_id', includeIfNull: false)  int? customerShopId, @JsonKey(name: 'region_id', includeIfNull: false)  int? regionId, @JsonKey(name: 'design_fee', includeIfNull: false)  String? designFee, @JsonKey(includeIfNull: false)  String? discount, @JsonKey(name: 'recipient_name', includeIfNull: false)  String? recipientName, @JsonKey(name: 'recipient_phone', includeIfNull: false)  String? recipientPhone, @JsonKey(name: 'address_details', includeIfNull: false)  String? addressDetails, @JsonKey(includeIfNull: false)  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that.customerId,_that.cityId,_that.designSource,_that.items,_that.customerShopId,_that.regionId,_that.designFee,_that.discount,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'design_source')  String designSource,  List<NewOrderItem> items, @JsonKey(name: 'customer_shop_id', includeIfNull: false)  int? customerShopId, @JsonKey(name: 'region_id', includeIfNull: false)  int? regionId, @JsonKey(name: 'design_fee', includeIfNull: false)  String? designFee, @JsonKey(includeIfNull: false)  String? discount, @JsonKey(name: 'recipient_name', includeIfNull: false)  String? recipientName, @JsonKey(name: 'recipient_phone', includeIfNull: false)  String? recipientPhone, @JsonKey(name: 'address_details', includeIfNull: false)  String? addressDetails, @JsonKey(includeIfNull: false)  String? notes)  $default,) {final _that = this;
switch (_that) {
case _NewOrder():
return $default(_that.customerId,_that.cityId,_that.designSource,_that.items,_that.customerShopId,_that.regionId,_that.designFee,_that.discount,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'design_source')  String designSource,  List<NewOrderItem> items, @JsonKey(name: 'customer_shop_id', includeIfNull: false)  int? customerShopId, @JsonKey(name: 'region_id', includeIfNull: false)  int? regionId, @JsonKey(name: 'design_fee', includeIfNull: false)  String? designFee, @JsonKey(includeIfNull: false)  String? discount, @JsonKey(name: 'recipient_name', includeIfNull: false)  String? recipientName, @JsonKey(name: 'recipient_phone', includeIfNull: false)  String? recipientPhone, @JsonKey(name: 'address_details', includeIfNull: false)  String? addressDetails, @JsonKey(includeIfNull: false)  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that.customerId,_that.cityId,_that.designSource,_that.items,_that.customerShopId,_that.regionId,_that.designFee,_that.discount,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewOrder implements NewOrder {
  const _NewOrder({@JsonKey(name: 'customer_id') required this.customerId, @JsonKey(name: 'city_id') required this.cityId, @JsonKey(name: 'design_source') required this.designSource, required final  List<NewOrderItem> items, @JsonKey(name: 'customer_shop_id', includeIfNull: false) this.customerShopId, @JsonKey(name: 'region_id', includeIfNull: false) this.regionId, @JsonKey(name: 'design_fee', includeIfNull: false) this.designFee, @JsonKey(includeIfNull: false) this.discount, @JsonKey(name: 'recipient_name', includeIfNull: false) this.recipientName, @JsonKey(name: 'recipient_phone', includeIfNull: false) this.recipientPhone, @JsonKey(name: 'address_details', includeIfNull: false) this.addressDetails, @JsonKey(includeIfNull: false) this.notes}): _items = items;
  factory _NewOrder.fromJson(Map<String, dynamic> json) => _$NewOrderFromJson(json);

@override@JsonKey(name: 'customer_id') final  int customerId;
@override@JsonKey(name: 'city_id') final  int cityId;
/// `none` · `customer` · `in_house`. Whose work the artwork was, which is the one thing
/// about a design that may move money.
@override@JsonKey(name: 'design_source') final  String designSource;
/// At least one, or the server refuses the order — `OrderNeedsAtLeastOneItem`.
 final  List<NewOrderItem> _items;
/// At least one, or the server refuses the order — `OrderNeedsAtLeastOneItem`.
@override List<NewOrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Which of the customer's shops this is for. Omitted from the body when absent, because
/// «this customer has no branch in it» is different from «null».
@override@JsonKey(name: 'customer_shop_id', includeIfNull: false) final  int? customerShopId;
/// Required by the *city*, not by this model: a city marked as needing one refuses an order
/// without it, and the server's sentence says so.
@override@JsonKey(name: 'region_id', includeIfNull: false) final  int? regionId;
/// Only counted when [designSource] is `in_house`. Sent as a decimal string, never a number.
@override@JsonKey(name: 'design_fee', includeIfNull: false) final  String? designFee;
/// Guarded by `orders.discount` on the server. The field is hidden in the app for staff
/// without the grant; that is the suggestion, and the refusal is the rule.
@override@JsonKey(includeIfNull: false) final  String? discount;
@override@JsonKey(name: 'recipient_name', includeIfNull: false) final  String? recipientName;
@override@JsonKey(name: 'recipient_phone', includeIfNull: false) final  String? recipientPhone;
@override@JsonKey(name: 'address_details', includeIfNull: false) final  String? addressDetails;
@override@JsonKey(includeIfNull: false) final  String? notes;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewOrderCopyWith<_NewOrder> get copyWith => __$NewOrderCopyWithImpl<_NewOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewOrder&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.designSource, designSource) || other.designSource == designSource)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.customerShopId, customerShopId) || other.customerShopId == customerShopId)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,cityId,designSource,const DeepCollectionEquality().hash(_items),customerShopId,regionId,designFee,discount,recipientName,recipientPhone,addressDetails,notes);

@override
String toString() {
  return 'NewOrder(customerId: $customerId, cityId: $cityId, designSource: $designSource, items: $items, customerShopId: $customerShopId, regionId: $regionId, designFee: $designFee, discount: $discount, recipientName: $recipientName, recipientPhone: $recipientPhone, addressDetails: $addressDetails, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$NewOrderCopyWith<$Res> implements $NewOrderCopyWith<$Res> {
  factory _$NewOrderCopyWith(_NewOrder value, $Res Function(_NewOrder) _then) = __$NewOrderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'city_id') int cityId,@JsonKey(name: 'design_source') String designSource, List<NewOrderItem> items,@JsonKey(name: 'customer_shop_id', includeIfNull: false) int? customerShopId,@JsonKey(name: 'region_id', includeIfNull: false) int? regionId,@JsonKey(name: 'design_fee', includeIfNull: false) String? designFee,@JsonKey(includeIfNull: false) String? discount,@JsonKey(name: 'recipient_name', includeIfNull: false) String? recipientName,@JsonKey(name: 'recipient_phone', includeIfNull: false) String? recipientPhone,@JsonKey(name: 'address_details', includeIfNull: false) String? addressDetails,@JsonKey(includeIfNull: false) String? notes
});




}
/// @nodoc
class __$NewOrderCopyWithImpl<$Res>
    implements _$NewOrderCopyWith<$Res> {
  __$NewOrderCopyWithImpl(this._self, this._then);

  final _NewOrder _self;
  final $Res Function(_NewOrder) _then;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? customerId = null,Object? cityId = null,Object? designSource = null,Object? items = null,Object? customerShopId = freezed,Object? regionId = freezed,Object? designFee = freezed,Object? discount = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? notes = freezed,}) {
  return _then(_NewOrder(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,designSource: null == designSource ? _self.designSource : designSource // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NewOrderItem>,customerShopId: freezed == customerShopId ? _self.customerShopId : customerShopId // ignore: cast_nullable_to_non_nullable
as int?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,designFee: freezed == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String?,discount: freezed == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$NewOrderItem {

@JsonKey(name: 'product_id') int get productId;@JsonKey(name: 'product_variant_id') int get productVariantId;/// A decimal string, already in ASCII digits — `'300'`, not `'٣٠٠'`.
 String get quantity;/// **Honoured only for a product the catalogue prices «حسب الطلب»**, and ignored otherwise:
/// for a listed product the catalogue's rate wins, which is what stops a posted number
/// undercutting an agreed price. Omitted when the app has no business naming one.
@JsonKey(name: 'unit_price', includeIfNull: false) String? get unitPrice;@JsonKey(includeIfNull: false) String? get notes;/// The order the clerk put the lines in, kept so the invoice reads the way it was written.
@JsonKey(name: 'sort_order') int get sortOrder;
/// Create a copy of NewOrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewOrderItemCopyWith<NewOrderItem> get copyWith => _$NewOrderItemCopyWithImpl<NewOrderItem>(this as NewOrderItem, _$identity);

  /// Serializes this NewOrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewOrderItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productVariantId,quantity,unitPrice,notes,sortOrder);

@override
String toString() {
  return 'NewOrderItem(productId: $productId, productVariantId: $productVariantId, quantity: $quantity, unitPrice: $unitPrice, notes: $notes, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $NewOrderItemCopyWith<$Res>  {
  factory $NewOrderItemCopyWith(NewOrderItem value, $Res Function(NewOrderItem) _then) = _$NewOrderItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId, String quantity,@JsonKey(name: 'unit_price', includeIfNull: false) String? unitPrice,@JsonKey(includeIfNull: false) String? notes,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class _$NewOrderItemCopyWithImpl<$Res>
    implements $NewOrderItemCopyWith<$Res> {
  _$NewOrderItemCopyWithImpl(this._self, this._then);

  final NewOrderItem _self;
  final $Res Function(NewOrderItem) _then;

/// Create a copy of NewOrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productVariantId = null,Object? quantity = null,Object? unitPrice = freezed,Object? notes = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NewOrderItem].
extension NewOrderItemPatterns on NewOrderItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewOrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewOrderItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewOrderItem value)  $default,){
final _that = this;
switch (_that) {
case _NewOrderItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewOrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _NewOrderItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity, @JsonKey(name: 'unit_price', includeIfNull: false)  String? unitPrice, @JsonKey(includeIfNull: false)  String? notes, @JsonKey(name: 'sort_order')  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewOrderItem() when $default != null:
return $default(_that.productId,_that.productVariantId,_that.quantity,_that.unitPrice,_that.notes,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity, @JsonKey(name: 'unit_price', includeIfNull: false)  String? unitPrice, @JsonKey(includeIfNull: false)  String? notes, @JsonKey(name: 'sort_order')  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _NewOrderItem():
return $default(_that.productId,_that.productVariantId,_that.quantity,_that.unitPrice,_that.notes,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity, @JsonKey(name: 'unit_price', includeIfNull: false)  String? unitPrice, @JsonKey(includeIfNull: false)  String? notes, @JsonKey(name: 'sort_order')  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _NewOrderItem() when $default != null:
return $default(_that.productId,_that.productVariantId,_that.quantity,_that.unitPrice,_that.notes,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewOrderItem implements NewOrderItem {
  const _NewOrderItem({@JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'product_variant_id') required this.productVariantId, required this.quantity, @JsonKey(name: 'unit_price', includeIfNull: false) this.unitPrice, @JsonKey(includeIfNull: false) this.notes, @JsonKey(name: 'sort_order') this.sortOrder = 0});
  factory _NewOrderItem.fromJson(Map<String, dynamic> json) => _$NewOrderItemFromJson(json);

@override@JsonKey(name: 'product_id') final  int productId;
@override@JsonKey(name: 'product_variant_id') final  int productVariantId;
/// A decimal string, already in ASCII digits — `'300'`, not `'٣٠٠'`.
@override final  String quantity;
/// **Honoured only for a product the catalogue prices «حسب الطلب»**, and ignored otherwise:
/// for a listed product the catalogue's rate wins, which is what stops a posted number
/// undercutting an agreed price. Omitted when the app has no business naming one.
@override@JsonKey(name: 'unit_price', includeIfNull: false) final  String? unitPrice;
@override@JsonKey(includeIfNull: false) final  String? notes;
/// The order the clerk put the lines in, kept so the invoice reads the way it was written.
@override@JsonKey(name: 'sort_order') final  int sortOrder;

/// Create a copy of NewOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewOrderItemCopyWith<_NewOrderItem> get copyWith => __$NewOrderItemCopyWithImpl<_NewOrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewOrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewOrderItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productVariantId,quantity,unitPrice,notes,sortOrder);

@override
String toString() {
  return 'NewOrderItem(productId: $productId, productVariantId: $productVariantId, quantity: $quantity, unitPrice: $unitPrice, notes: $notes, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$NewOrderItemCopyWith<$Res> implements $NewOrderItemCopyWith<$Res> {
  factory _$NewOrderItemCopyWith(_NewOrderItem value, $Res Function(_NewOrderItem) _then) = __$NewOrderItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId, String quantity,@JsonKey(name: 'unit_price', includeIfNull: false) String? unitPrice,@JsonKey(includeIfNull: false) String? notes,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class __$NewOrderItemCopyWithImpl<$Res>
    implements _$NewOrderItemCopyWith<$Res> {
  __$NewOrderItemCopyWithImpl(this._self, this._then);

  final _NewOrderItem _self;
  final $Res Function(_NewOrderItem) _then;

/// Create a copy of NewOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productVariantId = null,Object? quantity = null,Object? unitPrice = freezed,Object? notes = freezed,Object? sortOrder = null,}) {
  return _then(_NewOrderItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
