// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pool_settlements_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PoolSettlementsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolSettlementsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PoolSettlementsState()';
}


}

/// @nodoc
class $PoolSettlementsStateCopyWith<$Res>  {
$PoolSettlementsStateCopyWith(PoolSettlementsState _, $Res Function(PoolSettlementsState) __);
}


/// Adds pattern-matching-related methods to [PoolSettlementsState].
extension PoolSettlementsStatePatterns on PoolSettlementsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PoolSettlementsLoading value)?  loading,TResult Function( PoolSettlementsLoaded value)?  loaded,TResult Function( PoolSettlementsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PoolSettlementsLoading() when loading != null:
return loading(_that);case PoolSettlementsLoaded() when loaded != null:
return loaded(_that);case PoolSettlementsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PoolSettlementsLoading value)  loading,required TResult Function( PoolSettlementsLoaded value)  loaded,required TResult Function( PoolSettlementsFailure value)  failure,}){
final _that = this;
switch (_that) {
case PoolSettlementsLoading():
return loading(_that);case PoolSettlementsLoaded():
return loaded(_that);case PoolSettlementsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PoolSettlementsLoading value)?  loading,TResult? Function( PoolSettlementsLoaded value)?  loaded,TResult? Function( PoolSettlementsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PoolSettlementsLoading() when loading != null:
return loading(_that);case PoolSettlementsLoaded() when loaded != null:
return loaded(_that);case PoolSettlementsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( SettlementSnapshot snapshot,  List<InvestmentSettlement> settlements)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PoolSettlementsLoading() when loading != null:
return loading();case PoolSettlementsLoaded() when loaded != null:
return loaded(_that.snapshot,_that.settlements);case PoolSettlementsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( SettlementSnapshot snapshot,  List<InvestmentSettlement> settlements)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PoolSettlementsLoading():
return loading();case PoolSettlementsLoaded():
return loaded(_that.snapshot,_that.settlements);case PoolSettlementsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( SettlementSnapshot snapshot,  List<InvestmentSettlement> settlements)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PoolSettlementsLoading() when loading != null:
return loading();case PoolSettlementsLoaded() when loaded != null:
return loaded(_that.snapshot,_that.settlements);case PoolSettlementsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PoolSettlementsLoading implements PoolSettlementsState {
  const PoolSettlementsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolSettlementsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PoolSettlementsState.loading()';
}


}




/// @nodoc


class PoolSettlementsLoaded implements PoolSettlementsState {
  const PoolSettlementsLoaded({required this.snapshot, final  List<InvestmentSettlement> settlements = const <InvestmentSettlement>[]}): _settlements = settlements;
  

/// Where the money is **now**, derived on this read.
 final  SettlementSnapshot snapshot;
/// What has been signed before, newest first.
 final  List<InvestmentSettlement> _settlements;
/// What has been signed before, newest first.
@JsonKey() List<InvestmentSettlement> get settlements {
  if (_settlements is EqualUnmodifiableListView) return _settlements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_settlements);
}


/// Create a copy of PoolSettlementsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolSettlementsLoadedCopyWith<PoolSettlementsLoaded> get copyWith => _$PoolSettlementsLoadedCopyWithImpl<PoolSettlementsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolSettlementsLoaded&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&const DeepCollectionEquality().equals(other._settlements, _settlements));
}


@override
int get hashCode => Object.hash(runtimeType,snapshot,const DeepCollectionEquality().hash(_settlements));

@override
String toString() {
  return 'PoolSettlementsState.loaded(snapshot: $snapshot, settlements: $settlements)';
}


}

/// @nodoc
abstract mixin class $PoolSettlementsLoadedCopyWith<$Res> implements $PoolSettlementsStateCopyWith<$Res> {
  factory $PoolSettlementsLoadedCopyWith(PoolSettlementsLoaded value, $Res Function(PoolSettlementsLoaded) _then) = _$PoolSettlementsLoadedCopyWithImpl;
@useResult
$Res call({
 SettlementSnapshot snapshot, List<InvestmentSettlement> settlements
});


$SettlementSnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class _$PoolSettlementsLoadedCopyWithImpl<$Res>
    implements $PoolSettlementsLoadedCopyWith<$Res> {
  _$PoolSettlementsLoadedCopyWithImpl(this._self, this._then);

  final PoolSettlementsLoaded _self;
  final $Res Function(PoolSettlementsLoaded) _then;

/// Create a copy of PoolSettlementsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? snapshot = null,Object? settlements = null,}) {
  return _then(PoolSettlementsLoaded(
snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as SettlementSnapshot,settlements: null == settlements ? _self._settlements : settlements // ignore: cast_nullable_to_non_nullable
as List<InvestmentSettlement>,
  ));
}

/// Create a copy of PoolSettlementsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettlementSnapshotCopyWith<$Res> get snapshot {
  
  return $SettlementSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}

/// @nodoc


class PoolSettlementsFailure implements PoolSettlementsState {
  const PoolSettlementsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of PoolSettlementsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolSettlementsFailureCopyWith<PoolSettlementsFailure> get copyWith => _$PoolSettlementsFailureCopyWithImpl<PoolSettlementsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolSettlementsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PoolSettlementsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PoolSettlementsFailureCopyWith<$Res> implements $PoolSettlementsStateCopyWith<$Res> {
  factory $PoolSettlementsFailureCopyWith(PoolSettlementsFailure value, $Res Function(PoolSettlementsFailure) _then) = _$PoolSettlementsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PoolSettlementsFailureCopyWithImpl<$Res>
    implements $PoolSettlementsFailureCopyWith<$Res> {
  _$PoolSettlementsFailureCopyWithImpl(this._self, this._then);

  final PoolSettlementsFailure _self;
  final $Res Function(PoolSettlementsFailure) _then;

/// Create a copy of PoolSettlementsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PoolSettlementsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PoolSettlementsState
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
