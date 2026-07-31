// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'city_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CityModel {

 int get id; String get name;@JsonKey(name: 'is_region_required') bool get isRegionRequired;@JsonKey(name: 'delivery_price') String? get deliveryPrice;@JsonKey(name: 'darb_branch') String? get darbBranch; double? get latitude; double? get longitude;@JsonKey(name: 'regions_count') int? get regionsCount; List<RegionModel>? get regions;
/// Create a copy of CityModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CityModelCopyWith<CityModel> get copyWith => _$CityModelCopyWithImpl<CityModel>(this as CityModel, _$identity);

  /// Serializes this CityModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CityModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isRegionRequired, isRegionRequired) || other.isRegionRequired == isRegionRequired)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.darbBranch, darbBranch) || other.darbBranch == darbBranch)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.regionsCount, regionsCount) || other.regionsCount == regionsCount)&&const DeepCollectionEquality().equals(other.regions, regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isRegionRequired,deliveryPrice,darbBranch,latitude,longitude,regionsCount,const DeepCollectionEquality().hash(regions));

@override
String toString() {
  return 'CityModel(id: $id, name: $name, isRegionRequired: $isRegionRequired, deliveryPrice: $deliveryPrice, darbBranch: $darbBranch, latitude: $latitude, longitude: $longitude, regionsCount: $regionsCount, regions: $regions)';
}


}

/// @nodoc
abstract mixin class $CityModelCopyWith<$Res>  {
  factory $CityModelCopyWith(CityModel value, $Res Function(CityModel) _then) = _$CityModelCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'is_region_required') bool isRegionRequired,@JsonKey(name: 'delivery_price') String? deliveryPrice,@JsonKey(name: 'darb_branch') String? darbBranch, double? latitude, double? longitude,@JsonKey(name: 'regions_count') int? regionsCount, List<RegionModel>? regions
});




}
/// @nodoc
class _$CityModelCopyWithImpl<$Res>
    implements $CityModelCopyWith<$Res> {
  _$CityModelCopyWithImpl(this._self, this._then);

  final CityModel _self;
  final $Res Function(CityModel) _then;

/// Create a copy of CityModel
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
as List<RegionModel>?,
  ));
}

}


/// Adds pattern-matching-related methods to [CityModel].
extension CityModelPatterns on CityModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CityModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CityModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CityModel value)  $default,){
final _that = this;
switch (_that) {
case _CityModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CityModel value)?  $default,){
final _that = this;
switch (_that) {
case _CityModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'is_region_required')  bool isRegionRequired, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'darb_branch')  String? darbBranch,  double? latitude,  double? longitude, @JsonKey(name: 'regions_count')  int? regionsCount,  List<RegionModel>? regions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CityModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'is_region_required')  bool isRegionRequired, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'darb_branch')  String? darbBranch,  double? latitude,  double? longitude, @JsonKey(name: 'regions_count')  int? regionsCount,  List<RegionModel>? regions)  $default,) {final _that = this;
switch (_that) {
case _CityModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'is_region_required')  bool isRegionRequired, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'darb_branch')  String? darbBranch,  double? latitude,  double? longitude, @JsonKey(name: 'regions_count')  int? regionsCount,  List<RegionModel>? regions)?  $default,) {final _that = this;
switch (_that) {
case _CityModel() when $default != null:
return $default(_that.id,_that.name,_that.isRegionRequired,_that.deliveryPrice,_that.darbBranch,_that.latitude,_that.longitude,_that.regionsCount,_that.regions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CityModel extends CityModel {
  const _CityModel({required this.id, required this.name, @JsonKey(name: 'is_region_required') required this.isRegionRequired, @JsonKey(name: 'delivery_price') this.deliveryPrice, @JsonKey(name: 'darb_branch') this.darbBranch, this.latitude, this.longitude, @JsonKey(name: 'regions_count') this.regionsCount, final  List<RegionModel>? regions}): _regions = regions,super._();
  factory _CityModel.fromJson(Map<String, dynamic> json) => _$CityModelFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'is_region_required') final  bool isRegionRequired;
@override@JsonKey(name: 'delivery_price') final  String? deliveryPrice;
@override@JsonKey(name: 'darb_branch') final  String? darbBranch;
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey(name: 'regions_count') final  int? regionsCount;
 final  List<RegionModel>? _regions;
@override List<RegionModel>? get regions {
  final value = _regions;
  if (value == null) return null;
  if (_regions is EqualUnmodifiableListView) return _regions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of CityModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CityModelCopyWith<_CityModel> get copyWith => __$CityModelCopyWithImpl<_CityModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CityModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CityModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isRegionRequired, isRegionRequired) || other.isRegionRequired == isRegionRequired)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.darbBranch, darbBranch) || other.darbBranch == darbBranch)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.regionsCount, regionsCount) || other.regionsCount == regionsCount)&&const DeepCollectionEquality().equals(other._regions, _regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isRegionRequired,deliveryPrice,darbBranch,latitude,longitude,regionsCount,const DeepCollectionEquality().hash(_regions));

@override
String toString() {
  return 'CityModel(id: $id, name: $name, isRegionRequired: $isRegionRequired, deliveryPrice: $deliveryPrice, darbBranch: $darbBranch, latitude: $latitude, longitude: $longitude, regionsCount: $regionsCount, regions: $regions)';
}


}

