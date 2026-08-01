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
 List<CustomerShop>? get shops;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerCopyWith<Customer> get copyWith => _$CustomerCopyWithImpl<Customer>(this as Customer, _$identity);

  /// Serializes this Customer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other.shops, shops)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone,isActive,const DeepCollectionEquality().hash(shops),createdAt,updatedAt);

@override
String toString() {
  return 'Customer(id: $id, code: $code, name: $name, phone: $phone, isActive: $isActive, shops: $shops, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CustomerCopyWith<$Res>  {
  factory $CustomerCopyWith(Customer value, $Res Function(Customer) _then) = _$CustomerCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name, String phone,@JsonKey(name: 'is_active') bool isActive, List<CustomerShop>? shops,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? phone = null,Object? isActive = null,Object? shops = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,shops: freezed == shops ? _self.shops : shops // ignore: cast_nullable_to_non_nullable
as List<CustomerShop>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String phone, @JsonKey(name: 'is_active')  bool isActive,  List<CustomerShop>? shops, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.phone,_that.isActive,_that.shops,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String phone, @JsonKey(name: 'is_active')  bool isActive,  List<CustomerShop>? shops, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Customer():
return $default(_that.id,_that.code,_that.name,_that.phone,_that.isActive,_that.shops,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name,  String phone, @JsonKey(name: 'is_active')  bool isActive,  List<CustomerShop>? shops, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.phone,_that.isActive,_that.shops,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Customer extends Customer {
  const _Customer({required this.id, required this.code, required this.name, required this.phone, @JsonKey(name: 'is_active') required this.isActive, final  List<CustomerShop>? shops, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _shops = shops,super._();
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other._shops, _shops)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone,isActive,const DeepCollectionEquality().hash(_shops),createdAt,updatedAt);

@override
String toString() {
  return 'Customer(id: $id, code: $code, name: $name, phone: $phone, isActive: $isActive, shops: $shops, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CustomerCopyWith<$Res> implements $CustomerCopyWith<$Res> {
  factory _$CustomerCopyWith(_Customer value, $Res Function(_Customer) _then) = __$CustomerCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name, String phone,@JsonKey(name: 'is_active') bool isActive, List<CustomerShop>? shops,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? phone = null,Object? isActive = null,Object? shops = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Customer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,shops: freezed == shops ? _self._shops : shops // ignore: cast_nullable_to_non_nullable
as List<CustomerShop>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CustomerShop {

 int get id; String get name;/// Numbers, not strings: these go straight into a map SDK. Null only for shops recorded
/// before coordinates existed — a new one cannot be created without them.
 double? get latitude; double? get longitude;@JsonKey(name: 'page_url') String? get pageUrl;
/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerShopCopyWith<CustomerShop> get copyWith => _$CustomerShopCopyWithImpl<CustomerShop>(this as CustomerShop, _$identity);

  /// Serializes this CustomerShop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerShop&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,latitude,longitude,pageUrl);

@override
String toString() {
  return 'CustomerShop(id: $id, name: $name, latitude: $latitude, longitude: $longitude, pageUrl: $pageUrl)';
}


}

/// @nodoc
abstract mixin class $CustomerShopCopyWith<$Res>  {
  factory $CustomerShopCopyWith(CustomerShop value, $Res Function(CustomerShop) _then) = _$CustomerShopCopyWithImpl;
@useResult
$Res call({
 int id, String name, double? latitude, double? longitude,@JsonKey(name: 'page_url') String? pageUrl
});




}
/// @nodoc
class _$CustomerShopCopyWithImpl<$Res>
    implements $CustomerShopCopyWith<$Res> {
  _$CustomerShopCopyWithImpl(this._self, this._then);

  final CustomerShop _self;
  final $Res Function(CustomerShop) _then;

/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? latitude = freezed,Object? longitude = freezed,Object? pageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  double? latitude,  double? longitude, @JsonKey(name: 'page_url')  String? pageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerShop() when $default != null:
return $default(_that.id,_that.name,_that.latitude,_that.longitude,_that.pageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  double? latitude,  double? longitude, @JsonKey(name: 'page_url')  String? pageUrl)  $default,) {final _that = this;
switch (_that) {
case _CustomerShop():
return $default(_that.id,_that.name,_that.latitude,_that.longitude,_that.pageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  double? latitude,  double? longitude, @JsonKey(name: 'page_url')  String? pageUrl)?  $default,) {final _that = this;
switch (_that) {
case _CustomerShop() when $default != null:
return $default(_that.id,_that.name,_that.latitude,_that.longitude,_that.pageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerShop extends CustomerShop {
  const _CustomerShop({required this.id, required this.name, this.latitude, this.longitude, @JsonKey(name: 'page_url') this.pageUrl}): super._();
  factory _CustomerShop.fromJson(Map<String, dynamic> json) => _$CustomerShopFromJson(json);

@override final  int id;
@override final  String name;
/// Numbers, not strings: these go straight into a map SDK. Null only for shops recorded
/// before coordinates existed — a new one cannot be created without them.
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey(name: 'page_url') final  String? pageUrl;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerShop&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,latitude,longitude,pageUrl);

@override
String toString() {
  return 'CustomerShop(id: $id, name: $name, latitude: $latitude, longitude: $longitude, pageUrl: $pageUrl)';
}


}

/// @nodoc
abstract mixin class _$CustomerShopCopyWith<$Res> implements $CustomerShopCopyWith<$Res> {
  factory _$CustomerShopCopyWith(_CustomerShop value, $Res Function(_CustomerShop) _then) = __$CustomerShopCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, double? latitude, double? longitude,@JsonKey(name: 'page_url') String? pageUrl
});




}
/// @nodoc
class __$CustomerShopCopyWithImpl<$Res>
    implements _$CustomerShopCopyWith<$Res> {
  __$CustomerShopCopyWithImpl(this._self, this._then);

  final _CustomerShop _self;
  final $Res Function(_CustomerShop) _then;

/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? latitude = freezed,Object? longitude = freezed,Object? pageUrl = freezed,}) {
  return _then(_CustomerShop(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
