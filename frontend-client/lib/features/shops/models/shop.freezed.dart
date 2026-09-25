// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Shop {

 int get id; String get name;@JsonKey(name: 'city_id') int get cityId;/// `null` حين تُخرَج المدينة من الخريطة بعد تسجيل المتجر — المُعرِّف يبقى، والاسم لا يُخترع.
@JsonKey(name: 'city_name') String? get cityName;@JsonKey(name: 'region_id') int? get regionId;@JsonKey(name: 'region_name') String? get regionName;/// مجال العمل، أو `null` لمتجرٍ سُجّل بلا مجال — وذلك جوابٌ حقيقي لا نقص.
@JsonKey(name: 'business_field_id') int? get businessFieldId;@JsonKey(name: 'business_field_name') String? get businessFieldName;@JsonKey(name: 'page_url') String? get pageUrl;
/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopCopyWith<Shop> get copyWith => _$ShopCopyWithImpl<Shop>(this as Shop, _$identity);

  /// Serializes this Shop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shop&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.businessFieldId, businessFieldId) || other.businessFieldId == businessFieldId)&&(identical(other.businessFieldName, businessFieldName) || other.businessFieldName == businessFieldName)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,cityId,cityName,regionId,regionName,businessFieldId,businessFieldName,pageUrl);

@override
String toString() {
  return 'Shop(id: $id, name: $name, cityId: $cityId, cityName: $cityName, regionId: $regionId, regionName: $regionName, businessFieldId: $businessFieldId, businessFieldName: $businessFieldName, pageUrl: $pageUrl)';
}


}

/// @nodoc
abstract mixin class $ShopCopyWith<$Res>  {
  factory $ShopCopyWith(Shop value, $Res Function(Shop) _then) = _$ShopCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'city_id') int cityId,@JsonKey(name: 'city_name') String? cityName,@JsonKey(name: 'region_id') int? regionId,@JsonKey(name: 'region_name') String? regionName,@JsonKey(name: 'business_field_id') int? businessFieldId,@JsonKey(name: 'business_field_name') String? businessFieldName,@JsonKey(name: 'page_url') String? pageUrl
});




}
/// @nodoc
class _$ShopCopyWithImpl<$Res>
    implements $ShopCopyWith<$Res> {
  _$ShopCopyWithImpl(this._self, this._then);

  final Shop _self;
  final $Res Function(Shop) _then;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? cityId = null,Object? cityName = freezed,Object? regionId = freezed,Object? regionName = freezed,Object? businessFieldId = freezed,Object? businessFieldName = freezed,Object? pageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,cityName: freezed == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,regionName: freezed == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String?,businessFieldId: freezed == businessFieldId ? _self.businessFieldId : businessFieldId // ignore: cast_nullable_to_non_nullable
as int?,businessFieldName: freezed == businessFieldName ? _self.businessFieldName : businessFieldName // ignore: cast_nullable_to_non_nullable
as String?,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Shop].
extension ShopPatterns on Shop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shop value)  $default,){
final _that = this;
switch (_that) {
case _Shop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shop value)?  $default,){
final _that = this;
switch (_that) {
case _Shop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'city_name')  String? cityName, @JsonKey(name: 'region_id')  int? regionId, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'business_field_id')  int? businessFieldId, @JsonKey(name: 'business_field_name')  String? businessFieldName, @JsonKey(name: 'page_url')  String? pageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that.id,_that.name,_that.cityId,_that.cityName,_that.regionId,_that.regionName,_that.businessFieldId,_that.businessFieldName,_that.pageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'city_name')  String? cityName, @JsonKey(name: 'region_id')  int? regionId, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'business_field_id')  int? businessFieldId, @JsonKey(name: 'business_field_name')  String? businessFieldName, @JsonKey(name: 'page_url')  String? pageUrl)  $default,) {final _that = this;
switch (_that) {
case _Shop():
return $default(_that.id,_that.name,_that.cityId,_that.cityName,_that.regionId,_that.regionName,_that.businessFieldId,_that.businessFieldName,_that.pageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'city_name')  String? cityName, @JsonKey(name: 'region_id')  int? regionId, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'business_field_id')  int? businessFieldId, @JsonKey(name: 'business_field_name')  String? businessFieldName, @JsonKey(name: 'page_url')  String? pageUrl)?  $default,) {final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that.id,_that.name,_that.cityId,_that.cityName,_that.regionId,_that.regionName,_that.businessFieldId,_that.businessFieldName,_that.pageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shop extends Shop {
  const _Shop({required this.id, required this.name, @JsonKey(name: 'city_id') required this.cityId, @JsonKey(name: 'city_name') this.cityName, @JsonKey(name: 'region_id') this.regionId, @JsonKey(name: 'region_name') this.regionName, @JsonKey(name: 'business_field_id') this.businessFieldId, @JsonKey(name: 'business_field_name') this.businessFieldName, @JsonKey(name: 'page_url') this.pageUrl}): super._();
  factory _Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'city_id') final  int cityId;
/// `null` حين تُخرَج المدينة من الخريطة بعد تسجيل المتجر — المُعرِّف يبقى، والاسم لا يُخترع.
@override@JsonKey(name: 'city_name') final  String? cityName;
@override@JsonKey(name: 'region_id') final  int? regionId;
@override@JsonKey(name: 'region_name') final  String? regionName;
/// مجال العمل، أو `null` لمتجرٍ سُجّل بلا مجال — وذلك جوابٌ حقيقي لا نقص.
@override@JsonKey(name: 'business_field_id') final  int? businessFieldId;
@override@JsonKey(name: 'business_field_name') final  String? businessFieldName;
@override@JsonKey(name: 'page_url') final  String? pageUrl;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopCopyWith<_Shop> get copyWith => __$ShopCopyWithImpl<_Shop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shop&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.businessFieldId, businessFieldId) || other.businessFieldId == businessFieldId)&&(identical(other.businessFieldName, businessFieldName) || other.businessFieldName == businessFieldName)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,cityId,cityName,regionId,regionName,businessFieldId,businessFieldName,pageUrl);

