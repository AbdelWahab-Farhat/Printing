// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomerAccount {

 int get id; String get name; String get phone;/// «A123» — what staff say on the phone, so the customer should be able to read it back to
/// them. Allocated by the server and never sent by this app.
 String? get code;/// Whether the shop is still selling to this account.
///
/// Defaulted to `true`: an account nobody stopped is an account in use. A deactivated one
/// is refused at sign-in with its own message, so this arriving `false` is a state the app
/// will rarely see.
@JsonKey(name: 'is_active') bool get isActive;/// The shop this account was opened with, when it has one.
///
/// **Null is ordinary, not a failure.** An account registered from the app has no shop until
/// staff add one, and `auth/me` sends `null` rather than omitting the key — so «حسابي» draws
/// a name with no line under it instead of treating the account as half-loaded.
///
/// Absent altogether from `register` and `login`: neither is a moment when «حسابي» is on
/// screen, and loading three relations to fill a card nobody is looking at is a query the
/// sign-in screen would pay for.
 CustomerShop? get shop;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of CustomerAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerAccountCopyWith<CustomerAccount> get copyWith => _$CustomerAccountCopyWithImpl<CustomerAccount>(this as CustomerAccount, _$identity);

  /// Serializes this CustomerAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.code, code) || other.code == code)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.shop, shop) || other.shop == shop)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,code,isActive,shop,createdAt);

@override
String toString() {
  return 'CustomerAccount(id: $id, name: $name, phone: $phone, code: $code, isActive: $isActive, shop: $shop, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CustomerAccountCopyWith<$Res>  {
  factory $CustomerAccountCopyWith(CustomerAccount value, $Res Function(CustomerAccount) _then) = _$CustomerAccountCopyWithImpl;
@useResult
$Res call({
 int id, String name, String phone, String? code,@JsonKey(name: 'is_active') bool isActive, CustomerShop? shop,@JsonKey(name: 'created_at') DateTime? createdAt
});


$CustomerShopCopyWith<$Res>? get shop;

}
/// @nodoc
class _$CustomerAccountCopyWithImpl<$Res>
    implements $CustomerAccountCopyWith<$Res> {
  _$CustomerAccountCopyWithImpl(this._self, this._then);

  final CustomerAccount _self;
  final $Res Function(CustomerAccount) _then;

/// Create a copy of CustomerAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phone = null,Object? code = freezed,Object? isActive = null,Object? shop = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,shop: freezed == shop ? _self.shop : shop // ignore: cast_nullable_to_non_nullable
as CustomerShop?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of CustomerAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerShopCopyWith<$Res>? get shop {
    if (_self.shop == null) {
    return null;
  }

  return $CustomerShopCopyWith<$Res>(_self.shop!, (value) {
    return _then(_self.copyWith(shop: value));
  });
}
}


/// Adds pattern-matching-related methods to [CustomerAccount].
extension CustomerAccountPatterns on CustomerAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerAccount value)  $default,){
final _that = this;
switch (_that) {
case _CustomerAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerAccount value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String phone,  String? code, @JsonKey(name: 'is_active')  bool isActive,  CustomerShop? shop, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerAccount() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.code,_that.isActive,_that.shop,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String phone,  String? code, @JsonKey(name: 'is_active')  bool isActive,  CustomerShop? shop, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _CustomerAccount():
return $default(_that.id,_that.name,_that.phone,_that.code,_that.isActive,_that.shop,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String phone,  String? code, @JsonKey(name: 'is_active')  bool isActive,  CustomerShop? shop, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CustomerAccount() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.code,_that.isActive,_that.shop,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerAccount implements CustomerAccount {
  const _CustomerAccount({required this.id, required this.name, required this.phone, this.code, @JsonKey(name: 'is_active') this.isActive = true, this.shop, @JsonKey(name: 'created_at') this.createdAt});
  factory _CustomerAccount.fromJson(Map<String, dynamic> json) => _$CustomerAccountFromJson(json);

@override final  int id;
@override final  String name;
@override final  String phone;
/// «A123» — what staff say on the phone, so the customer should be able to read it back to
/// them. Allocated by the server and never sent by this app.
@override final  String? code;
/// Whether the shop is still selling to this account.
///
/// Defaulted to `true`: an account nobody stopped is an account in use. A deactivated one
/// is refused at sign-in with its own message, so this arriving `false` is a state the app
/// will rarely see.
@override@JsonKey(name: 'is_active') final  bool isActive;
/// The shop this account was opened with, when it has one.
///
/// **Null is ordinary, not a failure.** An account registered from the app has no shop until
/// staff add one, and `auth/me` sends `null` rather than omitting the key — so «حسابي» draws
/// a name with no line under it instead of treating the account as half-loaded.
///
/// Absent altogether from `register` and `login`: neither is a moment when «حسابي» is on
/// screen, and loading three relations to fill a card nobody is looking at is a query the
/// sign-in screen would pay for.
@override final  CustomerShop? shop;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of CustomerAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerAccountCopyWith<_CustomerAccount> get copyWith => __$CustomerAccountCopyWithImpl<_CustomerAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.code, code) || other.code == code)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.shop, shop) || other.shop == shop)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,code,isActive,shop,createdAt);

