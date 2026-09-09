// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sales_statistics_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SalesStatisticsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesStatisticsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SalesStatisticsState()';
}


}

/// @nodoc
class $SalesStatisticsStateCopyWith<$Res>  {
$SalesStatisticsStateCopyWith(SalesStatisticsState _, $Res Function(SalesStatisticsState) __);
}


/// Adds pattern-matching-related methods to [SalesStatisticsState].
extension SalesStatisticsStatePatterns on SalesStatisticsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SalesStatisticsInitial value)?  initial,TResult Function( SalesStatisticsLoading value)?  loading,TResult Function( SalesStatisticsLoaded value)?  loaded,TResult Function( SalesStatisticsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SalesStatisticsInitial() when initial != null:
return initial(_that);case SalesStatisticsLoading() when loading != null:
return loading(_that);case SalesStatisticsLoaded() when loaded != null:
return loaded(_that);case SalesStatisticsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SalesStatisticsInitial value)  initial,required TResult Function( SalesStatisticsLoading value)  loading,required TResult Function( SalesStatisticsLoaded value)  loaded,required TResult Function( SalesStatisticsFailure value)  failure,}){
final _that = this;
switch (_that) {
case SalesStatisticsInitial():
return initial(_that);case SalesStatisticsLoading():
return loading(_that);case SalesStatisticsLoaded():
return loaded(_that);case SalesStatisticsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SalesStatisticsInitial value)?  initial,TResult? Function( SalesStatisticsLoading value)?  loading,TResult? Function( SalesStatisticsLoaded value)?  loaded,TResult? Function( SalesStatisticsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SalesStatisticsInitial() when initial != null:
return initial(_that);case SalesStatisticsLoading() when loading != null:
return loading(_that);case SalesStatisticsLoaded() when loaded != null:
return loaded(_that);case SalesStatisticsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( SalesStatistics statistics)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SalesStatisticsInitial() when initial != null:
return initial();case SalesStatisticsLoading() when loading != null:
return loading();case SalesStatisticsLoaded() when loaded != null:
return loaded(_that.statistics);case SalesStatisticsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( SalesStatistics statistics)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SalesStatisticsInitial():
return initial();case SalesStatisticsLoading():
return loading();case SalesStatisticsLoaded():
return loaded(_that.statistics);case SalesStatisticsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( SalesStatistics statistics)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SalesStatisticsInitial() when initial != null:
return initial();case SalesStatisticsLoading() when loading != null:
return loading();case SalesStatisticsLoaded() when loaded != null:
return loaded(_that.statistics);case SalesStatisticsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SalesStatisticsInitial implements SalesStatisticsState {
  const SalesStatisticsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesStatisticsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SalesStatisticsState.initial()';
}


}




/// @nodoc


class SalesStatisticsLoading implements SalesStatisticsState {
  const SalesStatisticsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesStatisticsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SalesStatisticsState.loading()';
}


}




/// @nodoc


class SalesStatisticsLoaded implements SalesStatisticsState {
  const SalesStatisticsLoaded(this.statistics);
  

 final  SalesStatistics statistics;

/// Create a copy of SalesStatisticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesStatisticsLoadedCopyWith<SalesStatisticsLoaded> get copyWith => _$SalesStatisticsLoadedCopyWithImpl<SalesStatisticsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesStatisticsLoaded&&(identical(other.statistics, statistics) || other.statistics == statistics));
}


@override
int get hashCode => Object.hash(runtimeType,statistics);

@override
String toString() {
  return 'SalesStatisticsState.loaded(statistics: $statistics)';
}


}

/// @nodoc
abstract mixin class $SalesStatisticsLoadedCopyWith<$Res> implements $SalesStatisticsStateCopyWith<$Res> {
  factory $SalesStatisticsLoadedCopyWith(SalesStatisticsLoaded value, $Res Function(SalesStatisticsLoaded) _then) = _$SalesStatisticsLoadedCopyWithImpl;
@useResult
$Res call({
 SalesStatistics statistics
});


$SalesStatisticsCopyWith<$Res> get statistics;

}
/// @nodoc
class _$SalesStatisticsLoadedCopyWithImpl<$Res>
    implements $SalesStatisticsLoadedCopyWith<$Res> {
  _$SalesStatisticsLoadedCopyWithImpl(this._self, this._then);

  final SalesStatisticsLoaded _self;
  final $Res Function(SalesStatisticsLoaded) _then;

/// Create a copy of SalesStatisticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statistics = null,}) {
  return _then(SalesStatisticsLoaded(
null == statistics ? _self.statistics : statistics // ignore: cast_nullable_to_non_nullable
as SalesStatistics,
  ));
}

/// Create a copy of SalesStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SalesStatisticsCopyWith<$Res> get statistics {
  
  return $SalesStatisticsCopyWith<$Res>(_self.statistics, (value) {
    return _then(_self.copyWith(statistics: value));
  });
}
}

/// @nodoc


class SalesStatisticsFailure implements SalesStatisticsState {
  const SalesStatisticsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SalesStatisticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesStatisticsFailureCopyWith<SalesStatisticsFailure> get copyWith => _$SalesStatisticsFailureCopyWithImpl<SalesStatisticsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesStatisticsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SalesStatisticsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SalesStatisticsFailureCopyWith<$Res> implements $SalesStatisticsStateCopyWith<$Res> {
  factory $SalesStatisticsFailureCopyWith(SalesStatisticsFailure value, $Res Function(SalesStatisticsFailure) _then) = _$SalesStatisticsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SalesStatisticsFailureCopyWithImpl<$Res>
    implements $SalesStatisticsFailureCopyWith<$Res> {
  _$SalesStatisticsFailureCopyWithImpl(this._self, this._then);

  final SalesStatisticsFailure _self;
  final $Res Function(SalesStatisticsFailure) _then;

/// Create a copy of SalesStatisticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SalesStatisticsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SalesStatisticsState
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
