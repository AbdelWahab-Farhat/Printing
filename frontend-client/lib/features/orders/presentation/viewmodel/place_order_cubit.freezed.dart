// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_order_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaceOrderState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceOrderState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaceOrderState()';
}


}

/// @nodoc
class $PlaceOrderStateCopyWith<$Res>  {
$PlaceOrderStateCopyWith(PlaceOrderState _, $Res Function(PlaceOrderState) __);
}


/// Adds pattern-matching-related methods to [PlaceOrderState].
extension PlaceOrderStatePatterns on PlaceOrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaceOrderLoading value)?  loading,TResult Function( PlaceOrderReady value)?  ready,TResult Function( PlaceOrderFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaceOrderLoading() when loading != null:
return loading(_that);case PlaceOrderReady() when ready != null:
return ready(_that);case PlaceOrderFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaceOrderLoading value)  loading,required TResult Function( PlaceOrderReady value)  ready,required TResult Function( PlaceOrderFailure value)  failure,}){
final _that = this;
switch (_that) {
case PlaceOrderLoading():
return loading(_that);case PlaceOrderReady():
return ready(_that);case PlaceOrderFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaceOrderLoading value)?  loading,TResult? Function( PlaceOrderReady value)?  ready,TResult? Function( PlaceOrderFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PlaceOrderLoading() when loading != null:
return loading(_that);case PlaceOrderReady() when ready != null:
return ready(_that);case PlaceOrderFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<City> cities,  List<CustomerDesign> designs,  List<OrderDraftLine> lines,  int? cityId,  int? regionId,  List<int> designIds,  bool isSubmitting,  CustomerOrderDetail? placed,  Failure? lastFailure)?  ready,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaceOrderLoading() when loading != null:
return loading();case PlaceOrderReady() when ready != null:
return ready(_that.cities,_that.designs,_that.lines,_that.cityId,_that.regionId,_that.designIds,_that.isSubmitting,_that.placed,_that.lastFailure);case PlaceOrderFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<City> cities,  List<CustomerDesign> designs,  List<OrderDraftLine> lines,  int? cityId,  int? regionId,  List<int> designIds,  bool isSubmitting,  CustomerOrderDetail? placed,  Failure? lastFailure)  ready,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PlaceOrderLoading():
return loading();case PlaceOrderReady():
return ready(_that.cities,_that.designs,_that.lines,_that.cityId,_that.regionId,_that.designIds,_that.isSubmitting,_that.placed,_that.lastFailure);case PlaceOrderFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<City> cities,  List<CustomerDesign> designs,  List<OrderDraftLine> lines,  int? cityId,  int? regionId,  List<int> designIds,  bool isSubmitting,  CustomerOrderDetail? placed,  Failure? lastFailure)?  ready,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PlaceOrderLoading() when loading != null:
return loading();case PlaceOrderReady() when ready != null:
return ready(_that.cities,_that.designs,_that.lines,_that.cityId,_that.regionId,_that.designIds,_that.isSubmitting,_that.placed,_that.lastFailure);case PlaceOrderFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PlaceOrderLoading implements PlaceOrderState {
  const PlaceOrderLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceOrderLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaceOrderState.loading()';
}


}




/// @nodoc


class PlaceOrderReady implements PlaceOrderState {
  const PlaceOrderReady({required final  List<City> cities, final  List<CustomerDesign> designs = const <CustomerDesign>[], final  List<OrderDraftLine> lines = const <OrderDraftLine>[], this.cityId, this.regionId, final  List<int> designIds = const <int>[], this.isSubmitting = false, this.placed, this.lastFailure}): _cities = cities,_designs = designs,_lines = lines,_designIds = designIds;
  

/// Every destination, with its neighbourhoods. Fetched once — the picker does not page.
 final  List<City> _cities;
/// Every destination, with its neighbourhoods. Fetched once — the picker does not page.
 List<City> get cities {
  if (_cities is EqualUnmodifiableListView) return _cities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cities);
}

/// The customer's library, for attaching artwork. **Empty is fine**: attaching a design is
/// optional, and an empty library is also what a failed fetch looks like here, because
/// neither is worth refusing an order over.
 final  List<CustomerDesign> _designs;
/// The customer's library, for attaching artwork. **Empty is fine**: attaching a design is
/// optional, and an empty library is also what a failed fetch looks like here, because
/// neither is worth refusing an order over.
@JsonKey() List<CustomerDesign> get designs {
  if (_designs is EqualUnmodifiableListView) return _designs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_designs);
}

 final  List<OrderDraftLine> _lines;