@override
String toString() {
  return 'CustomerAccount(id: $id, name: $name, phone: $phone, code: $code, isActive: $isActive, shop: $shop, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CustomerAccountCopyWith<$Res> implements $CustomerAccountCopyWith<$Res> {
  factory _$CustomerAccountCopyWith(_CustomerAccount value, $Res Function(_CustomerAccount) _then) = __$CustomerAccountCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String phone, String? code,@JsonKey(name: 'is_active') bool isActive, CustomerShop? shop,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $CustomerShopCopyWith<$Res>? get shop;

}
/// @nodoc
class __$CustomerAccountCopyWithImpl<$Res>
    implements _$CustomerAccountCopyWith<$Res> {
  __$CustomerAccountCopyWithImpl(this._self, this._then);

  final _CustomerAccount _self;
  final $Res Function(_CustomerAccount) _then;

/// Create a copy of CustomerAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phone = null,Object? code = freezed,Object? isActive = null,Object? shop = freezed,Object? createdAt = freezed,}) {
  return _then(_CustomerAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,shop: freezed == shop ? _self.shop : shop // ignore: cast_nullable_to_non_nullable
as CustomerShop?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of CustomerAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerShopCopyWith<$Res>? get shop {
    if (_self.shop == null) {
    return null;
  }

  return $CustomerShopCopyWith<$Res>(_self.shop!, (value) {
    return _then(_self.copyWith(shop: value));
  });
}
}


/// @nodoc
mixin _$CustomerShop {

 String? get name;/// The city as the shop's record names it, not as an order snapshotted it.
@JsonKey(name: 'city_name') String? get cityName;/// «ملابس وأحذية» — the trade, which is a fact about the shop rather than the account.
@JsonKey(name: 'business_field') String? get businessField;
/// Create a copy of CustomerShop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerShopCopyWith<CustomerShop> get copyWith => _$CustomerShopCopyWithImpl<CustomerShop>(this as CustomerShop, _$identity);

  /// Serializes this CustomerShop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerShop&&(identical(other.name, name) || other.name == name)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.businessField, businessField) || other.businessField == businessField));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,cityName,businessField);

@override
String toString() {
  return 'CustomerShop(name: $name, cityName: $cityName, businessField: $businessField)';
}


}

/// @nodoc
abstract mixin class $CustomerShopCopyWith<$Res>  {
  factory $CustomerShopCopyWith(CustomerShop value, $Res Function(CustomerShop) _then) = _$CustomerShopCopyWithImpl;
@useResult
$Res call({
 String? name,@JsonKey(name: 'city_name') String? cityName,@JsonKey(name: 'business_field') String? businessField
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
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? cityName = freezed,Object? businessField = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,cityName: freezed == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String?,businessField: freezed == businessField ? _self.businessField : businessField // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name, @JsonKey(name: 'city_name')  String? cityName, @JsonKey(name: 'business_field')  String? businessField)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerShop() when $default != null:
return $default(_that.name,_that.cityName,_that.businessField);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name, @JsonKey(name: 'city_name')  String? cityName, @JsonKey(name: 'business_field')  String? businessField)  $default,) {final _that = this;
switch (_that) {
case _CustomerShop():
return $default(_that.name,_that.cityName,_that.businessField);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name, @JsonKey(name: 'city_name')  String? cityName, @JsonKey(name: 'business_field')  String? businessField)?  $default,) {final _that = this;
switch (_that) {
case _CustomerShop() when $default != null:
return $default(_that.name,_that.cityName,_that.businessField);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerShop implements CustomerShop {
  const _CustomerShop({this.name, @JsonKey(name: 'city_name') this.cityName, @JsonKey(name: 'business_field') this.businessField});
  factory _CustomerShop.fromJson(Map<String, dynamic> json) => _$CustomerShopFromJson(json);

@override final  String? name;
/// The city as the shop's record names it, not as an order snapshotted it.
@override@JsonKey(name: 'city_name') final  String? cityName;
/// «ملابس وأحذية» — the trade, which is a fact about the shop rather than the account.
@override@JsonKey(name: 'business_field') final  String? businessField;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerShop&&(identical(other.name, name) || other.name == name)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.businessField, businessField) || other.businessField == businessField));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,cityName,businessField);

@override
String toString() {
  return 'CustomerShop(name: $name, cityName: $cityName, businessField: $businessField)';
}


}

