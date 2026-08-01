// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'city.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$City {

 int get id; String get name;/// Whether the customer *must* pick a region — not whether the city has any.
@JsonKey(name: 'is_region_required') bool get isRegionRequired;/// Money as a string, exactly as the API sends it ("15.00"). Never a `double`: a price is
/// added to an order total, and binary floating point does not add money correctly.
/// `null` means no rate has been agreed yet — which is not the same as free.
@JsonKey(name: 'delivery_price') String? get deliveryPrice;/// The شركة درب branch that serves this city.
@JsonKey(name: 'darb_branch') String? get darbBranch; double? get latitude; double? get longitude;/// Present on the list endpoint.
@JsonKey(name: 'regions_count') int? get regionsCount;/// Present when a single city was fetched.
 List<Region>? get regions;
/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CityCopyWith<City> get copyWith => _$CityCopyWithImpl<City>(this as City, _$identity);

  /// Serializes this City to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is City&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isRegionRequired, isRegionRequired) || other.isRegionRequired == isRegionRequired)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.darbBranch, darbBranch) || other.darbBranch == darbBranch)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.regionsCount, regionsCount) || other.regionsCount == regionsCount)&&const DeepCollectionEquality().equals(other.regions, regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isRegionRequired,deliveryPrice,darbBranch,latitude,longitude,regionsCount,const DeepCollectionEquality().hash(regions));

@override
String toString() {
  return 'City(id: $id, name: $name, isRegionRequired: $isRegionRequired, deliveryPrice: $deliveryPrice, darbBranch: $darbBranch, latitude: $latitude, longitude: $longitude, regionsCount: $regionsCount, regions: $regions)';
}


}

/// @nodoc
abstract mixin class $CityCopyWith<$Res>  {
  factory $CityCopyWith(City value, $Res Function(City) _then) = _$CityCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'is_region_required') bool isRegionRequired,@JsonKey(name: 'delivery_price') String? deliveryPrice,@JsonKey(name: 'darb_branch') String? darbBranch, double? latitude, double? longitude,@JsonKey(name: 'regions_count') int? regionsCount, List<Region>? regions
});




}
/// @nodoc
class _$CityCopyWithImpl<$Res>
    implements $CityCopyWith<$Res> {
  _$CityCopyWithImpl(this._self, this._then);

  final City _self;
  final $Res Function(City) _then;

/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isRegionRequired = null,Object? deliveryPrice = freezed,Object? darbBranch = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? regionsCount = freezed,Object? regions = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isRegionRequired: null == isRegionRequired ? _self.isRegionRequired : isRegionRequired // ignore: cast_nullable_to_non_nullable
as bool,deliveryPrice: freezed == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String?,darbBranch: freezed == darbBranch ? _self.darbBranch : darbBranch // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,regionsCount: freezed == regionsCount ? _self.regionsCount : regionsCount // ignore: cast_nullable_to_non_nullable
as int?,regions: freezed == regions ? _self.regions : regions // ignore: cast_nullable_to_non_nullable
as List<Region>?,
  ));
}

}


