// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_form_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShopFormState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopFormState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShopFormState()';
}


}

/// @nodoc
class $ShopFormStateCopyWith<$Res>  {
$ShopFormStateCopyWith(ShopFormState _, $Res Function(ShopFormState) __);
}


/// Adds pattern-matching-related methods to [ShopFormState].
extension ShopFormStatePatterns on ShopFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ShopFormLoading value)?  loading,TResult Function( ShopFormReady value)?  ready,TResult Function( ShopFormFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ShopFormLoading() when loading != null:
return loading(_that);case ShopFormReady() when ready != null:
return ready(_that);case ShopFormFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ShopFormLoading value)  loading,required TResult Function( ShopFormReady value)  ready,required TResult Function( ShopFormFailure value)  failure,}){
final _that = this;
switch (_that) {
case ShopFormLoading():
return loading(_that);case ShopFormReady():
return ready(_that);case ShopFormFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ShopFormLoading value)?  loading,TResult? Function( ShopFormReady value)?  ready,TResult? Function( ShopFormFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ShopFormLoading() when loading != null:
return loading(_that);case ShopFormReady() when ready != null:
return ready(_that);case ShopFormFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<City> cities,  List<BusinessField> businessFields,  int? businessFieldId,  int? cityId,  int? regionId,  bool isSaving,  Failure? lastFailure)?  ready,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ShopFormLoading() when loading != null:
return loading();case ShopFormReady() when ready != null:
return ready(_that.cities,_that.businessFields,_that.businessFieldId,_that.cityId,_that.regionId,_that.isSaving,_that.lastFailure);case ShopFormFailure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<City> cities,  List<BusinessField> businessFields,  int? businessFieldId,  int? cityId,  int? regionId,  bool isSaving,  Failure? lastFailure)  ready,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case ShopFormLoading():
return loading();case ShopFormReady():
return ready(_that.cities,_that.businessFields,_that.businessFieldId,_that.cityId,_that.regionId,_that.isSaving,_that.lastFailure);case ShopFormFailure():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<City> cities,  List<BusinessField> businessFields,  int? businessFieldId,  int? cityId,  int? regionId,  bool isSaving,  Failure? lastFailure)?  ready,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case ShopFormLoading() when loading != null:
return loading();case ShopFormReady() when ready != null:
return ready(_that.cities,_that.businessFields,_that.businessFieldId,_that.cityId,_that.regionId,_that.isSaving,_that.lastFailure);case ShopFormFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ShopFormLoading implements ShopFormState {
  const ShopFormLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopFormLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShopFormState.loading()';
}


}




/// @nodoc


class ShopFormReady implements ShopFormState {
  const ShopFormReady({required final  List<City> cities, final  List<BusinessField> businessFields = const <BusinessField>[], this.businessFieldId, this.cityId, this.regionId, this.isSaving = false, this.lastFailure}): _cities = cities,_businessFields = businessFields;
  

/// كل المدن بمناطقها، مرةً واحدة — المنتقي لا يُقلَّب صفحات.
 final  List<City> _cities;
/// كل المدن بمناطقها، مرةً واحدة — المنتقي لا يُقلَّب صفحات.
 List<City> get cities {
  if (_cities is EqualUnmodifiableListView) return _cities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cities);
}

/// المجالات المعروضة، ومعها مجال المتجر إن أُوقف بعد تسجيله. فارغةٌ حين لم تصل، والحقل اختياري.
 final  List<BusinessField> _businessFields;
/// المجالات المعروضة، ومعها مجال المتجر إن أُوقف بعد تسجيله. فارغةٌ حين لم تصل، والحقل اختياري.
@JsonKey() List<BusinessField> get businessFields {
  if (_businessFields is EqualUnmodifiableListView) return _businessFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_businessFields);
}

 final  int? businessFieldId;
 final  int? cityId;
 final  int? regionId;
@JsonKey() final  bool isSaving;
/// آخر حفظٍ رُفض. أخطاء الحقول تُعلَّق تحت حقولها، والباقي رسالة.
 final  Failure? lastFailure;

/// Create a copy of ShopFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopFormReadyCopyWith<ShopFormReady> get copyWith => _$ShopFormReadyCopyWithImpl<ShopFormReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopFormReady&&const DeepCollectionEquality().equals(other._cities, _cities)&&const DeepCollectionEquality().equals(other._businessFields, _businessFields)&&(identical(other.businessFieldId, businessFieldId) || other.businessFieldId == businessFieldId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cities),const DeepCollectionEquality().hash(_businessFields),businessFieldId,cityId,regionId,isSaving,lastFailure);

@override
String toString() {
  return 'ShopFormState.ready(cities: $cities, businessFields: $businessFields, businessFieldId: $businessFieldId, cityId: $cityId, regionId: $regionId, isSaving: $isSaving, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class $ShopFormReadyCopyWith<$Res> implements $ShopFormStateCopyWith<$Res> {
  factory $ShopFormReadyCopyWith(ShopFormReady value, $Res Function(ShopFormReady) _then) = _$ShopFormReadyCopyWithImpl;
@useResult
$Res call({
 List<City> cities, List<BusinessField> businessFields, int? businessFieldId, int? cityId, int? regionId, bool isSaving, Failure? lastFailure
});


$FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class _$ShopFormReadyCopyWithImpl<$Res>
    implements $ShopFormReadyCopyWith<$Res> {
  _$ShopFormReadyCopyWithImpl(this._self, this._then);

  final ShopFormReady _self;
  final $Res Function(ShopFormReady) _then;

/// Create a copy of ShopFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cities = null,Object? businessFields = null,Object? businessFieldId = freezed,Object? cityId = freezed,Object? regionId = freezed,Object? isSaving = null,Object? lastFailure = freezed,}) {
  return _then(ShopFormReady(
cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<City>,businessFields: null == businessFields ? _self._businessFields : businessFields // ignore: cast_nullable_to_non_nullable
as List<BusinessField>,businessFieldId: freezed == businessFieldId ? _self.businessFieldId : businessFieldId // ignore: cast_nullable_to_non_nullable
as int?,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of ShopFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get lastFailure {
    if (_self.lastFailure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.lastFailure!, (value) {
    return _then(_self.copyWith(lastFailure: value));
  });
}
}

/// @nodoc


class ShopFormFailure implements ShopFormState {
  const ShopFormFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of ShopFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopFormFailureCopyWith<ShopFormFailure> get copyWith => _$ShopFormFailureCopyWithImpl<ShopFormFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopFormFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ShopFormState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ShopFormFailureCopyWith<$Res> implements $ShopFormStateCopyWith<$Res> {
  factory $ShopFormFailureCopyWith(ShopFormFailure value, $Res Function(ShopFormFailure) _then) = _$ShopFormFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ShopFormFailureCopyWithImpl<$Res>
    implements $ShopFormFailureCopyWith<$Res> {
  _$ShopFormFailureCopyWithImpl(this._self, this._then);

  final ShopFormFailure _self;
  final $Res Function(ShopFormFailure) _then;

/// Create a copy of ShopFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ShopFormFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ShopFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
