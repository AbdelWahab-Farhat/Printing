// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Customer {

 int get id;/// The permanent human-facing identifier — `C1`, `C2`, `C3` … Allocated by the server and
/// never sent by this app: it is read-only here by construction, not by convention.
 String get code; String get name; String get phone;/// A customer is deactivated, never deleted, so their orders keep pointing at a row that
/// still exists. There is no destroy endpoint to call.
@JsonKey(name: 'is_active') bool get isActive;/// Absent — not empty — when the API did not load them. `whenLoaded` on the backend means
/// a missing key rather than `[]`, and "we did not ask" is a different fact from "this
/// customer has none".
 List<CustomerShop>? get shops;/// How many orders this customer has placed, ever — cancellations included.
///
/// **Null is «we were not told», and it happens two ways.** A reader without `orders.view`
/// is not sent the key at all, and neither is the response to saving the form. Both are
/// different from `0`, which is a real answer about a real customer — so a card draws the
/// number when there is one and draws nothing when there is not, rather than printing a
/// nought it was never given. See CUSTOMER-ORDERS-SECTION.md §٣.
@JsonKey(name: 'orders_count') int? get ordersCount;/// When this customer last placed an order.
///
/// **Sent only by the list that is sorted by it** — `sort=least_recent_order`, the call
/// sheet — because that is the only screen that shows it and the only request that pays for
/// the subquery behind it. Null covers both «this customer has never ordered», which is the
/// answer that sort gives explicitly, and «no list asked»; the card tells them apart by
/// [ordersCount], which is on every row.
@JsonKey(name: 'last_order_at') DateTime? get lastOrderAt;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerCopyWith<Customer> get copyWith => _$CustomerCopyWithImpl<Customer>(this as Customer, _$identity);

  /// Serializes this Customer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other.shops, shops)&&(identical(other.ordersCount, ordersCount) || other.ordersCount == ordersCount)&&(identical(other.lastOrderAt, lastOrderAt) || other.lastOrderAt == lastOrderAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone,isActive,const DeepCollectionEquality().hash(shops),ordersCount,lastOrderAt,createdAt,updatedAt);