/// @nodoc
abstract mixin class _$CityModelCopyWith<$Res> implements $CityModelCopyWith<$Res> {
  factory _$CityModelCopyWith(_CityModel value, $Res Function(_CityModel) _then) = __$CityModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'is_region_required') bool isRegionRequired,@JsonKey(name: 'delivery_price') String? deliveryPrice,@JsonKey(name: 'darb_branch') String? darbBranch, double? latitude, double? longitude,@JsonKey(name: 'regions_count') int? regionsCount, List<RegionModel>? regions
});




}
/// @nodoc
class __$CityModelCopyWithImpl<$Res>
    implements _$CityModelCopyWith<$Res> {
  __$CityModelCopyWithImpl(this._self, this._then);

  final _CityModel _self;
  final $Res Function(_CityModel) _then;

/// Create a copy of CityModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isRegionRequired = null,Object? deliveryPrice = freezed,Object? darbBranch = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? regionsCount = freezed,Object? regions = freezed,}) {
  return _then(_CityModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isRegionRequired: null == isRegionRequired ? _self.isRegionRequired : isRegionRequired // ignore: cast_nullable_to_non_nullable
as bool,deliveryPrice: freezed == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String?,darbBranch: freezed == darbBranch ? _self.darbBranch : darbBranch // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,regionsCount: freezed == regionsCount ? _self.regionsCount : regionsCount // ignore: cast_nullable_to_non_nullable
as int?,regions: freezed == regions ? _self._regions : regions // ignore: cast_nullable_to_non_nullable
as List<RegionModel>?,
  ));
}


}


/// @nodoc
mixin _$RegionModel {

 int get id;@JsonKey(name: 'city_id') int get cityId; String get name; String? get code;@JsonKey(name: 'darb_branch') String? get darbBranch; double? get latitude; double? get longitude;
/// Create a copy of RegionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegionModelCopyWith<RegionModel> get copyWith => _$RegionModelCopyWithImpl<RegionModel>(this as RegionModel, _$identity);

  /// Serializes this RegionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.darbBranch, darbBranch) || other.darbBranch == darbBranch)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cityId,name,code,darbBranch,latitude,longitude);

@override
String toString() {
  return 'RegionModel(id: $id, cityId: $cityId, name: $name, code: $code, darbBranch: $darbBranch, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $RegionModelCopyWith<$Res>  {
  factory $RegionModelCopyWith(RegionModel value, $Res Function(RegionModel) _then) = _$RegionModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'city_id') int cityId, String name, String? code,@JsonKey(name: 'darb_branch') String? darbBranch, double? latitude, double? longitude
});




}
/// @nodoc
class _$RegionModelCopyWithImpl<$Res>
    implements $RegionModelCopyWith<$Res> {
  _$RegionModelCopyWithImpl(this._self, this._then);

  final RegionModel _self;
  final $Res Function(RegionModel) _then;

/// Create a copy of RegionModel
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


/// Adds pattern-matching-related methods to [RegionModel].
extension RegionModelPatterns on RegionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegionModel value)  $default,){
final _that = this;
switch (_that) {
case _RegionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegionModel value)?  $default,){
final _that = this;
switch (_that) {
case _RegionModel() when $default != null:
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
case _RegionModel() when $default != null:
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
case _RegionModel():
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
case _RegionModel() when $default != null:
return $default(_that.id,_that.cityId,_that.name,_that.code,_that.darbBranch,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegionModel extends RegionModel {
  const _RegionModel({required this.id, @JsonKey(name: 'city_id') required this.cityId, required this.name, this.code, @JsonKey(name: 'darb_branch') this.darbBranch, this.latitude, this.longitude}): super._();
  factory _RegionModel.fromJson(Map<String, dynamic> json) => _$RegionModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'city_id') final  int cityId;
@override final  String name;
@override final  String? code;
@override@JsonKey(name: 'darb_branch') final  String? darbBranch;
@override final  double? latitude;
@override final  double? longitude;

/// Create a copy of RegionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegionModelCopyWith<_RegionModel> get copyWith => __$RegionModelCopyWithImpl<_RegionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.darbBranch, darbBranch) || other.darbBranch == darbBranch)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cityId,name,code,darbBranch,latitude,longitude);

@override
String toString() {
  return 'RegionModel(id: $id, cityId: $cityId, name: $name, code: $code, darbBranch: $darbBranch, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$RegionModelCopyWith<$Res> implements $RegionModelCopyWith<$Res> {
  factory _$RegionModelCopyWith(_RegionModel value, $Res Function(_RegionModel) _then) = __$RegionModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'city_id') int cityId, String name, String? code,@JsonKey(name: 'darb_branch') String? darbBranch, double? latitude, double? longitude
});




}
/// @nodoc
class __$RegionModelCopyWithImpl<$Res>
    implements _$RegionModelCopyWith<$Res> {
  __$RegionModelCopyWithImpl(this._self, this._then);

  final _RegionModel _self;
  final $Res Function(_RegionModel) _then;

/// Create a copy of RegionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cityId = null,Object? name = null,Object? code = freezed,Object? darbBranch = freezed,Object? latitude = freezed,Object? longitude = freezed,}) {
  return _then(_RegionModel(
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
