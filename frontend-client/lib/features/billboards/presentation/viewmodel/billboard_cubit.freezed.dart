// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billboard_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BillboardState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillboardState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BillboardState()';
}


}

/// @nodoc
class $BillboardStateCopyWith<$Res>  {
$BillboardStateCopyWith(BillboardState _, $Res Function(BillboardState) __);
}


/// Adds pattern-matching-related methods to [BillboardState].
extension BillboardStatePatterns on BillboardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BillboardLoading value)?  loading,TResult Function( BillboardLoaded value)?  loaded,TResult Function( BillboardFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BillboardLoading() when loading != null:
return loading(_that);case BillboardLoaded() when loaded != null:
return loaded(_that);case BillboardFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BillboardLoading value)  loading,required TResult Function( BillboardLoaded value)  loaded,required TResult Function( BillboardFailure value)  failure,}){
final _that = this;
switch (_that) {
case BillboardLoading():
return loading(_that);case BillboardLoaded():
return loaded(_that);case BillboardFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BillboardLoading value)?  loading,TResult? Function( BillboardLoaded value)?  loaded,TResult? Function( BillboardFailure value)?  failure,}){
final _that = this;
switch (_that) {
case BillboardLoading() when loading != null:
return loading(_that);case BillboardLoaded() when loaded != null:
return loaded(_that);case BillboardFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<Billboard> billboards)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BillboardLoading() when loading != null:
return loading();case BillboardLoaded() when loaded != null:
return loaded(_that.billboards);case BillboardFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<Billboard> billboards)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case BillboardLoading():
return loading();case BillboardLoaded():
return loaded(_that.billboards);case BillboardFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<Billboard> billboards)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case BillboardLoading() when loading != null:
return loading();case BillboardLoaded() when loaded != null:
return loaded(_that.billboards);case BillboardFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class BillboardLoading implements BillboardState {
  const BillboardLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillboardLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BillboardState.loading()';
}


}




/// @nodoc


class BillboardLoaded implements BillboardState {
  const BillboardLoaded(final  List<Billboard> billboards): _billboards = billboards;
  

 final  List<Billboard> _billboards;
 List<Billboard> get billboards {
  if (_billboards is EqualUnmodifiableListView) return _billboards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_billboards);
}


/// Create a copy of BillboardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillboardLoadedCopyWith<BillboardLoaded> get copyWith => _$BillboardLoadedCopyWithImpl<BillboardLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillboardLoaded&&const DeepCollectionEquality().equals(other._billboards, _billboards));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_billboards));

@override
String toString() {
  return 'BillboardState.loaded(billboards: $billboards)';
}


}

/// @nodoc
abstract mixin class $BillboardLoadedCopyWith<$Res> implements $BillboardStateCopyWith<$Res> {
  factory $BillboardLoadedCopyWith(BillboardLoaded value, $Res Function(BillboardLoaded) _then) = _$BillboardLoadedCopyWithImpl;
@useResult
$Res call({
 List<Billboard> billboards
});




}
/// @nodoc
class _$BillboardLoadedCopyWithImpl<$Res>
    implements $BillboardLoadedCopyWith<$Res> {
  _$BillboardLoadedCopyWithImpl(this._self, this._then);

  final BillboardLoaded _self;
  final $Res Function(BillboardLoaded) _then;

/// Create a copy of BillboardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? billboards = null,}) {
  return _then(BillboardLoaded(
null == billboards ? _self._billboards : billboards // ignore: cast_nullable_to_non_nullable
as List<Billboard>,
  ));
}


}

/// @nodoc


class BillboardFailure implements BillboardState {
  const BillboardFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of BillboardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillboardFailureCopyWith<BillboardFailure> get copyWith => _$BillboardFailureCopyWithImpl<BillboardFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillboardFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'BillboardState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $BillboardFailureCopyWith<$Res> implements $BillboardStateCopyWith<$Res> {
  factory $BillboardFailureCopyWith(BillboardFailure value, $Res Function(BillboardFailure) _then) = _$BillboardFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$BillboardFailureCopyWithImpl<$Res>
    implements $BillboardFailureCopyWith<$Res> {
  _$BillboardFailureCopyWithImpl(this._self, this._then);

  final BillboardFailure _self;
  final $Res Function(BillboardFailure) _then;

/// Create a copy of BillboardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(BillboardFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of BillboardState
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