@override
String toString() {
  return 'Customer(id: $id, code: $code, name: $name, phone: $phone, isActive: $isActive, shops: $shops, ordersCount: $ordersCount, lastOrderAt: $lastOrderAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CustomerCopyWith<$Res>  {
  factory $CustomerCopyWith(Customer value, $Res Function(Customer) _then) = _$CustomerCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name, String phone,@JsonKey(name: 'is_active') bool isActive, List<CustomerShop>? shops,@JsonKey(name: 'orders_count') int? ordersCount,@JsonKey(name: 'last_order_at') DateTime? lastOrderAt,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$CustomerCopyWithImpl<$Res>
    implements $CustomerCopyWith<$Res> {
  _$CustomerCopyWithImpl(this._self, this._then);

  final Customer _self;
  final $Res Function(Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? phone = null,Object? isActive = null,Object? shops = freezed,Object? ordersCount = freezed,Object? lastOrderAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,shops: freezed == shops ? _self.shops : shops // ignore: cast_nullable_to_non_nullable
as List<CustomerShop>?,ordersCount: freezed == ordersCount ? _self.ordersCount : ordersCount // ignore: cast_nullable_to_non_nullable
as int?,lastOrderAt: freezed == lastOrderAt ? _self.lastOrderAt : lastOrderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Customer].
extension CustomerPatterns on Customer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Customer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Customer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Customer value)  $default,){
final _that = this;
switch (_that) {
case _Customer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Customer value)?  $default,){
final _that = this;
switch (_that) {
case _Customer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String phone, @JsonKey(name: 'is_active')  bool isActive,  List<CustomerShop>? shops, @JsonKey(name: 'orders_count')  int? ordersCount, @JsonKey(name: 'last_order_at')  DateTime? lastOrderAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.phone,_that.isActive,_that.shops,_that.ordersCount,_that.lastOrderAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String phone, @JsonKey(name: 'is_active')  bool isActive,  List<CustomerShop>? shops, @JsonKey(name: 'orders_count')  int? ordersCount, @JsonKey(name: 'last_order_at')  DateTime? lastOrderAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Customer():
return $default(_that.id,_that.code,_that.name,_that.phone,_that.isActive,_that.shops,_that.ordersCount,_that.lastOrderAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name,  String phone, @JsonKey(name: 'is_active')  bool isActive,  List<CustomerShop>? shops, @JsonKey(name: 'orders_count')  int? ordersCount, @JsonKey(name: 'last_order_at')  DateTime? lastOrderAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.phone,_that.isActive,_that.shops,_that.ordersCount,_that.lastOrderAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Customer extends Customer {
  const _Customer({required this.id, required this.code, required this.name, required this.phone, @JsonKey(name: 'is_active') required this.isActive, final  List<CustomerShop>? shops, @JsonKey(name: 'orders_count') this.ordersCount, @JsonKey(name: 'last_order_at') this.lastOrderAt, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _shops = shops,super._();
  factory _Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);

@override final  int id;
/// The permanent human-facing identifier — `C1`, `C2`, `C3` … Allocated by the server and
/// never sent by this app: it is read-only here by construction, not by convention.
@override final  String code;
@override final  String name;
@override final  String phone;
/// A customer is deactivated, never deleted, so their orders keep pointing at a row that
/// still exists. There is no destroy endpoint to call.
@override@JsonKey(name: 'is_active') final  bool isActive;
/// Absent — not empty — when the API did not load them. `whenLoaded` on the backend means
/// a missing key rather than `[]`, and "we did not ask" is a different fact from "this
/// customer has none".
 final  List<CustomerShop>? _shops;
/// Absent — not empty — when the API did not load them. `whenLoaded` on the backend means
/// a missing key rather than `[]`, and "we did not ask" is a different fact from "this
/// customer has none".
@override List<CustomerShop>? get shops {
  final value = _shops;
  if (value == null) return null;
  if (_shops is EqualUnmodifiableListView) return _shops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// How many orders this customer has placed, ever — cancellations included.
///
/// **Null is «we were not told», and it happens two ways.** A reader without `orders.view`
/// is not sent the key at all, and neither is the response to saving the form. Both are
/// different from `0`, which is a real answer about a real customer — so a card draws the
/// number when there is one and draws nothing when there is not, rather than printing a
/// nought it was never given. See CUSTOMER-ORDERS-SECTION.md §٣.
@override@JsonKey(name: 'orders_count') final  int? ordersCount;
/// When this customer last placed an order.
///
/// **Sent only by the list that is sorted by it** — `sort=least_recent_order`, the call
/// sheet — because that is the only screen that shows it and the only request that pays for
/// the subquery behind it. Null covers both «this customer has never ordered», which is the
/// answer that sort gives explicitly, and «no list asked»; the card tells them apart by
/// [ordersCount], which is on every row.
@override@JsonKey(name: 'last_order_at') final  DateTime? lastOrderAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerCopyWith<_Customer> get copyWith => __$CustomerCopyWithImpl<_Customer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other._shops, _shops)&&(identical(other.ordersCount, ordersCount) || other.ordersCount == ordersCount)&&(identical(other.lastOrderAt, lastOrderAt) || other.lastOrderAt == lastOrderAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone,isActive,const DeepCollectionEquality().hash(_shops),ordersCount,lastOrderAt,createdAt,updatedAt);

@override
String toString() {
  return 'Customer(id: $id, code: $code, name: $name, phone: $phone, isActive: $isActive, shops: $shops, ordersCount: $ordersCount, lastOrderAt: $lastOrderAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CustomerCopyWith<$Res> implements $CustomerCopyWith<$Res> {
  factory _$CustomerCopyWith(_Customer value, $Res Function(_Customer) _then) = __$CustomerCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name, String phone,@JsonKey(name: 'is_active') bool isActive, List<CustomerShop>? shops,@JsonKey(name: 'orders_count') int? ordersCount,@JsonKey(name: 'last_order_at') DateTime? lastOrderAt,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$CustomerCopyWithImpl<$Res>
    implements _$CustomerCopyWith<$Res> {
  __$CustomerCopyWithImpl(this._self, this._then);

  final _Customer _self;
  final $Res Function(_Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? phone = null,Object? isActive = null,Object? shops = freezed,Object? ordersCount = freezed,Object? lastOrderAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Customer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,shops: freezed == shops ? _self._shops : shops // ignore: cast_nullable_to_non_nullable
as List<CustomerShop>?,ordersCount: freezed == ordersCount ? _self.ordersCount : ordersCount // ignore: cast_nullable_to_non_nullable
as int?,lastOrderAt: freezed == lastOrderAt ? _self.lastOrderAt : lastOrderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CustomerShop {

 int get id; String get name;/// المدينة — required by the API, so a shop that came from it has one. Nullable here all
/// the same: `city` is the *object*, and the server omits it when the relation was not
/// loaded or the city has since been deleted.
@JsonKey(name: 'city_id') int? get cityId; City? get city;/// المنطقة — genuinely optional. Most cities have no neighbourhoods, and a shop taken over
/// the phone often has none recorded.
@JsonKey(name: 'region_id') int? get regionId; Region? get region;/// Numbers, not strings: these go straight into a map SDK. Null for every shop recorded
/// since the form stopped asking for a pin — which is why nothing reads them today. The
/// field stays so the pin survives a round trip through this app untouched.
 double? get latitude; double? get longitude;@JsonKey(name: 'page_url') String? get pageUrl;/// مجال العمل — what this shop sells. Null for the shops recorded before the list existed,
/// and for one entered in a hurry; «لم يُحدَّد» is a real answer here, not a missing one.
@JsonKey(name: 'business_field_id') int? get businessFieldId;/// The trade itself, so a screen renders its name without fetching the list to translate
/// one number. Sent whenever the shop is loaded with it.
@JsonKey(name: 'business_field') BusinessField? get businessField;
/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerShopCopyWith<CustomerShop> get copyWith => _$CustomerShopCopyWithImpl<CustomerShop>(this as CustomerShop, _$identity);

  /// Serializes this CustomerShop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerShop&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.city, city) || other.city == city)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.region, region) || other.region == region)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl)&&(identical(other.businessFieldId, businessFieldId) || other.businessFieldId == businessFieldId)&&(identical(other.businessField, businessField) || other.businessField == businessField));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,cityId,city,regionId,region,latitude,longitude,pageUrl,businessFieldId,businessField);

@override
String toString() {
  return 'CustomerShop(id: $id, name: $name, cityId: $cityId, city: $city, regionId: $regionId, region: $region, latitude: $latitude, longitude: $longitude, pageUrl: $pageUrl, businessFieldId: $businessFieldId, businessField: $businessField)';
}


}

/// @nodoc
abstract mixin class $CustomerShopCopyWith<$Res>  {
  factory $CustomerShopCopyWith(CustomerShop value, $Res Function(CustomerShop) _then) = _$CustomerShopCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'city_id') int? cityId, City? city,@JsonKey(name: 'region_id') int? regionId, Region? region, double? latitude, double? longitude,@JsonKey(name: 'page_url') String? pageUrl,@JsonKey(name: 'business_field_id') int? businessFieldId,@JsonKey(name: 'business_field') BusinessField? businessField
});


$CityCopyWith<$Res>? get city;$RegionCopyWith<$Res>? get region;$BusinessFieldCopyWith<$Res>? get businessField;

}
/// @nodoc
class _$CustomerShopCopyWithImpl<$Res>
    implements $CustomerShopCopyWith<$Res> {
  _$CustomerShopCopyWithImpl(this._self, this._then);

  final CustomerShop _self;
  final $Res Function(CustomerShop) _then;

/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? cityId = freezed,Object? city = freezed,Object? regionId = freezed,Object? region = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? pageUrl = freezed,Object? businessFieldId = freezed,Object? businessField = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as City?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Region?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,businessFieldId: freezed == businessFieldId ? _self.businessFieldId : businessFieldId // ignore: cast_nullable_to_non_nullable
as int?,businessField: freezed == businessField ? _self.businessField : businessField // ignore: cast_nullable_to_non_nullable
as BusinessField?,
  ));
}
/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CityCopyWith<$Res>? get city {
    if (_self.city == null) {
    return null;
  }

  return $CityCopyWith<$Res>(_self.city!, (value) {
    return _then(_self.copyWith(city: value));
  });
}/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegionCopyWith<$Res>? get region {
    if (_self.region == null) {
    return null;
  }

  return $RegionCopyWith<$Res>(_self.region!, (value) {
    return _then(_self.copyWith(region: value));
  });
}/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessFieldCopyWith<$Res>? get businessField {
    if (_self.businessField == null) {
    return null;
  }

  return $BusinessFieldCopyWith<$Res>(_self.businessField!, (value) {
    return _then(_self.copyWith(businessField: value));
  });
}
}


/// Adds pattern-matching-related methods to [CustomerShop].
extension CustomerShopPatterns on CustomerShop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerShop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerShop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerShop value)  $default,){
final _that = this;
switch (_that) {
case _CustomerShop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerShop value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerShop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'city_id')  int? cityId,  City? city, @JsonKey(name: 'region_id')  int? regionId,  Region? region,  double? latitude,  double? longitude, @JsonKey(name: 'page_url')  String? pageUrl, @JsonKey(name: 'business_field_id')  int? businessFieldId, @JsonKey(name: 'business_field')  BusinessField? businessField)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerShop() when $default != null:
return $default(_that.id,_that.name,_that.cityId,_that.city,_that.regionId,_that.region,_that.latitude,_that.longitude,_that.pageUrl,_that.businessFieldId,_that.businessField);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'city_id')  int? cityId,  City? city, @JsonKey(name: 'region_id')  int? regionId,  Region? region,  double? latitude,  double? longitude, @JsonKey(name: 'page_url')  String? pageUrl, @JsonKey(name: 'business_field_id')  int? businessFieldId, @JsonKey(name: 'business_field')  BusinessField? businessField)  $default,) {final _that = this;
switch (_that) {
case _CustomerShop():
return $default(_that.id,_that.name,_that.cityId,_that.city,_that.regionId,_that.region,_that.latitude,_that.longitude,_that.pageUrl,_that.businessFieldId,_that.businessField);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'city_id')  int? cityId,  City? city, @JsonKey(name: 'region_id')  int? regionId,  Region? region,  double? latitude,  double? longitude, @JsonKey(name: 'page_url')  String? pageUrl, @JsonKey(name: 'business_field_id')  int? businessFieldId, @JsonKey(name: 'business_field')  BusinessField? businessField)?  $default,) {final _that = this;
switch (_that) {
case _CustomerShop() when $default != null:
return $default(_that.id,_that.name,_that.cityId,_that.city,_that.regionId,_that.region,_that.latitude,_that.longitude,_that.pageUrl,_that.businessFieldId,_that.businessField);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerShop extends CustomerShop {
  const _CustomerShop({required this.id, required this.name, @JsonKey(name: 'city_id') this.cityId, this.city, @JsonKey(name: 'region_id') this.regionId, this.region, this.latitude, this.longitude, @JsonKey(name: 'page_url') this.pageUrl, @JsonKey(name: 'business_field_id') this.businessFieldId, @JsonKey(name: 'business_field') this.businessField}): super._();
  factory _CustomerShop.fromJson(Map<String, dynamic> json) => _$CustomerShopFromJson(json);

@override final  int id;
@override final  String name;
/// المدينة — required by the API, so a shop that came from it has one. Nullable here all
/// the same: `city` is the *object*, and the server omits it when the relation was not
/// loaded or the city has since been deleted.
@override@JsonKey(name: 'city_id') final  int? cityId;
@override final  City? city;
/// المنطقة — genuinely optional. Most cities have no neighbourhoods, and a shop taken over
/// the phone often has none recorded.
@override@JsonKey(name: 'region_id') final  int? regionId;
@override final  Region? region;
/// Numbers, not strings: these go straight into a map SDK. Null for every shop recorded
/// since the form stopped asking for a pin — which is why nothing reads them today. The
/// field stays so the pin survives a round trip through this app untouched.
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey(name: 'page_url') final  String? pageUrl;
/// مجال العمل — what this shop sells. Null for the shops recorded before the list existed,
/// and for one entered in a hurry; «لم يُحدَّد» is a real answer here, not a missing one.
@override@JsonKey(name: 'business_field_id') final  int? businessFieldId;
/// The trade itself, so a screen renders its name without fetching the list to translate
/// one number. Sent whenever the shop is loaded with it.
@override@JsonKey(name: 'business_field') final  BusinessField? businessField;

/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerShopCopyWith<_CustomerShop> get copyWith => __$CustomerShopCopyWithImpl<_CustomerShop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerShopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerShop&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.city, city) || other.city == city)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.region, region) || other.region == region)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl)&&(identical(other.businessFieldId, businessFieldId) || other.businessFieldId == businessFieldId)&&(identical(other.businessField, businessField) || other.businessField == businessField));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,cityId,city,regionId,region,latitude,longitude,pageUrl,businessFieldId,businessField);