/// Adds pattern-matching-related methods to [City].
extension CityPatterns on City {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _City value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _City() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _City value)  $default,){
final _that = this;
switch (_that) {
case _City():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _City value)?  $default,){
final _that = this;
switch (_that) {
case _City() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'is_region_required')  bool isRegionRequired, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'darb_branch')  String? darbBranch,  double? latitude,  double? longitude, @JsonKey(name: 'regions_count')  int? regionsCount,  List<Region>? regions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _City() when $default != null:
return $default(_that.id,_that.name,_that.isRegionRequired,_that.deliveryPrice,_that.darbBranch,_that.latitude,_that.longitude,_that.regionsCount,_that.regions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'is_region_required')  bool isRegionRequired, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'darb_branch')  String? darbBranch,  double? latitude,  double? longitude, @JsonKey(name: 'regions_count')  int? regionsCount,  List<Region>? regions)  $default,) {final _that = this;
switch (_that) {
case _City():
return $default(_that.id,_that.name,_that.isRegionRequired,_that.deliveryPrice,_that.darbBranch,_that.latitude,_that.longitude,_that.regionsCount,_that.regions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'is_region_required')  bool isRegionRequired, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'darb_branch')  String? darbBranch,  double? latitude,  double? longitude, @JsonKey(name: 'regions_count')  int? regionsCount,  List<Region>? regions)?  $default,) {final _that = this;
switch (_that) {
case _City() when $default != null:
return $default(_that.id,_that.name,_that.isRegionRequired,_that.deliveryPrice,_that.darbBranch,_that.latitude,_that.longitude,_that.regionsCount,_that.regions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _City extends City {
  const _City({required this.id, required this.name, @JsonKey(name: 'is_region_required') required this.isRegionRequired, @JsonKey(name: 'delivery_price') this.deliveryPrice, @JsonKey(name: 'darb_branch') this.darbBranch, this.latitude, this.longitude, @JsonKey(name: 'regions_count') this.regionsCount, final  List<Region>? regions}): _regions = regions,super._();
  factory _City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);

@override final  int id;
@override final  String name;
/// Whether the customer *must* pick a region — not whether the city has any.
@override@JsonKey(name: 'is_region_required') final  bool isRegionRequired;
/// Money as a string, exactly as the API sends it ("15.00"). Never a `double`: a price is
/// added to an order total, and binary floating point does not add money correctly.
/// `null` means no rate has been agreed yet — which is not the same as free.
@override@JsonKey(name: 'delivery_price') final  String? deliveryPrice;
/// The شركة درب branch that serves this city.
@override@JsonKey(name: 'darb_branch') final  String? darbBranch;
@override final  double? latitude;
@override final  double? longitude;
/// Present on the list endpoint.
@override@JsonKey(name: 'regions_count') final  int? regionsCount;
/// Present when a single city was fetched.
 final  List<Region>? _regions;
/// Present when a single city was fetched.
@override List<Region>? get regions {
  final value = _regions;
  if (value == null) return null;
  if (_regions is EqualUnmodifiableListView) return _regions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CityCopyWith<_City> get copyWith => __$CityCopyWithImpl<_City>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _City&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isRegionRequired, isRegionRequired) || other.isRegionRequired == isRegionRequired)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.darbBranch, darbBranch) || other.darbBranch == darbBranch)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.regionsCount, regionsCount) || other.regionsCount == regionsCount)&&const DeepCollectionEquality().equals(other._regions, _regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isRegionRequired,deliveryPrice,darbBranch,latitude,longitude,regionsCount,const DeepCollectionEquality().hash(_regions));

@override
String toString() {
  return 'City(id: $id, name: $name, isRegionRequired: $isRegionRequired, deliveryPrice: $deliveryPrice, darbBranch: $darbBranch, latitude: $latitude, longitude: $longitude, regionsCount: $regionsCount, regions: $regions)';
}


}

/// @nodoc
abstract mixin class _$CityCopyWith<$Res> implements $CityCopyWith<$Res> {
  factory _$CityCopyWith(_City value, $Res Function(_City) _then) = __$CityCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'is_region_required') bool isRegionRequired,@JsonKey(name: 'delivery_price') String? deliveryPrice,@JsonKey(name: 'darb_branch') String? darbBranch, double? latitude, double? longitude,@JsonKey(name: 'regions_count') int? regionsCount, List<Region>? regions
});




}
/// @nodoc
class __$CityCopyWithImpl<$Res>
    implements _$CityCopyWith<$Res> {
  __$CityCopyWithImpl(this._self, this._then);

  final _City _self;
  final $Res Function(_City) _then;

/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isRegionRequired = null,Object? deliveryPrice = freezed,Object? darbBranch = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? regionsCount = freezed,Object? regions = freezed,}) {
  return _then(_City(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isRegionRequired: null == isRegionRequired ? _self.isRegionRequired : isRegionRequired // ignore: cast_nullable_to_non_nullable
as bool,deliveryPrice: freezed == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String?,darbBranch: freezed == darbBranch ? _self.darbBranch : darbBranch // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,regionsCount: freezed == regionsCount ? _self.regionsCount : regionsCount // ignore: cast_nullable_to_non_nullable
as int?,regions: freezed == regions ? _self._regions : regions // ignore: cast_nullable_to_non_nullable
as List<Region>?,
  ));
}


}