@override
String toString() {
  return 'Shop(id: $id, name: $name, cityId: $cityId, cityName: $cityName, regionId: $regionId, regionName: $regionName, businessFieldId: $businessFieldId, businessFieldName: $businessFieldName, pageUrl: $pageUrl)';
}


}

/// @nodoc
abstract mixin class _$ShopCopyWith<$Res> implements $ShopCopyWith<$Res> {
  factory _$ShopCopyWith(_Shop value, $Res Function(_Shop) _then) = __$ShopCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'city_id') int cityId,@JsonKey(name: 'city_name') String? cityName,@JsonKey(name: 'region_id') int? regionId,@JsonKey(name: 'region_name') String? regionName,@JsonKey(name: 'business_field_id') int? businessFieldId,@JsonKey(name: 'business_field_name') String? businessFieldName,@JsonKey(name: 'page_url') String? pageUrl
});




}
/// @nodoc
class __$ShopCopyWithImpl<$Res>
    implements _$ShopCopyWith<$Res> {
  __$ShopCopyWithImpl(this._self, this._then);

  final _Shop _self;
  final $Res Function(_Shop) _then;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? cityId = null,Object? cityName = freezed,Object? regionId = freezed,Object? regionName = freezed,Object? businessFieldId = freezed,Object? businessFieldName = freezed,Object? pageUrl = freezed,}) {
  return _then(_Shop(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,cityName: freezed == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,regionName: freezed == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String?,businessFieldId: freezed == businessFieldId ? _self.businessFieldId : businessFieldId // ignore: cast_nullable_to_non_nullable
as int?,businessFieldName: freezed == businessFieldName ? _self.businessFieldName : businessFieldName // ignore: cast_nullable_to_non_nullable
as String?,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BusinessField {

 int get id; String get name;
/// Create a copy of BusinessField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessFieldCopyWith<BusinessField> get copyWith => _$BusinessFieldCopyWithImpl<BusinessField>(this as BusinessField, _$identity);

  /// Serializes this BusinessField to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessField&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'BusinessField(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $BusinessFieldCopyWith<$Res>  {
  factory $BusinessFieldCopyWith(BusinessField value, $Res Function(BusinessField) _then) = _$BusinessFieldCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$BusinessFieldCopyWithImpl<$Res>
    implements $BusinessFieldCopyWith<$Res> {
  _$BusinessFieldCopyWithImpl(this._self, this._then);

  final BusinessField _self;
  final $Res Function(BusinessField) _then;

/// Create a copy of BusinessField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessField].
extension BusinessFieldPatterns on BusinessField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessField value)  $default,){
final _that = this;
switch (_that) {
case _BusinessField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessField value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessField() when $default != null:
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
case _BusinessField() when $default != null:
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
case _BusinessField():
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
case _BusinessField() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessField implements BusinessField {
  const _BusinessField({required this.id, required this.name});
  factory _BusinessField.fromJson(Map<String, dynamic> json) => _$BusinessFieldFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of BusinessField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessFieldCopyWith<_BusinessField> get copyWith => __$BusinessFieldCopyWithImpl<_BusinessField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessField&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'BusinessField(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$BusinessFieldCopyWith<$Res> implements $BusinessFieldCopyWith<$Res> {
  factory _$BusinessFieldCopyWith(_BusinessField value, $Res Function(_BusinessField) _then) = __$BusinessFieldCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$BusinessFieldCopyWithImpl<$Res>
    implements _$BusinessFieldCopyWith<$Res> {
  __$BusinessFieldCopyWithImpl(this._self, this._then);

  final _BusinessField _self;
  final $Res Function(_BusinessField) _then;

/// Create a copy of BusinessField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_BusinessField(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
