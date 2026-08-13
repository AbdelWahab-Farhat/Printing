// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_manufacturing_cost_rate_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveManufacturingCostRateState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveManufacturingCostRateState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveManufacturingCostRateState()';
}


}

/// @nodoc
class $SaveManufacturingCostRateStateCopyWith<$Res>  {
$SaveManufacturingCostRateStateCopyWith(SaveManufacturingCostRateState _, $Res Function(SaveManufacturingCostRateState) __);
}


/// Adds pattern-matching-related methods to [SaveManufacturingCostRateState].
extension SaveManufacturingCostRateStatePatterns on SaveManufacturingCostRateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveManufacturingCostRateInitial value)?  initial,TResult Function( SaveManufacturingCostRateSubmitting value)?  submitting,TResult Function( SaveManufacturingCostRateSuccess value)?  success,TResult Function( SaveManufacturingCostRateFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveManufacturingCostRateInitial() when initial != null:
return initial(_that);case SaveManufacturingCostRateSubmitting() when submitting != null:
return submitting(_that);case SaveManufacturingCostRateSuccess() when success != null:
return success(_that);case SaveManufacturingCostRateFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveManufacturingCostRateInitial value)  initial,required TResult Function( SaveManufacturingCostRateSubmitting value)  submitting,required TResult Function( SaveManufacturingCostRateSuccess value)  success,required TResult Function( SaveManufacturingCostRateFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveManufacturingCostRateInitial():
return initial(_that);case SaveManufacturingCostRateSubmitting():
return submitting(_that);case SaveManufacturingCostRateSuccess():
return success(_that);case SaveManufacturingCostRateFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveManufacturingCostRateInitial value)?  initial,TResult? Function( SaveManufacturingCostRateSubmitting value)?  submitting,TResult? Function( SaveManufacturingCostRateSuccess value)?  success,TResult? Function( SaveManufacturingCostRateFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveManufacturingCostRateInitial() when initial != null:
return initial(_that);case SaveManufacturingCostRateSubmitting() when submitting != null:
return submitting(_that);case SaveManufacturingCostRateSuccess() when success != null:
return success(_that);case SaveManufacturingCostRateFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( ManufacturingCostRate rate)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveManufacturingCostRateInitial() when initial != null:
return initial();case SaveManufacturingCostRateSubmitting() when submitting != null:
return submitting();case SaveManufacturingCostRateSuccess() when success != null:
return success(_that.rate);case SaveManufacturingCostRateFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( ManufacturingCostRate rate)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SaveManufacturingCostRateInitial():
return initial();case SaveManufacturingCostRateSubmitting():
return submitting();case SaveManufacturingCostRateSuccess():
return success(_that.rate);case SaveManufacturingCostRateFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( ManufacturingCostRate rate)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SaveManufacturingCostRateInitial() when initial != null:
return initial();case SaveManufacturingCostRateSubmitting() when submitting != null:
return submitting();case SaveManufacturingCostRateSuccess() when success != null:
return success(_that.rate);case SaveManufacturingCostRateFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveManufacturingCostRateInitial implements SaveManufacturingCostRateState {
  const SaveManufacturingCostRateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveManufacturingCostRateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveManufacturingCostRateState.initial()';
}


}




/// @nodoc


class SaveManufacturingCostRateSubmitting implements SaveManufacturingCostRateState {
  const SaveManufacturingCostRateSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveManufacturingCostRateSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveManufacturingCostRateState.submitting()';
}


}




/// @nodoc


class SaveManufacturingCostRateSuccess implements SaveManufacturingCostRateState {
  const SaveManufacturingCostRateSuccess(this.rate);
  

 final  ManufacturingCostRate rate;

/// Create a copy of SaveManufacturingCostRateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveManufacturingCostRateSuccessCopyWith<SaveManufacturingCostRateSuccess> get copyWith => _$SaveManufacturingCostRateSuccessCopyWithImpl<SaveManufacturingCostRateSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveManufacturingCostRateSuccess&&(identical(other.rate, rate) || other.rate == rate));
}


@override
int get hashCode => Object.hash(runtimeType,rate);

@override
String toString() {
  return 'SaveManufacturingCostRateState.success(rate: $rate)';
}


}

/// @nodoc
abstract mixin class $SaveManufacturingCostRateSuccessCopyWith<$Res> implements $SaveManufacturingCostRateStateCopyWith<$Res> {
  factory $SaveManufacturingCostRateSuccessCopyWith(SaveManufacturingCostRateSuccess value, $Res Function(SaveManufacturingCostRateSuccess) _then) = _$SaveManufacturingCostRateSuccessCopyWithImpl;
@useResult
$Res call({
 ManufacturingCostRate rate
});


$ManufacturingCostRateCopyWith<$Res> get rate;

}
/// @nodoc
class _$SaveManufacturingCostRateSuccessCopyWithImpl<$Res>
    implements $SaveManufacturingCostRateSuccessCopyWith<$Res> {
  _$SaveManufacturingCostRateSuccessCopyWithImpl(this._self, this._then);

  final SaveManufacturingCostRateSuccess _self;
  final $Res Function(SaveManufacturingCostRateSuccess) _then;

/// Create a copy of SaveManufacturingCostRateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rate = null,}) {
  return _then(SaveManufacturingCostRateSuccess(
null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as ManufacturingCostRate,
  ));
}

/// Create a copy of SaveManufacturingCostRateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ManufacturingCostRateCopyWith<$Res> get rate {
  
  return $ManufacturingCostRateCopyWith<$Res>(_self.rate, (value) {
    return _then(_self.copyWith(rate: value));
  });
}
}

/// @nodoc


class SaveManufacturingCostRateFailure implements SaveManufacturingCostRateState {
  const SaveManufacturingCostRateFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveManufacturingCostRateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveManufacturingCostRateFailureCopyWith<SaveManufacturingCostRateFailure> get copyWith => _$SaveManufacturingCostRateFailureCopyWithImpl<SaveManufacturingCostRateFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveManufacturingCostRateFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveManufacturingCostRateState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveManufacturingCostRateFailureCopyWith<$Res> implements $SaveManufacturingCostRateStateCopyWith<$Res> {
  factory $SaveManufacturingCostRateFailureCopyWith(SaveManufacturingCostRateFailure value, $Res Function(SaveManufacturingCostRateFailure) _then) = _$SaveManufacturingCostRateFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveManufacturingCostRateFailureCopyWithImpl<$Res>
    implements $SaveManufacturingCostRateFailureCopyWith<$Res> {
  _$SaveManufacturingCostRateFailureCopyWithImpl(this._self, this._then);

  final SaveManufacturingCostRateFailure _self;
  final $Res Function(SaveManufacturingCostRateFailure) _then;

/// Create a copy of SaveManufacturingCostRateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveManufacturingCostRateFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveManufacturingCostRateState
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