@override
String toString() {
  return 'CustomerShop(id: $id, name: $name, cityId: $cityId, city: $city, regionId: $regionId, region: $region, latitude: $latitude, longitude: $longitude, pageUrl: $pageUrl, businessFieldId: $businessFieldId, businessField: $businessField)';
}


}

/// @nodoc
abstract mixin class _$CustomerShopCopyWith<$Res> implements $CustomerShopCopyWith<$Res> {
  factory _$CustomerShopCopyWith(_CustomerShop value, $Res Function(_CustomerShop) _then) = __$CustomerShopCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'city_id') int? cityId, City? city,@JsonKey(name: 'region_id') int? regionId, Region? region, double? latitude, double? longitude,@JsonKey(name: 'page_url') String? pageUrl,@JsonKey(name: 'business_field_id') int? businessFieldId,@JsonKey(name: 'business_field') BusinessField? businessField
});


@override $CityCopyWith<$Res>? get city;@override $RegionCopyWith<$Res>? get region;@override $BusinessFieldCopyWith<$Res>? get businessField;

}
/// @nodoc
class __$CustomerShopCopyWithImpl<$Res>
    implements _$CustomerShopCopyWith<$Res> {
  __$CustomerShopCopyWithImpl(this._self, this._then);

  final _CustomerShop _self;
  final $Res Function(_CustomerShop) _then;

/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? cityId = freezed,Object? city = freezed,Object? regionId = freezed,Object? region = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? pageUrl = freezed,Object? businessFieldId = freezed,Object? businessField = freezed,}) {
  return _then(_CustomerShop(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as City?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Region?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,businessFieldId: freezed == businessFieldId ? _self.businessFieldId : businessFieldId // ignore: cast_nullable_to_non_nullable
as int?,businessField: freezed == businessField ? _self.businessField : businessField // ignore: cast_nullable_to_non_nullable
as BusinessField?,
  ));
}

/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CityCopyWith<$Res>? get city {
    if (_self.city == null) {
    return null;
  }

  return $CityCopyWith<$Res>(_self.city!, (value) {
    return _then(_self.copyWith(city: value));
  });
}/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegionCopyWith<$Res>? get region {
    if (_self.region == null) {
    return null;
  }

  return $RegionCopyWith<$Res>(_self.region!, (value) {
    return _then(_self.copyWith(region: value));
  });
}/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessFieldCopyWith<$Res>? get businessField {
    if (_self.businessField == null) {
    return null;
  }

  return $BusinessFieldCopyWith<$Res>(_self.businessField!, (value) {
    return _then(_self.copyWith(businessField: value));
  });
}
}

// dart format on
