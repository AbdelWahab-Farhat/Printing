// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_warehouse_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveWarehouseState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveWarehouseState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveWarehouseState()';
}


}

/// @nodoc
class $SaveWarehouseStateCopyWith<$Res>  {
$SaveWarehouseStateCopyWith(SaveWarehouseState _, $Res Function(SaveWarehouseState) __);
}


/// Adds pattern-matching-related methods to [SaveWarehouseState].
extension SaveWarehouseStatePatterns on SaveWarehouseState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveWarehouseInitial value)?  initial,TResult Function( SaveWarehouseSubmitting value)?  submitting,TResult Function( SaveWarehouseSuccess value)?  success,TResult Function( SaveWarehouseFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveWarehouseInitial() when initial != null:
return initial(_that);case SaveWarehouseSubmitting() when submitting != null:
return submitting(_that);case SaveWarehouseSuccess() when success != null:
return success(_that);case SaveWarehouseFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveWarehouseInitial value)  initial,required TResult Function( SaveWarehouseSubmitting value)  submitting,required TResult Function( SaveWarehouseSuccess value)  success,required TResult Function( SaveWarehouseFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveWarehouseInitial():
return initial(_that);case SaveWarehouseSubmitting():
return submitting(_that);case SaveWarehouseSuccess():
return success(_that);case SaveWarehouseFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveWarehouseInitial value)?  initial,TResult? Function( SaveWarehouseSubmitting value)?  submitting,TResult? Function( SaveWarehouseSuccess value)?  success,TResult? Function( SaveWarehouseFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveWarehouseInitial() when initial != null:
return initial(_that);case SaveWarehouseSubmitting() when submitting != null:
return submitting(_that);case SaveWarehouseSuccess() when success != null:
return success(_that);case SaveWarehouseFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( Warehouse warehouse)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveWarehouseInitial() when initial != null:
return initial();case SaveWarehouseSubmitting() when submitting != null:
return submitting();case SaveWarehouseSuccess() when success != null:
return success(_that.warehouse);case SaveWarehouseFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( Warehouse warehouse)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SaveWarehouseInitial():
return initial();case SaveWarehouseSubmitting():
return submitting();case SaveWarehouseSuccess():
return success(_that.warehouse);case SaveWarehouseFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( Warehouse warehouse)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SaveWarehouseInitial() when initial != null:
return initial();case SaveWarehouseSubmitting() when submitting != null:
return submitting();case SaveWarehouseSuccess() when success != null:
return success(_that.warehouse);case SaveWarehouseFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveWarehouseInitial implements SaveWarehouseState {
  const SaveWarehouseInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveWarehouseInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveWarehouseState.initial()';
}


}




/// @nodoc


class SaveWarehouseSubmitting implements SaveWarehouseState {
  const SaveWarehouseSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveWarehouseSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveWarehouseState.submitting()';
}


}




/// @nodoc


class SaveWarehouseSuccess implements SaveWarehouseState {
  const SaveWarehouseSuccess(this.warehouse);
  

 final  Warehouse warehouse;

/// Create a copy of SaveWarehouseState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveWarehouseSuccessCopyWith<SaveWarehouseSuccess> get copyWith => _$SaveWarehouseSuccessCopyWithImpl<SaveWarehouseSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveWarehouseSuccess&&(identical(other.warehouse, warehouse) || other.warehouse == warehouse));
}


@override
int get hashCode => Object.hash(runtimeType,warehouse);

@override
String toString() {
  return 'SaveWarehouseState.success(warehouse: $warehouse)';
}


}

/// @nodoc
abstract mixin class $SaveWarehouseSuccessCopyWith<$Res> implements $SaveWarehouseStateCopyWith<$Res> {
  factory $SaveWarehouseSuccessCopyWith(SaveWarehouseSuccess value, $Res Function(SaveWarehouseSuccess) _then) = _$SaveWarehouseSuccessCopyWithImpl;
@useResult
$Res call({
 Warehouse warehouse
});


$WarehouseCopyWith<$Res> get warehouse;

}
/// @nodoc
class _$SaveWarehouseSuccessCopyWithImpl<$Res>
    implements $SaveWarehouseSuccessCopyWith<$Res> {
  _$SaveWarehouseSuccessCopyWithImpl(this._self, this._then);

  final SaveWarehouseSuccess _self;
  final $Res Function(SaveWarehouseSuccess) _then;

/// Create a copy of SaveWarehouseState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? warehouse = null,}) {
  return _then(SaveWarehouseSuccess(
null == warehouse ? _self.warehouse : warehouse // ignore: cast_nullable_to_non_nullable
as Warehouse,
  ));
}

/// Create a copy of SaveWarehouseState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarehouseCopyWith<$Res> get warehouse {
  
  return $WarehouseCopyWith<$Res>(_self.warehouse, (value) {
    return _then(_self.copyWith(warehouse: value));
  });
}
}

/// @nodoc


class SaveWarehouseFailure implements SaveWarehouseState {
  const SaveWarehouseFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveWarehouseState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveWarehouseFailureCopyWith<SaveWarehouseFailure> get copyWith => _$SaveWarehouseFailureCopyWithImpl<SaveWarehouseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveWarehouseFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveWarehouseState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveWarehouseFailureCopyWith<$Res> implements $SaveWarehouseStateCopyWith<$Res> {
  factory $SaveWarehouseFailureCopyWith(SaveWarehouseFailure value, $Res Function(SaveWarehouseFailure) _then) = _$SaveWarehouseFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveWarehouseFailureCopyWithImpl<$Res>
    implements $SaveWarehouseFailureCopyWith<$Res> {
  _$SaveWarehouseFailureCopyWithImpl(this._self, this._then);

  final SaveWarehouseFailure _self;
  final $Res Function(SaveWarehouseFailure) _then;

/// Create a copy of SaveWarehouseState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveWarehouseFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveWarehouseState
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
