// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_customer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewCustomer {

 String get name; String get phone;/// The places this customer sells from.
///
/// Omitted from the body entirely when empty rather than sent as `[]`: to this API an empty
/// array is a *statement* ("this customer has no shops"), and on the update endpoint the
/// same key means "delete the ones they had". Saying nothing is the honest thing for a form
/// where the user simply did not add any.
@JsonKey(includeIfNull: false) List<NewCustomerShop>? get shops;
/// Create a copy of NewCustomer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewCustomerCopyWith<NewCustomer> get copyWith => _$NewCustomerCopyWithImpl<NewCustomer>(this as NewCustomer, _$identity);

  /// Serializes this NewCustomer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewCustomer&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&const DeepCollectionEquality().equals(other.shops, shops));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone,const DeepCollectionEquality().hash(shops));

@override
String toString() {
  return 'NewCustomer(name: $name, phone: $phone, shops: $shops)';
}


}

/// @nodoc
abstract mixin class $NewCustomerCopyWith<$Res>  {
  factory $NewCustomerCopyWith(NewCustomer value, $Res Function(NewCustomer) _then) = _$NewCustomerCopyWithImpl;
@useResult
$Res call({
 String name, String phone,@JsonKey(includeIfNull: false) List<NewCustomerShop>? shops
});




}
/// @nodoc
class _$NewCustomerCopyWithImpl<$Res>
    implements $NewCustomerCopyWith<$Res> {
  _$NewCustomerCopyWithImpl(this._self, this._then);

  final NewCustomer _self;
  final $Res Function(NewCustomer) _then;

/// Create a copy of NewCustomer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = null,Object? shops = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,shops: freezed == shops ? _self.shops : shops // ignore: cast_nullable_to_non_nullable
as List<NewCustomerShop>?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewCustomer].
extension NewCustomerPatterns on NewCustomer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewCustomer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewCustomer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewCustomer value)  $default,){
final _that = this;
switch (_that) {
case _NewCustomer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewCustomer value)?  $default,){
final _that = this;
switch (_that) {
case _NewCustomer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phone, @JsonKey(includeIfNull: false)  List<NewCustomerShop>? shops)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewCustomer() when $default != null:
return $default(_that.name,_that.phone,_that.shops);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phone, @JsonKey(includeIfNull: false)  List<NewCustomerShop>? shops)  $default,) {final _that = this;
switch (_that) {
case _NewCustomer():
return $default(_that.name,_that.phone,_that.shops);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phone, @JsonKey(includeIfNull: false)  List<NewCustomerShop>? shops)?  $default,) {final _that = this;
switch (_that) {
case _NewCustomer() when $default != null:
return $default(_that.name,_that.phone,_that.shops);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createFactory: false)

class _NewCustomer implements NewCustomer {
  const _NewCustomer({required this.name, required this.phone, @JsonKey(includeIfNull: false) final  List<NewCustomerShop>? shops}): _shops = shops;
  

@override final  String name;
@override final  String phone;
/// The places this customer sells from.
///
/// Omitted from the body entirely when empty rather than sent as `[]`: to this API an empty
/// array is a *statement* ("this customer has no shops"), and on the update endpoint the
/// same key means "delete the ones they had". Saying nothing is the honest thing for a form
/// where the user simply did not add any.
 final  List<NewCustomerShop>? _shops;
/// The places this customer sells from.
///
/// Omitted from the body entirely when empty rather than sent as `[]`: to this API an empty
/// array is a *statement* ("this customer has no shops"), and on the update endpoint the
/// same key means "delete the ones they had". Saying nothing is the honest thing for a form
/// where the user simply did not add any.
@override@JsonKey(includeIfNull: false) List<NewCustomerShop>? get shops {
  final value = _shops;
  if (value == null) return null;
  if (_shops is EqualUnmodifiableListView) return _shops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of NewCustomer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewCustomerCopyWith<_NewCustomer> get copyWith => __$NewCustomerCopyWithImpl<_NewCustomer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewCustomerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewCustomer&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&const DeepCollectionEquality().equals(other._shops, _shops));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone,const DeepCollectionEquality().hash(_shops));

@override
String toString() {
  return 'NewCustomer(name: $name, phone: $phone, shops: $shops)';
}


}

/// @nodoc
abstract mixin class _$NewCustomerCopyWith<$Res> implements $NewCustomerCopyWith<$Res> {
  factory _$NewCustomerCopyWith(_NewCustomer value, $Res Function(_NewCustomer) _then) = __$NewCustomerCopyWithImpl;
@override @useResult
$Res call({
 String name, String phone,@JsonKey(includeIfNull: false) List<NewCustomerShop>? shops
});




}
/// @nodoc
class __$NewCustomerCopyWithImpl<$Res>
    implements _$NewCustomerCopyWith<$Res> {
  __$NewCustomerCopyWithImpl(this._self, this._then);

  final _NewCustomer _self;
  final $Res Function(_NewCustomer) _then;

/// Create a copy of NewCustomer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = null,Object? shops = freezed,}) {
  return _then(_NewCustomer(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,shops: freezed == shops ? _self._shops : shops // ignore: cast_nullable_to_non_nullable
as List<NewCustomerShop>?,
  ));
}


}

