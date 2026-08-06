// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'take_order_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TakeOrderState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TakeOrderState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TakeOrderState()';
}


}

/// @nodoc
class $TakeOrderStateCopyWith<$Res>  {
$TakeOrderStateCopyWith(TakeOrderState _, $Res Function(TakeOrderState) __);
}


/// Adds pattern-matching-related methods to [TakeOrderState].
extension TakeOrderStatePatterns on TakeOrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TakeOrderInitial value)?  initial,TResult Function( TakeOrderSubmitting value)?  submitting,TResult Function( TakeOrderSuccess value)?  success,TResult Function( TakeOrderFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TakeOrderInitial() when initial != null:
return initial(_that);case TakeOrderSubmitting() when submitting != null:
return submitting(_that);case TakeOrderSuccess() when success != null:
return success(_that);case TakeOrderFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TakeOrderInitial value)  initial,required TResult Function( TakeOrderSubmitting value)  submitting,required TResult Function( TakeOrderSuccess value)  success,required TResult Function( TakeOrderFailure value)  failure,}){
final _that = this;
switch (_that) {
case TakeOrderInitial():
return initial(_that);case TakeOrderSubmitting():
return submitting(_that);case TakeOrderSuccess():
return success(_that);case TakeOrderFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TakeOrderInitial value)?  initial,TResult? Function( TakeOrderSubmitting value)?  submitting,TResult? Function( TakeOrderSuccess value)?  success,TResult? Function( TakeOrderFailure value)?  failure,}){
final _that = this;
switch (_that) {
case TakeOrderInitial() when initial != null:
return initial(_that);case TakeOrderSubmitting() when submitting != null:
return submitting(_that);case TakeOrderSuccess() when success != null:
return success(_that);case TakeOrderFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( Order order)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TakeOrderInitial() when initial != null:
return initial();case TakeOrderSubmitting() when submitting != null:
return submitting();case TakeOrderSuccess() when success != null:
return success(_that.order);case TakeOrderFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( Order order)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case TakeOrderInitial():
return initial();case TakeOrderSubmitting():
return submitting();case TakeOrderSuccess():
return success(_that.order);case TakeOrderFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( Order order)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case TakeOrderInitial() when initial != null:
return initial();case TakeOrderSubmitting() when submitting != null:
return submitting();case TakeOrderSuccess() when success != null:
return success(_that.order);case TakeOrderFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TakeOrderInitial implements TakeOrderState {
  const TakeOrderInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TakeOrderInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TakeOrderState.initial()';
}


}




/// @nodoc


class TakeOrderSubmitting implements TakeOrderState {
  const TakeOrderSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TakeOrderSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TakeOrderState.submitting()';
}


}




/// @nodoc


class TakeOrderSuccess implements TakeOrderState {
  const TakeOrderSuccess(this.order);
  

 final  Order order;

/// Create a copy of TakeOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TakeOrderSuccessCopyWith<TakeOrderSuccess> get copyWith => _$TakeOrderSuccessCopyWithImpl<TakeOrderSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TakeOrderSuccess&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,order);

@override
String toString() {
  return 'TakeOrderState.success(order: $order)';
}


}

/// @nodoc
abstract mixin class $TakeOrderSuccessCopyWith<$Res> implements $TakeOrderStateCopyWith<$Res> {
  factory $TakeOrderSuccessCopyWith(TakeOrderSuccess value, $Res Function(TakeOrderSuccess) _then) = _$TakeOrderSuccessCopyWithImpl;
@useResult
$Res call({
 Order order
});


$OrderCopyWith<$Res> get order;

}
/// @nodoc
class _$TakeOrderSuccessCopyWithImpl<$Res>
    implements $TakeOrderSuccessCopyWith<$Res> {
  _$TakeOrderSuccessCopyWithImpl(this._self, this._then);

  final TakeOrderSuccess _self;
  final $Res Function(TakeOrderSuccess) _then;

/// Create a copy of TakeOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? order = null,}) {
  return _then(TakeOrderSuccess(
null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as Order,
  ));
}

/// Create a copy of TakeOrderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderCopyWith<$Res> get order {
  
  return $OrderCopyWith<$Res>(_self.order, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

/// @nodoc


class TakeOrderFailure implements TakeOrderState {
  const TakeOrderFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of TakeOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TakeOrderFailureCopyWith<TakeOrderFailure> get copyWith => _$TakeOrderFailureCopyWithImpl<TakeOrderFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TakeOrderFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TakeOrderState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TakeOrderFailureCopyWith<$Res> implements $TakeOrderStateCopyWith<$Res> {
  factory $TakeOrderFailureCopyWith(TakeOrderFailure value, $Res Function(TakeOrderFailure) _then) = _$TakeOrderFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TakeOrderFailureCopyWithImpl<$Res>
    implements $TakeOrderFailureCopyWith<$Res> {
  _$TakeOrderFailureCopyWithImpl(this._self, this._then);

  final TakeOrderFailure _self;
  final $Res Function(TakeOrderFailure) _then;

/// Create a copy of TakeOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TakeOrderFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of TakeOrderState
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