/// @nodoc
abstract mixin class _$CustomerShopCopyWith<$Res> implements $CustomerShopCopyWith<$Res> {
  factory _$CustomerShopCopyWith(_CustomerShop value, $Res Function(_CustomerShop) _then) = __$CustomerShopCopyWithImpl;
@override @useResult
$Res call({
 String? name,@JsonKey(name: 'city_name') String? cityName,@JsonKey(name: 'business_field') String? businessField
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
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? cityName = freezed,Object? businessField = freezed,}) {
  return _then(_CustomerShop(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,cityName: freezed == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String?,businessField: freezed == businessField ? _self.businessField : businessField // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AuthSession {

 CustomerAccount get customer; String get token;
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSessionCopyWith<AuthSession> get copyWith => _$AuthSessionCopyWithImpl<AuthSession>(this as AuthSession, _$identity);

  /// Serializes this AuthSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSession&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customer,token);

@override
String toString() {
  return 'AuthSession(customer: $customer, token: $token)';
}


}

/// @nodoc
abstract mixin class $AuthSessionCopyWith<$Res>  {
  factory $AuthSessionCopyWith(AuthSession value, $Res Function(AuthSession) _then) = _$AuthSessionCopyWithImpl;
@useResult
$Res call({
 CustomerAccount customer, String token
});


$CustomerAccountCopyWith<$Res> get customer;

}
/// @nodoc
class _$AuthSessionCopyWithImpl<$Res>
    implements $AuthSessionCopyWith<$Res> {
  _$AuthSessionCopyWithImpl(this._self, this._then);

  final AuthSession _self;
  final $Res Function(AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? customer = null,Object? token = null,}) {
  return _then(_self.copyWith(
customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as CustomerAccount,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerAccountCopyWith<$Res> get customer {
  
  return $CustomerAccountCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthSession].
extension AuthSessionPatterns on AuthSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthSession value)  $default,){
final _that = this;
switch (_that) {
case _AuthSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthSession value)?  $default,){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CustomerAccount customer,  String token)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.customer,_that.token);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CustomerAccount customer,  String token)  $default,) {final _that = this;
switch (_that) {
case _AuthSession():
return $default(_that.customer,_that.token);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CustomerAccount customer,  String token)?  $default,) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.customer,_that.token);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthSession implements AuthSession {
  const _AuthSession({required this.customer, required this.token});
  factory _AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);

@override final  CustomerAccount customer;
@override final  String token;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthSessionCopyWith<_AuthSession> get copyWith => __$AuthSessionCopyWithImpl<_AuthSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthSession&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customer,token);

@override
String toString() {
  return 'AuthSession(customer: $customer, token: $token)';
}


}

/// @nodoc
abstract mixin class _$AuthSessionCopyWith<$Res> implements $AuthSessionCopyWith<$Res> {
  factory _$AuthSessionCopyWith(_AuthSession value, $Res Function(_AuthSession) _then) = __$AuthSessionCopyWithImpl;
@override @useResult
$Res call({
 CustomerAccount customer, String token
});


@override $CustomerAccountCopyWith<$Res> get customer;

}
/// @nodoc
class __$AuthSessionCopyWithImpl<$Res>
    implements _$AuthSessionCopyWith<$Res> {
  __$AuthSessionCopyWithImpl(this._self, this._then);

  final _AuthSession _self;
  final $Res Function(_AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? customer = null,Object? token = null,}) {
  return _then(_AuthSession(
customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as CustomerAccount,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerAccountCopyWith<$Res> get customer {
  
  return $CustomerAccountCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}
}

// dart format on