/// @nodoc
mixin _$NewCustomerShop {

 String get name;/// Real numbers, not the text that was typed. `'٣٢٫٨'` from an Arabic keyboard is turned
/// into `32.8` in [CreateCustomer] — the one place in this feature that converts anything —
/// so the JSON carries `32.8` and not a string the API would have to coerce.
 double get latitude; double get longitude;/// A Facebook page, usually. Absent rather than null when the user left it blank: the API's
/// rule is `nullable|url`, and an empty string is neither.
@JsonKey(name: 'page_url', includeIfNull: false) String? get pageUrl;
/// Create a copy of NewCustomerShop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewCustomerShopCopyWith<NewCustomerShop> get copyWith => _$NewCustomerShopCopyWithImpl<NewCustomerShop>(this as NewCustomerShop, _$identity);

  /// Serializes this NewCustomerShop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewCustomerShop&&(identical(other.name, name) || other.name == name)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,latitude,longitude,pageUrl);

@override
String toString() {
  return 'NewCustomerShop(name: $name, latitude: $latitude, longitude: $longitude, pageUrl: $pageUrl)';
}


}

/// @nodoc
abstract mixin class $NewCustomerShopCopyWith<$Res>  {
  factory $NewCustomerShopCopyWith(NewCustomerShop value, $Res Function(NewCustomerShop) _then) = _$NewCustomerShopCopyWithImpl;
@useResult
$Res call({
 String name, double latitude, double longitude,@JsonKey(name: 'page_url', includeIfNull: false) String? pageUrl
});




}
/// @nodoc
class _$NewCustomerShopCopyWithImpl<$Res>
    implements $NewCustomerShopCopyWith<$Res> {
  _$NewCustomerShopCopyWithImpl(this._self, this._then);

  final NewCustomerShop _self;
  final $Res Function(NewCustomerShop) _then;

/// Create a copy of NewCustomerShop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? latitude = null,Object? longitude = null,Object? pageUrl = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewCustomerShop].
extension NewCustomerShopPatterns on NewCustomerShop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewCustomerShop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewCustomerShop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewCustomerShop value)  $default,){
final _that = this;
switch (_that) {
case _NewCustomerShop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewCustomerShop value)?  $default,){
final _that = this;
switch (_that) {
case _NewCustomerShop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double latitude,  double longitude, @JsonKey(name: 'page_url', includeIfNull: false)  String? pageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewCustomerShop() when $default != null:
return $default(_that.name,_that.latitude,_that.longitude,_that.pageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double latitude,  double longitude, @JsonKey(name: 'page_url', includeIfNull: false)  String? pageUrl)  $default,) {final _that = this;
switch (_that) {
case _NewCustomerShop():
return $default(_that.name,_that.latitude,_that.longitude,_that.pageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double latitude,  double longitude, @JsonKey(name: 'page_url', includeIfNull: false)  String? pageUrl)?  $default,) {final _that = this;
switch (_that) {
case _NewCustomerShop() when $default != null:
return $default(_that.name,_that.latitude,_that.longitude,_that.pageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createFactory: false)

class _NewCustomerShop implements NewCustomerShop {
  const _NewCustomerShop({required this.name, required this.latitude, required this.longitude, @JsonKey(name: 'page_url', includeIfNull: false) this.pageUrl});
  

@override final  String name;
/// Real numbers, not the text that was typed. `'٣٢٫٨'` from an Arabic keyboard is turned
/// into `32.8` in [CreateCustomer] — the one place in this feature that converts anything —
/// so the JSON carries `32.8` and not a string the API would have to coerce.
@override final  double latitude;
@override final  double longitude;
/// A Facebook page, usually. Absent rather than null when the user left it blank: the API's
/// rule is `nullable|url`, and an empty string is neither.
@override@JsonKey(name: 'page_url', includeIfNull: false) final  String? pageUrl;

/// Create a copy of NewCustomerShop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewCustomerShopCopyWith<_NewCustomerShop> get copyWith => __$NewCustomerShopCopyWithImpl<_NewCustomerShop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewCustomerShopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewCustomerShop&&(identical(other.name, name) || other.name == name)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,latitude,longitude,pageUrl);

@override
String toString() {
  return 'NewCustomerShop(name: $name, latitude: $latitude, longitude: $longitude, pageUrl: $pageUrl)';
}


}

/// @nodoc
abstract mixin class _$NewCustomerShopCopyWith<$Res> implements $NewCustomerShopCopyWith<$Res> {
  factory _$NewCustomerShopCopyWith(_NewCustomerShop value, $Res Function(_NewCustomerShop) _then) = __$NewCustomerShopCopyWithImpl;
@override @useResult
$Res call({
 String name, double latitude, double longitude,@JsonKey(name: 'page_url', includeIfNull: false) String? pageUrl
});




}
/// @nodoc
class __$NewCustomerShopCopyWithImpl<$Res>
    implements _$NewCustomerShopCopyWith<$Res> {
  __$NewCustomerShopCopyWithImpl(this._self, this._then);

  final _NewCustomerShop _self;
  final $Res Function(_NewCustomerShop) _then;

/// Create a copy of NewCustomerShop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? latitude = null,Object? longitude = null,Object? pageUrl = freezed,}) {
  return _then(_NewCustomerShop(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