/// @nodoc
mixin _$Region {

 int get id;@JsonKey(name: 'city_id') int get cityId; String get name;/// شركة درب's zone code, e.g. `s18`. Theirs, so it is displayed and never generated.
 String? get code;@JsonKey(name: 'darb_branch') String? get darbBranch; double? get latitude; double? get longitude;
/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegionCopyWith<Region> get copyWith => _$RegionCopyWithImpl<Region>(this as Region, _$identity);

  /// Serializes this Region to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Region&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.darbBranch, darbBranch) || other.darbBranch == darbBranch)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cityId,name,code,darbBranch,latitude,longitude);

@override
String toString() {
  return 'Region(id: $id, cityId: $cityId, name: $name, code: $code, darbBranch: $darbBranch, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $RegionCopyWith<$Res>  {
  factory $RegionCopyWith(Region value, $Res Function(Region) _then) = _$RegionCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'city_id') int cityId, String name, String? code,@JsonKey(name: 'darb_branch') String? darbBranch, double? latitude, double? longitude
});




}
/// @nodoc
class _$RegionCopyWithImpl<$Res>
    implements $RegionCopyWith<$Res> {
  _$RegionCopyWithImpl(this._self, this._then);

  final Region _self;
  final $Res Function(Region) _then;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cityId = null,Object? name = null,Object? code = freezed,Object? darbBranch = freezed,Object? latitude = freezed,Object? longitude = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,darbBranch: freezed == darbBranch ? _self.darbBranch : darbBranch // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [Region].
extension RegionPatterns on Region {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Region value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Region() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Region value)  $default,){
final _that = this;
switch (_that) {
case _Region():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Region value)?  $default,){
final _that = this;
switch (_that) {
case _Region() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'city_id')  int cityId,  String name,  String? code, @JsonKey(name: 'darb_branch')  String? darbBranch,  double? latitude,  double? longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Region() when $default != null:
return $default(_that.id,_that.cityId,_that.name,_that.code,_that.darbBranch,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'city_id')  int cityId,  String name,  String? code, @JsonKey(name: 'darb_branch')  String? darbBranch,  double? latitude,  double? longitude)  $default,) {final _that = this;
switch (_that) {
case _Region():
return $default(_that.id,_that.cityId,_that.name,_that.code,_that.darbBranch,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'city_id')  int cityId,  String name,  String? code, @JsonKey(name: 'darb_branch')  String? darbBranch,  double? latitude,  double? longitude)?  $default,) {final _that = this;
switch (_that) {
case _Region() when $default != null:
return $default(_that.id,_that.cityId,_that.name,_that.code,_that.darbBranch,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Region extends Region {
  const _Region({required this.id, @JsonKey(name: 'city_id') required this.cityId, required this.name, this.code, @JsonKey(name: 'darb_branch') this.darbBranch, this.latitude, this.longitude}): super._();
  factory _Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);

@override final  int id;
@override@JsonKey(name: 'city_id') final  int cityId;
@override final  String name;
/// شركة درب's zone code, e.g. `s18`. Theirs, so it is displayed and never generated.
@override final  String? code;
@override@JsonKey(name: 'darb_branch') final  String? darbBranch;
@override final  double? latitude;
@override final  double? longitude;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegionCopyWith<_Region> get copyWith => __$RegionCopyWithImpl<_Region>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Region&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.darbBranch, darbBranch) || other.darbBranch == darbBranch)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cityId,name,code,darbBranch,latitude,longitude);

@override
String toString() {
  return 'Region(id: $id, cityId: $cityId, name: $name, code: $code, darbBranch: $darbBranch, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$RegionCopyWith<$Res> implements $RegionCopyWith<$Res> {
  factory _$RegionCopyWith(_Region value, $Res Function(_Region) _then) = __$RegionCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'city_id') int cityId, String name, String? code,@JsonKey(name: 'darb_branch') String? darbBranch, double? latitude, double? longitude
});




}
/// @nodoc
class __$RegionCopyWithImpl<$Res>
    implements _$RegionCopyWith<$Res> {
  __$RegionCopyWithImpl(this._self, this._then);

  final _Region _self;
  final $Res Function(_Region) _then;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cityId = null,Object? name = null,Object? code = freezed,Object? darbBranch = freezed,Object? latitude = freezed,Object? longitude = freezed,}) {
  return _then(_Region(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,darbBranch: freezed == darbBranch ? _self.darbBranch : darbBranch // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
