// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'record_movement_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecordMovementState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordMovementState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecordMovementState()';
}


}

/// @nodoc
class $RecordMovementStateCopyWith<$Res>  {
$RecordMovementStateCopyWith(RecordMovementState _, $Res Function(RecordMovementState) __);
}


/// Adds pattern-matching-related methods to [RecordMovementState].
extension RecordMovementStatePatterns on RecordMovementState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RecordMovementInitial value)?  initial,TResult Function( RecordMovementSubmitting value)?  submitting,TResult Function( RecordMovementSuccess value)?  success,TResult Function( RecordMovementFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RecordMovementInitial() when initial != null:
return initial(_that);case RecordMovementSubmitting() when submitting != null:
return submitting(_that);case RecordMovementSuccess() when success != null:
return success(_that);case RecordMovementFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RecordMovementInitial value)  initial,required TResult Function( RecordMovementSubmitting value)  submitting,required TResult Function( RecordMovementSuccess value)  success,required TResult Function( RecordMovementFailure value)  failure,}){
final _that = this;
switch (_that) {
case RecordMovementInitial():
return initial(_that);case RecordMovementSubmitting():
return submitting(_that);case RecordMovementSuccess():
return success(_that);case RecordMovementFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RecordMovementInitial value)?  initial,TResult? Function( RecordMovementSubmitting value)?  submitting,TResult? Function( RecordMovementSuccess value)?  success,TResult? Function( RecordMovementFailure value)?  failure,}){
final _that = this;
switch (_that) {
case RecordMovementInitial() when initial != null:
return initial(_that);case RecordMovementSubmitting() when submitting != null:
return submitting(_that);case RecordMovementSuccess() when success != null:
return success(_that);case RecordMovementFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( StockMovement movement)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RecordMovementInitial() when initial != null:
return initial();case RecordMovementSubmitting() when submitting != null:
return submitting();case RecordMovementSuccess() when success != null:
return success(_that.movement);case RecordMovementFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( StockMovement movement)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case RecordMovementInitial():
return initial();case RecordMovementSubmitting():
return submitting();case RecordMovementSuccess():
return success(_that.movement);case RecordMovementFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( StockMovement movement)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case RecordMovementInitial() when initial != null:
return initial();case RecordMovementSubmitting() when submitting != null:
return submitting();case RecordMovementSuccess() when success != null:
return success(_that.movement);case RecordMovementFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class RecordMovementInitial implements RecordMovementState {
  const RecordMovementInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordMovementInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecordMovementState.initial()';
}


}




/// @nodoc


class RecordMovementSubmitting implements RecordMovementState {
  const RecordMovementSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordMovementSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecordMovementState.submitting()';
}


}




/// @nodoc


class RecordMovementSuccess implements RecordMovementState {
  const RecordMovementSuccess(this.movement);
  

 final  StockMovement movement;

/// Create a copy of RecordMovementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordMovementSuccessCopyWith<RecordMovementSuccess> get copyWith => _$RecordMovementSuccessCopyWithImpl<RecordMovementSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordMovementSuccess&&(identical(other.movement, movement) || other.movement == movement));
}


@override
int get hashCode => Object.hash(runtimeType,movement);

@override
String toString() {
  return 'RecordMovementState.success(movement: $movement)';
}


}

/// @nodoc
abstract mixin class $RecordMovementSuccessCopyWith<$Res> implements $RecordMovementStateCopyWith<$Res> {
  factory $RecordMovementSuccessCopyWith(RecordMovementSuccess value, $Res Function(RecordMovementSuccess) _then) = _$RecordMovementSuccessCopyWithImpl;
@useResult
$Res call({
 StockMovement movement
});


$StockMovementCopyWith<$Res> get movement;

}
/// @nodoc
class _$RecordMovementSuccessCopyWithImpl<$Res>
    implements $RecordMovementSuccessCopyWith<$Res> {
  _$RecordMovementSuccessCopyWithImpl(this._self, this._then);

  final RecordMovementSuccess _self;
  final $Res Function(RecordMovementSuccess) _then;

/// Create a copy of RecordMovementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? movement = null,}) {
  return _then(RecordMovementSuccess(
null == movement ? _self.movement : movement // ignore: cast_nullable_to_non_nullable
as StockMovement,
  ));
}

/// Create a copy of RecordMovementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockMovementCopyWith<$Res> get movement {
  
  return $StockMovementCopyWith<$Res>(_self.movement, (value) {
    return _then(_self.copyWith(movement: value));
  });
}
}

/// @nodoc


class RecordMovementFailure implements RecordMovementState {
  const RecordMovementFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of RecordMovementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordMovementFailureCopyWith<RecordMovementFailure> get copyWith => _$RecordMovementFailureCopyWithImpl<RecordMovementFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordMovementFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'RecordMovementState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $RecordMovementFailureCopyWith<$Res> implements $RecordMovementStateCopyWith<$Res> {
  factory $RecordMovementFailureCopyWith(RecordMovementFailure value, $Res Function(RecordMovementFailure) _then) = _$RecordMovementFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$RecordMovementFailureCopyWithImpl<$Res>
    implements $RecordMovementFailureCopyWith<$Res> {
  _$RecordMovementFailureCopyWithImpl(this._self, this._then);

  final RecordMovementFailure _self;
  final $Res Function(RecordMovementFailure) _then;

/// Create a copy of RecordMovementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(RecordMovementFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of RecordMovementState
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
