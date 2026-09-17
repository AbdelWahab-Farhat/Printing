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
mixin _$Region {

 int get id;@JsonKey(name: 'city_id') int get cityId; String get name;
/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegionCopyWith<Region> get copyWith => _$RegionCopyWithImpl<Region>(this as Region, _$identity);

  /// Serializes this Region to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Region&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cityId,name);

@override
String toString() {
  return 'Region(id: $id, cityId: $cityId, name: $name)';
}


}

/// @nodoc
abstract mixin class $RegionCopyWith<$Res>  {
  factory $RegionCopyWith(Region value, $Res Function(Region) _then) = _$RegionCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'city_id') int cityId, String name
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cityId = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'city_id')  int cityId,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Region() when $default != null:
return $default(_that.id,_that.cityId,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'city_id')  int cityId,  String name)  $default,) {final _that = this;
switch (_that) {
case _Region():
return $default(_that.id,_that.cityId,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'city_id')  int cityId,  String name)?  $default,) {final _that = this;
switch (_that) {
case _Region() when $default != null:
return $default(_that.id,_that.cityId,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Region implements Region {
  const _Region({required this.id, @JsonKey(name: 'city_id') required this.cityId, required this.name});
  factory _Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);

@override final  int id;
@override@JsonKey(name: 'city_id') final  int cityId;
@override final  String name;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Region&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cityId,name);

@override
String toString() {
  return 'Region(id: $id, cityId: $cityId, name: $name)';
}


}

/// @nodoc
abstract mixin class _$RegionCopyWith<$Res> implements $RegionCopyWith<$Res> {
  factory _$RegionCopyWith(_Region value, $Res Function(_Region) _then) = __$RegionCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'city_id') int cityId, String name
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cityId = null,Object? name = null,}) {
  return _then(_Region(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$City {

 int get id; String get name;/// The value for logic, and the Arabic beside it. The label travels with the value so this
/// app keeps no translation table it would then have to keep in step with the business.
@JsonKey(name: 'fulfilment_type') String? get fulfilmentType;@JsonKey(name: 'fulfilment_type_label') String? get fulfilmentTypeLabel;/// **The boolean the order screen branches on**, decided on the server — so the app never
/// has to know which enum case means «they collect it».
@JsonKey(name: 'is_office_pickup') bool get isOfficePickup;/// Whether the picker may let the customer past without choosing a neighbourhood.
@JsonKey(name: 'is_region_required') bool get isRegionRequired;/// A decimal string, like every amount in this app. Null means no rate agreed.
@JsonKey(name: 'delivery_price') String? get deliveryPrice; List<Region> get regions;
/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CityCopyWith<City> get copyWith => _$CityCopyWithImpl<City>(this as City, _$identity);

  /// Serializes this City to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is City&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fulfilmentType, fulfilmentType) || other.fulfilmentType == fulfilmentType)&&(identical(other.fulfilmentTypeLabel, fulfilmentTypeLabel) || other.fulfilmentTypeLabel == fulfilmentTypeLabel)&&(identical(other.isOfficePickup, isOfficePickup) || other.isOfficePickup == isOfficePickup)&&(identical(other.isRegionRequired, isRegionRequired) || other.isRegionRequired == isRegionRequired)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&const DeepCollectionEquality().equals(other.regions, regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fulfilmentType,fulfilmentTypeLabel,isOfficePickup,isRegionRequired,deliveryPrice,const DeepCollectionEquality().hash(regions));

@override
String toString() {
  return 'City(id: $id, name: $name, fulfilmentType: $fulfilmentType, fulfilmentTypeLabel: $fulfilmentTypeLabel, isOfficePickup: $isOfficePickup, isRegionRequired: $isRegionRequired, deliveryPrice: $deliveryPrice, regions: $regions)';
}


}

/// @nodoc
abstract mixin class $CityCopyWith<$Res>  {
  factory $CityCopyWith(City value, $Res Function(City) _then) = _$CityCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'fulfilment_type') String? fulfilmentType,@JsonKey(name: 'fulfilment_type_label') String? fulfilmentTypeLabel,@JsonKey(name: 'is_office_pickup') bool isOfficePickup,@JsonKey(name: 'is_region_required') bool isRegionRequired,@JsonKey(name: 'delivery_price') String? deliveryPrice, List<Region> regions
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? fulfilmentType = freezed,Object? fulfilmentTypeLabel = freezed,Object? isOfficePickup = null,Object? isRegionRequired = null,Object? deliveryPrice = freezed,Object? regions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fulfilmentType: freezed == fulfilmentType ? _self.fulfilmentType : fulfilmentType // ignore: cast_nullable_to_non_nullable
as String?,fulfilmentTypeLabel: freezed == fulfilmentTypeLabel ? _self.fulfilmentTypeLabel : fulfilmentTypeLabel // ignore: cast_nullable_to_non_nullable
as String?,isOfficePickup: null == isOfficePickup ? _self.isOfficePickup : isOfficePickup // ignore: cast_nullable_to_non_nullable
as bool,isRegionRequired: null == isRegionRequired ? _self.isRegionRequired : isRegionRequired // ignore: cast_nullable_to_non_nullable
as bool,deliveryPrice: freezed == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String?,regions: null == regions ? _self.regions : regions // ignore: cast_nullable_to_non_nullable
as List<Region>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'fulfilment_type')  String? fulfilmentType, @JsonKey(name: 'fulfilment_type_label')  String? fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup')  bool isOfficePickup, @JsonKey(name: 'is_region_required')  bool isRegionRequired, @JsonKey(name: 'delivery_price')  String? deliveryPrice,  List<Region> regions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _City() when $default != null:
return $default(_that.id,_that.name,_that.fulfilmentType,_that.fulfilmentTypeLabel,_that.isOfficePickup,_that.isRegionRequired,_that.deliveryPrice,_that.regions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'fulfilment_type')  String? fulfilmentType, @JsonKey(name: 'fulfilment_type_label')  String? fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup')  bool isOfficePickup, @JsonKey(name: 'is_region_required')  bool isRegionRequired, @JsonKey(name: 'delivery_price')  String? deliveryPrice,  List<Region> regions)  $default,) {final _that = this;
switch (_that) {
case _City():
return $default(_that.id,_that.name,_that.fulfilmentType,_that.fulfilmentTypeLabel,_that.isOfficePickup,_that.isRegionRequired,_that.deliveryPrice,_that.regions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'fulfilment_type')  String? fulfilmentType, @JsonKey(name: 'fulfilment_type_label')  String? fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup')  bool isOfficePickup, @JsonKey(name: 'is_region_required')  bool isRegionRequired, @JsonKey(name: 'delivery_price')  String? deliveryPrice,  List<Region> regions)?  $default,) {final _that = this;
switch (_that) {
case _City() when $default != null:
return $default(_that.id,_that.name,_that.fulfilmentType,_that.fulfilmentTypeLabel,_that.isOfficePickup,_that.isRegionRequired,_that.deliveryPrice,_that.regions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _City implements City {
  const _City({required this.id, required this.name, @JsonKey(name: 'fulfilment_type') this.fulfilmentType, @JsonKey(name: 'fulfilment_type_label') this.fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup') this.isOfficePickup = false, @JsonKey(name: 'is_region_required') this.isRegionRequired = false, @JsonKey(name: 'delivery_price') this.deliveryPrice, final  List<Region> regions = const <Region>[]}): _regions = regions;
  factory _City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);

@override final  int id;
@override final  String name;
/// The value for logic, and the Arabic beside it. The label travels with the value so this
/// app keeps no translation table it would then have to keep in step with the business.
@override@JsonKey(name: 'fulfilment_type') final  String? fulfilmentType;
@override@JsonKey(name: 'fulfilment_type_label') final  String? fulfilmentTypeLabel;
/// **The boolean the order screen branches on**, decided on the server — so the app never
/// has to know which enum case means «they collect it».
@override@JsonKey(name: 'is_office_pickup') final  bool isOfficePickup;
/// Whether the picker may let the customer past without choosing a neighbourhood.
@override@JsonKey(name: 'is_region_required') final  bool isRegionRequired;
/// A decimal string, like every amount in this app. Null means no rate agreed.
@override@JsonKey(name: 'delivery_price') final  String? deliveryPrice;
 final  List<Region> _regions;
@override@JsonKey() List<Region> get regions {
  if (_regions is EqualUnmodifiableListView) return _regions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_regions);
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _City&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fulfilmentType, fulfilmentType) || other.fulfilmentType == fulfilmentType)&&(identical(other.fulfilmentTypeLabel, fulfilmentTypeLabel) || other.fulfilmentTypeLabel == fulfilmentTypeLabel)&&(identical(other.isOfficePickup, isOfficePickup) || other.isOfficePickup == isOfficePickup)&&(identical(other.isRegionRequired, isRegionRequired) || other.isRegionRequired == isRegionRequired)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&const DeepCollectionEquality().equals(other._regions, _regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fulfilmentType,fulfilmentTypeLabel,isOfficePickup,isRegionRequired,deliveryPrice,const DeepCollectionEquality().hash(_regions));

@override
String toString() {
  return 'City(id: $id, name: $name, fulfilmentType: $fulfilmentType, fulfilmentTypeLabel: $fulfilmentTypeLabel, isOfficePickup: $isOfficePickup, isRegionRequired: $isRegionRequired, deliveryPrice: $deliveryPrice, regions: $regions)';
}


}

/// @nodoc
abstract mixin class _$CityCopyWith<$Res> implements $CityCopyWith<$Res> {
  factory _$CityCopyWith(_City value, $Res Function(_City) _then) = __$CityCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'fulfilment_type') String? fulfilmentType,@JsonKey(name: 'fulfilment_type_label') String? fulfilmentTypeLabel,@JsonKey(name: 'is_office_pickup') bool isOfficePickup,@JsonKey(name: 'is_region_required') bool isRegionRequired,@JsonKey(name: 'delivery_price') String? deliveryPrice, List<Region> regions
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? fulfilmentType = freezed,Object? fulfilmentTypeLabel = freezed,Object? isOfficePickup = null,Object? isRegionRequired = null,Object? deliveryPrice = freezed,Object? regions = null,}) {
  return _then(_City(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fulfilmentType: freezed == fulfilmentType ? _self.fulfilmentType : fulfilmentType // ignore: cast_nullable_to_non_nullable
as String?,fulfilmentTypeLabel: freezed == fulfilmentTypeLabel ? _self.fulfilmentTypeLabel : fulfilmentTypeLabel // ignore: cast_nullable_to_non_nullable
as String?,isOfficePickup: null == isOfficePickup ? _self.isOfficePickup : isOfficePickup // ignore: cast_nullable_to_non_nullable
as bool,isRegionRequired: null == isRegionRequired ? _self.isRegionRequired : isRegionRequired // ignore: cast_nullable_to_non_nullable
as bool,deliveryPrice: freezed == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String?,regions: null == regions ? _self._regions : regions // ignore: cast_nullable_to_non_nullable
as List<Region>,
  ));
}


}

// dart format on
