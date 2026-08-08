// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_purchase_order_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavePurchaseOrderState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavePurchaseOrderState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SavePurchaseOrderState()';
}


}

/// @nodoc
class $SavePurchaseOrderStateCopyWith<$Res>  {
$SavePurchaseOrderStateCopyWith(SavePurchaseOrderState _, $Res Function(SavePurchaseOrderState) __);
}


/// Adds pattern-matching-related methods to [SavePurchaseOrderState].
extension SavePurchaseOrderStatePatterns on SavePurchaseOrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SavePurchaseOrderInitial value)?  initial,TResult Function( SavePurchaseOrderSubmitting value)?  submitting,TResult Function( SavePurchaseOrderSuccess value)?  success,TResult Function( SavePurchaseOrderFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SavePurchaseOrderInitial() when initial != null:
return initial(_that);case SavePurchaseOrderSubmitting() when submitting != null:
return submitting(_that);case SavePurchaseOrderSuccess() when success != null:
return success(_that);case SavePurchaseOrderFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SavePurchaseOrderInitial value)  initial,required TResult Function( SavePurchaseOrderSubmitting value)  submitting,required TResult Function( SavePurchaseOrderSuccess value)  success,required TResult Function( SavePurchaseOrderFailure value)  failure,}){
final _that = this;
switch (_that) {
case SavePurchaseOrderInitial():
return initial(_that);case SavePurchaseOrderSubmitting():
return submitting(_that);case SavePurchaseOrderSuccess():
return success(_that);case SavePurchaseOrderFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SavePurchaseOrderInitial value)?  initial,TResult? Function( SavePurchaseOrderSubmitting value)?  submitting,TResult? Function( SavePurchaseOrderSuccess value)?  success,TResult? Function( SavePurchaseOrderFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SavePurchaseOrderInitial() when initial != null:
return initial(_that);case SavePurchaseOrderSubmitting() when submitting != null:
return submitting(_that);case SavePurchaseOrderSuccess() when success != null:
return success(_that);case SavePurchaseOrderFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( PurchaseOrder order)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SavePurchaseOrderInitial() when initial != null:
return initial();case SavePurchaseOrderSubmitting() when submitting != null:
return submitting();case SavePurchaseOrderSuccess() when success != null:
return success(_that.order);case SavePurchaseOrderFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( PurchaseOrder order)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SavePurchaseOrderInitial():
return initial();case SavePurchaseOrderSubmitting():
return submitting();case SavePurchaseOrderSuccess():
return success(_that.order);case SavePurchaseOrderFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( PurchaseOrder order)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SavePurchaseOrderInitial() when initial != null:
return initial();case SavePurchaseOrderSubmitting() when submitting != null:
return submitting();case SavePurchaseOrderSuccess() when success != null:
return success(_that.order);case SavePurchaseOrderFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SavePurchaseOrderInitial implements SavePurchaseOrderState {
  const SavePurchaseOrderInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavePurchaseOrderInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SavePurchaseOrderState.initial()';
}


}




/// @nodoc


class SavePurchaseOrderSubmitting implements SavePurchaseOrderState {
  const SavePurchaseOrderSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavePurchaseOrderSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SavePurchaseOrderState.submitting()';
}


}




/// @nodoc


class SavePurchaseOrderSuccess implements SavePurchaseOrderState {
  const SavePurchaseOrderSuccess(this.order);
  

 final  PurchaseOrder order;

/// Create a copy of SavePurchaseOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavePurchaseOrderSuccessCopyWith<SavePurchaseOrderSuccess> get copyWith => _$SavePurchaseOrderSuccessCopyWithImpl<SavePurchaseOrderSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavePurchaseOrderSuccess&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,order);

@override
String toString() {
  return 'SavePurchaseOrderState.success(order: $order)';
}


}

/// @nodoc
abstract mixin class $SavePurchaseOrderSuccessCopyWith<$Res> implements $SavePurchaseOrderStateCopyWith<$Res> {
  factory $SavePurchaseOrderSuccessCopyWith(SavePurchaseOrderSuccess value, $Res Function(SavePurchaseOrderSuccess) _then) = _$SavePurchaseOrderSuccessCopyWithImpl;
@useResult
$Res call({
 PurchaseOrder order
});


$PurchaseOrderCopyWith<$Res> get order;

}
/// @nodoc
class _$SavePurchaseOrderSuccessCopyWithImpl<$Res>
    implements $SavePurchaseOrderSuccessCopyWith<$Res> {
  _$SavePurchaseOrderSuccessCopyWithImpl(this._self, this._then);

  final SavePurchaseOrderSuccess _self;
  final $Res Function(SavePurchaseOrderSuccess) _then;

/// Create a copy of SavePurchaseOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? order = null,}) {
  return _then(SavePurchaseOrderSuccess(
null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as PurchaseOrder,
  ));
}

/// Create a copy of SavePurchaseOrderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseOrderCopyWith<$Res> get order {
  
  return $PurchaseOrderCopyWith<$Res>(_self.order, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

/// @nodoc


class SavePurchaseOrderFailure implements SavePurchaseOrderState {
  const SavePurchaseOrderFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SavePurchaseOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavePurchaseOrderFailureCopyWith<SavePurchaseOrderFailure> get copyWith => _$SavePurchaseOrderFailureCopyWithImpl<SavePurchaseOrderFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavePurchaseOrderFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SavePurchaseOrderState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SavePurchaseOrderFailureCopyWith<$Res> implements $SavePurchaseOrderStateCopyWith<$Res> {
  factory $SavePurchaseOrderFailureCopyWith(SavePurchaseOrderFailure value, $Res Function(SavePurchaseOrderFailure) _then) = _$SavePurchaseOrderFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SavePurchaseOrderFailureCopyWithImpl<$Res>
    implements $SavePurchaseOrderFailureCopyWith<$Res> {
  _$SavePurchaseOrderFailureCopyWithImpl(this._self, this._then);

  final SavePurchaseOrderFailure _self;
  final $Res Function(SavePurchaseOrderFailure) _then;

/// Create a copy of SavePurchaseOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SavePurchaseOrderFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SavePurchaseOrderState
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
