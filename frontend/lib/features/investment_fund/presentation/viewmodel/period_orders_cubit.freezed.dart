// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_orders_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PeriodOrdersState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrdersState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PeriodOrdersState()';
}


}

/// @nodoc
class $PeriodOrdersStateCopyWith<$Res>  {
$PeriodOrdersStateCopyWith(PeriodOrdersState _, $Res Function(PeriodOrdersState) __);
}


/// Adds pattern-matching-related methods to [PeriodOrdersState].
extension PeriodOrdersStatePatterns on PeriodOrdersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PeriodOrdersLoading value)?  loading,TResult Function( PeriodOrdersLoaded value)?  loaded,TResult Function( PeriodOrdersFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PeriodOrdersLoading() when loading != null:
return loading(_that);case PeriodOrdersLoaded() when loaded != null:
return loaded(_that);case PeriodOrdersFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PeriodOrdersLoading value)  loading,required TResult Function( PeriodOrdersLoaded value)  loaded,required TResult Function( PeriodOrdersFailure value)  failure,}){
final _that = this;
switch (_that) {
case PeriodOrdersLoading():
return loading(_that);case PeriodOrdersLoaded():
return loaded(_that);case PeriodOrdersFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PeriodOrdersLoading value)?  loading,TResult? Function( PeriodOrdersLoaded value)?  loaded,TResult? Function( PeriodOrdersFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PeriodOrdersLoading() when loading != null:
return loading(_that);case PeriodOrdersLoaded() when loaded != null:
return loaded(_that);case PeriodOrdersFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( PeriodOrders held)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PeriodOrdersLoading() when loading != null:
return loading();case PeriodOrdersLoaded() when loaded != null:
return loaded(_that.held);case PeriodOrdersFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( PeriodOrders held)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PeriodOrdersLoading():
return loading();case PeriodOrdersLoaded():
return loaded(_that.held);case PeriodOrdersFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( PeriodOrders held)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PeriodOrdersLoading() when loading != null:
return loading();case PeriodOrdersLoaded() when loaded != null:
return loaded(_that.held);case PeriodOrdersFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PeriodOrdersLoading implements PeriodOrdersState {
  const PeriodOrdersLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrdersLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PeriodOrdersState.loading()';
}


}




/// @nodoc


class PeriodOrdersLoaded implements PeriodOrdersState {
  const PeriodOrdersLoaded(this.held);
  

 final  PeriodOrders held;

/// Create a copy of PeriodOrdersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodOrdersLoadedCopyWith<PeriodOrdersLoaded> get copyWith => _$PeriodOrdersLoadedCopyWithImpl<PeriodOrdersLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrdersLoaded&&(identical(other.held, held) || other.held == held));
}


@override
int get hashCode => Object.hash(runtimeType,held);

@override
String toString() {
  return 'PeriodOrdersState.loaded(held: $held)';
}


}

/// @nodoc
abstract mixin class $PeriodOrdersLoadedCopyWith<$Res> implements $PeriodOrdersStateCopyWith<$Res> {
  factory $PeriodOrdersLoadedCopyWith(PeriodOrdersLoaded value, $Res Function(PeriodOrdersLoaded) _then) = _$PeriodOrdersLoadedCopyWithImpl;
@useResult
$Res call({
 PeriodOrders held
});


$PeriodOrdersCopyWith<$Res> get held;

}
/// @nodoc
class _$PeriodOrdersLoadedCopyWithImpl<$Res>
    implements $PeriodOrdersLoadedCopyWith<$Res> {
  _$PeriodOrdersLoadedCopyWithImpl(this._self, this._then);

  final PeriodOrdersLoaded _self;
  final $Res Function(PeriodOrdersLoaded) _then;

/// Create a copy of PeriodOrdersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? held = null,}) {
  return _then(PeriodOrdersLoaded(
null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as PeriodOrders,
  ));
}

/// Create a copy of PeriodOrdersState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodOrdersCopyWith<$Res> get held {
  
  return $PeriodOrdersCopyWith<$Res>(_self.held, (value) {
    return _then(_self.copyWith(held: value));
  });
}
}

/// @nodoc


class PeriodOrdersFailure implements PeriodOrdersState {
  const PeriodOrdersFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of PeriodOrdersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodOrdersFailureCopyWith<PeriodOrdersFailure> get copyWith => _$PeriodOrdersFailureCopyWithImpl<PeriodOrdersFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrdersFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PeriodOrdersState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PeriodOrdersFailureCopyWith<$Res> implements $PeriodOrdersStateCopyWith<$Res> {
  factory $PeriodOrdersFailureCopyWith(PeriodOrdersFailure value, $Res Function(PeriodOrdersFailure) _then) = _$PeriodOrdersFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PeriodOrdersFailureCopyWithImpl<$Res>
    implements $PeriodOrdersFailureCopyWith<$Res> {
  _$PeriodOrdersFailureCopyWithImpl(this._self, this._then);

  final PeriodOrdersFailure _self;
  final $Res Function(PeriodOrdersFailure) _then;

/// Create a copy of PeriodOrdersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PeriodOrdersFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PeriodOrdersState
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