@JsonKey() List<OrderDraftLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

 final  int? cityId;
 final  int? regionId;
 final  List<int> _designIds;
@JsonKey() List<int> get designIds {
  if (_designIds is EqualUnmodifiableListView) return _designIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_designIds);
}

@JsonKey() final  bool isSubmitting;
/// The order the shop created, once it has. **«بانتظار المراجعة»** — nothing is confirmed
/// and nothing is priced against stock until a person has read it.
 final  CustomerOrderDetail? placed;
 final  Failure? lastFailure;

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceOrderReadyCopyWith<PlaceOrderReady> get copyWith => _$PlaceOrderReadyCopyWithImpl<PlaceOrderReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceOrderReady&&const DeepCollectionEquality().equals(other._cities, _cities)&&const DeepCollectionEquality().equals(other._designs, _designs)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&const DeepCollectionEquality().equals(other._designIds, _designIds)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.placed, placed) || other.placed == placed)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cities),const DeepCollectionEquality().hash(_designs),const DeepCollectionEquality().hash(_lines),cityId,regionId,const DeepCollectionEquality().hash(_designIds),isSubmitting,placed,lastFailure);

@override
String toString() {
  return 'PlaceOrderState.ready(cities: $cities, designs: $designs, lines: $lines, cityId: $cityId, regionId: $regionId, designIds: $designIds, isSubmitting: $isSubmitting, placed: $placed, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class $PlaceOrderReadyCopyWith<$Res> implements $PlaceOrderStateCopyWith<$Res> {
  factory $PlaceOrderReadyCopyWith(PlaceOrderReady value, $Res Function(PlaceOrderReady) _then) = _$PlaceOrderReadyCopyWithImpl;
@useResult
$Res call({
 List<City> cities, List<CustomerDesign> designs, List<OrderDraftLine> lines, int? cityId, int? regionId, List<int> designIds, bool isSubmitting, CustomerOrderDetail? placed, Failure? lastFailure
});


$CustomerOrderDetailCopyWith<$Res>? get placed;$FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class _$PlaceOrderReadyCopyWithImpl<$Res>
    implements $PlaceOrderReadyCopyWith<$Res> {
  _$PlaceOrderReadyCopyWithImpl(this._self, this._then);

  final PlaceOrderReady _self;
  final $Res Function(PlaceOrderReady) _then;

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cities = null,Object? designs = null,Object? lines = null,Object? cityId = freezed,Object? regionId = freezed,Object? designIds = null,Object? isSubmitting = null,Object? placed = freezed,Object? lastFailure = freezed,}) {
  return _then(PlaceOrderReady(
cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<City>,designs: null == designs ? _self._designs : designs // ignore: cast_nullable_to_non_nullable
as List<CustomerDesign>,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<OrderDraftLine>,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,designIds: null == designIds ? _self._designIds : designIds // ignore: cast_nullable_to_non_nullable
as List<int>,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,placed: freezed == placed ? _self.placed : placed // ignore: cast_nullable_to_non_nullable
as CustomerOrderDetail?,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerOrderDetailCopyWith<$Res>? get placed {
    if (_self.placed == null) {
    return null;
  }

  return $CustomerOrderDetailCopyWith<$Res>(_self.placed!, (value) {
    return _then(_self.copyWith(placed: value));
  });
}/// Create a copy of PlaceOrderState
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


class PlaceOrderFailure implements PlaceOrderState {
  const PlaceOrderFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceOrderFailureCopyWith<PlaceOrderFailure> get copyWith => _$PlaceOrderFailureCopyWithImpl<PlaceOrderFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceOrderFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PlaceOrderState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PlaceOrderFailureCopyWith<$Res> implements $PlaceOrderStateCopyWith<$Res> {
  factory $PlaceOrderFailureCopyWith(PlaceOrderFailure value, $Res Function(PlaceOrderFailure) _then) = _$PlaceOrderFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PlaceOrderFailureCopyWithImpl<$Res>
    implements $PlaceOrderFailureCopyWith<$Res> {
  _$PlaceOrderFailureCopyWithImpl(this._self, this._then);

  final PlaceOrderFailure _self;
  final $Res Function(PlaceOrderFailure) _then;

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PlaceOrderFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PlaceOrderState
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
