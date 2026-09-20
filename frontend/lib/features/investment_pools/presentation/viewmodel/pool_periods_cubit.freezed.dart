// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pool_periods_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PoolPeriodsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolPeriodsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PoolPeriodsState()';
}


}

/// @nodoc
class $PoolPeriodsStateCopyWith<$Res>  {
$PoolPeriodsStateCopyWith(PoolPeriodsState _, $Res Function(PoolPeriodsState) __);
}


/// Adds pattern-matching-related methods to [PoolPeriodsState].
extension PoolPeriodsStatePatterns on PoolPeriodsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PoolPeriodsLoading value)?  loading,TResult Function( PoolPeriodsLoaded value)?  loaded,TResult Function( PoolPeriodsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PoolPeriodsLoading() when loading != null:
return loading(_that);case PoolPeriodsLoaded() when loaded != null:
return loaded(_that);case PoolPeriodsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PoolPeriodsLoading value)  loading,required TResult Function( PoolPeriodsLoaded value)  loaded,required TResult Function( PoolPeriodsFailure value)  failure,}){
final _that = this;
switch (_that) {
case PoolPeriodsLoading():
return loading(_that);case PoolPeriodsLoaded():
return loaded(_that);case PoolPeriodsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PoolPeriodsLoading value)?  loading,TResult? Function( PoolPeriodsLoaded value)?  loaded,TResult? Function( PoolPeriodsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PoolPeriodsLoading() when loading != null:
return loading(_that);case PoolPeriodsLoaded() when loaded != null:
return loaded(_that);case PoolPeriodsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<InvestmentPeriod> periods)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PoolPeriodsLoading() when loading != null:
return loading();case PoolPeriodsLoaded() when loaded != null:
return loaded(_that.periods);case PoolPeriodsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<InvestmentPeriod> periods)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PoolPeriodsLoading():
return loading();case PoolPeriodsLoaded():
return loaded(_that.periods);case PoolPeriodsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<InvestmentPeriod> periods)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PoolPeriodsLoading() when loading != null:
return loading();case PoolPeriodsLoaded() when loaded != null:
return loaded(_that.periods);case PoolPeriodsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PoolPeriodsLoading implements PoolPeriodsState {
  const PoolPeriodsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolPeriodsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PoolPeriodsState.loading()';
}


}




/// @nodoc


class PoolPeriodsLoaded implements PoolPeriodsState {
  const PoolPeriodsLoaded({required final  List<InvestmentPeriod> periods}): _periods = periods;
  

 final  List<InvestmentPeriod> _periods;
 List<InvestmentPeriod> get periods {
  if (_periods is EqualUnmodifiableListView) return _periods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_periods);
}


/// Create a copy of PoolPeriodsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolPeriodsLoadedCopyWith<PoolPeriodsLoaded> get copyWith => _$PoolPeriodsLoadedCopyWithImpl<PoolPeriodsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolPeriodsLoaded&&const DeepCollectionEquality().equals(other._periods, _periods));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_periods));

@override
String toString() {
  return 'PoolPeriodsState.loaded(periods: $periods)';
}


}

/// @nodoc
abstract mixin class $PoolPeriodsLoadedCopyWith<$Res> implements $PoolPeriodsStateCopyWith<$Res> {
  factory $PoolPeriodsLoadedCopyWith(PoolPeriodsLoaded value, $Res Function(PoolPeriodsLoaded) _then) = _$PoolPeriodsLoadedCopyWithImpl;
@useResult
$Res call({
 List<InvestmentPeriod> periods
});




}
/// @nodoc
class _$PoolPeriodsLoadedCopyWithImpl<$Res>
    implements $PoolPeriodsLoadedCopyWith<$Res> {
  _$PoolPeriodsLoadedCopyWithImpl(this._self, this._then);

  final PoolPeriodsLoaded _self;
  final $Res Function(PoolPeriodsLoaded) _then;

/// Create a copy of PoolPeriodsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? periods = null,}) {
  return _then(PoolPeriodsLoaded(
periods: null == periods ? _self._periods : periods // ignore: cast_nullable_to_non_nullable
as List<InvestmentPeriod>,
  ));
}


}

/// @nodoc


class PoolPeriodsFailure implements PoolPeriodsState {
  const PoolPeriodsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of PoolPeriodsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolPeriodsFailureCopyWith<PoolPeriodsFailure> get copyWith => _$PoolPeriodsFailureCopyWithImpl<PoolPeriodsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolPeriodsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PoolPeriodsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PoolPeriodsFailureCopyWith<$Res> implements $PoolPeriodsStateCopyWith<$Res> {
  factory $PoolPeriodsFailureCopyWith(PoolPeriodsFailure value, $Res Function(PoolPeriodsFailure) _then) = _$PoolPeriodsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PoolPeriodsFailureCopyWithImpl<$Res>
    implements $PoolPeriodsFailureCopyWith<$Res> {
  _$PoolPeriodsFailureCopyWithImpl(this._self, this._then);

  final PoolPeriodsFailure _self;
  final $Res Function(PoolPeriodsFailure) _then;

/// Create a copy of PoolPeriodsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PoolPeriodsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PoolPeriodsState
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
